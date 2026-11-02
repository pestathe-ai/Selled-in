// Salvataggio locale: articoli e impostazioni in SharedPreferences,
// foto copiate nella cartella privata dell'app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class Archivio extends ChangeNotifier {
  static const _kArticoli = 'articoli_v1';
  static const _kImpostazioni = 'impostazioni_v1';

  List<Articolo> articoli = [];
  Impostazioni impostazioni = const Impostazioni();
  bool pronto = false;

  Future<void> carica() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kArticoli);
    if (raw != null) {
      try {
        articoli = (jsonDecode(raw) as List)
            .map((e) => Articolo.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        articoli = [];
      }
    }
    final rawImp = sp.getString(_kImpostazioni);
    if (rawImp != null) {
      try {
        impostazioni = Impostazioni.fromJson(Map<String, dynamic>.from(jsonDecode(rawImp) as Map));
      } catch (_) {}
    }
    pronto = true;
    notifyListeners();
  }

  Future<void> _salva() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kArticoli, jsonEncode(articoli.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  Articolo? trova(String id) {
    for (final a in articoli) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> salvaArticolo(Articolo a) async {
    final i = articoli.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      articoli[i] = a;
    } else {
      articoli.insert(0, a);
    }
    await _salva();
  }

  Future<void> elimina(Articolo a) async {
    articoli.removeWhere((x) => x.id == a.id);
    for (final f in a.foto) {
      try {
        await File(f).delete();
      } catch (_) {}
    }
    await _salva();
  }

  Future<void> salvaImpostazioni(Impostazioni imp) async {
    impostazioni = imp;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kImpostazioni, jsonEncode(imp.toJson()));
    notifyListeners();
  }

  /// Copia una foto (dalla galleria o fotocamera) nella cartella dell'app.
  Future<String> importaFoto(String sorgente) async {
    final dir = await getApplicationDocumentsDirectory();
    final cartella = Directory('${dir.path}/foto');
    if (!await cartella.exists()) await cartella.create(recursive: true);
    final ext = sorgente.contains('.') ? sorgente.substring(sorgente.lastIndexOf('.')) : '.jpg';
    final dest = '${cartella.path}/${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(sorgente).copy(dest);
    return dest;
  }

  /// Esporta tutto in CSV (per backup o foglio di calcolo).
  String esportaCsv() {
    String q(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
    final righe = <String>[
      'tipo,marca,taglia,colore,condizione,prezzo,costo,pubblicato_su,venduto_il,prezzo_vendita,venduto_su',
      for (final a in articoli)
        [
          q(a.tipo),
          q(a.marca),
          q(a.taglia),
          q(a.colore),
          q(a.condizione),
          a.prezzo,
          a.costo ?? '',
          q(a.pubblicazioni.keys.map((p) => p.nome).join(' / ')),
          a.vendutoIl?.toIso8601String().substring(0, 10) ?? '',
          a.prezzoVendita ?? '',
          q(a.vendutoSu?.nome),
        ].join(','),
    ];
    return righe.join('\n');
  }
}
