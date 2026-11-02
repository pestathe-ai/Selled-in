// Calcoli: articoli fermi, ribassi, statistiche. Puro Dart.
import 'models.dart';

int giorniTra(DateTime da, DateTime a) =>
    DateTime(a.year, a.month, a.day).difference(DateTime(da.year, da.month, da.day)).inDays;

/// Un articolo è fermo se è pubblicato, non venduto e online (o non ribassato)
/// da almeno [Impostazioni.giorniFermo] giorni.
bool isFermo(Articolo a, Impostazioni imp, DateTime oggi) {
  if (a.venduto || a.pubblicazioni.isEmpty) return false;
  final riferimento = a.ultimoRibasso ?? a.online;
  return giorniTra(riferimento, oggi) >= imp.giorniFermo;
}

/// Prezzo ribassato, arrotondato all'euro (sotto i 20 €) o ai 5 € inferiori sopra.
/// Mai sotto il costo, se noto, e mai sotto 1 €.
double prezzoSuggerito(Articolo a, Impostazioni imp) {
  final grezzo = a.prezzo * (100 - imp.percRibasso) / 100;
  double p = grezzo < 20 ? grezzo.floorToDouble() : (grezzo / 5).floorToDouble() * 5;
  if (p >= a.prezzo) p = a.prezzo - 1;
  final minimo = a.costo != null && a.costo! > 0 ? a.costo! : 1.0;
  if (p < minimo) p = minimo;
  return p;
}

/// Cosa fare con un articolo fermo.
List<String> consigli(Articolo a, Impostazioni imp, DateTime oggi) {
  final out = <String>[];
  if (a.foto.length < 4) out.add('Aggiungi foto: almeno 4, con etichetta e dettagli.');
  if (a.note.trim().length < 40) out.add('Allunga la descrizione: misure, difetti, come veste.');
  if (a.marca.trim().isEmpty) out.add('Indica la marca: è la prima cosa che si cerca.');
  final mancanti = imp.attive.where((p) => !a.pubblicazioni.containsKey(p)).toList();
  if (mancanti.isNotEmpty) {
    out.add('Pubblicalo anche su: ${mancanti.map((p) => p.nome).join(', ')}.');
  }
  out.add('Abbassa il prezzo a ${prezzoSuggerito(a, imp).toStringAsFixed(0)} € '
      '(chi l\'ha nei preferiti riceve un avviso).');
  return out;
}

class Statistiche {
  final int inVendita;
  final int venduti;
  final double incassato;
  final double? guadagno; // solo sugli articoli con costo noto
  final double valoreInVendita;
  final double? giorniMediVendita;
  final Map<Piattaforma, int> vendutiPer;
  final Map<Piattaforma, double> incassatoPer;
  final int fermi;

  const Statistiche({
    required this.inVendita,
    required this.venduti,
    required this.incassato,
    required this.guadagno,
    required this.valoreInVendita,
    required this.giorniMediVendita,
    required this.vendutiPer,
    required this.incassatoPer,
    required this.fermi,
  });
}

Statistiche calcolaStatistiche(List<Articolo> tutti, Impostazioni imp, DateTime oggi,
    {int? anno}) {
  final venduti = tutti
      .where((a) => a.venduto && (anno == null || a.vendutoIl!.year == anno))
      .toList();
  final inVendita = tutti.where((a) => !a.venduto).toList();
  final incassato = venduti.fold<double>(0, (s, a) => s + (a.prezzoVendita ?? a.prezzo));
  final conCosto = venduti.where((a) => a.costo != null).toList();
  final guadagno = conCosto.isEmpty
      ? null
      : conCosto.fold<double>(0, (s, a) => s + (a.prezzoVendita ?? a.prezzo) - a.costo!);
  final giorni = venduti.map((a) => giorniTra(a.online, a.vendutoIl!)).toList();
  final per = <Piattaforma, int>{};
  final incPer = <Piattaforma, double>{};
  for (final a in venduti) {
    final p = a.vendutoSu;
    if (p == null) continue;
    per[p] = (per[p] ?? 0) + 1;
    incPer[p] = (incPer[p] ?? 0) + (a.prezzoVendita ?? a.prezzo);
  }
  return Statistiche(
    inVendita: inVendita.length,
    venduti: venduti.length,
    incassato: incassato,
    guadagno: guadagno,
    valoreInVendita: inVendita.fold<double>(0, (s, a) => s + a.prezzo),
    giorniMediVendita: giorni.isEmpty ? null : giorni.reduce((a, b) => a + b) / giorni.length,
    vendutiPer: per,
    incassatoPer: incPer,
    fermi: inVendita.where((a) => isFermo(a, imp, oggi)).length,
  );
}

/// Segna la vendita: registra prezzo e piattaforma.
Articolo segnaVenduto(Articolo a, Piattaforma su, double prezzo, DateTime quando) {
  return a.copyWith(vendutoIl: quando, prezzoVendita: prezzo, vendutoSu: su);
}

/// Applica un ribasso: nuovo prezzo su tutte le piattaforme attive dell'articolo.
Articolo applicaRibasso(Articolo a, double nuovo, DateTime quando) {
  return a.copyWith(
    prezzo: nuovo,
    ultimoRibasso: quando,
    pubblicazioni: {
      for (final e in a.pubblicazioni.entries) e.key: e.value.copyWith(prezzo: nuovo),
    },
  );
}
