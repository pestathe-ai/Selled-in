// Adatta un articolo al formato di ogni piattaforma. Puro Dart.
import 'models.dart';

class TestoAnnuncio {
  final String titolo; // vuoto se la piattaforma non usa un titolo
  final String descrizione;
  final double prezzo;
  const TestoAnnuncio(this.titolo, this.descrizione, this.prezzo);

  /// Tutto insieme, per incollare in un colpo solo.
  String get completo => [
        if (titolo.isNotEmpty) titolo,
        descrizione,
        'Prezzo: ${euro(prezzo)}',
      ].join('\n\n');
}

String euro(double v) {
  final intero = v == v.roundToDouble();
  final s = intero ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceAll('.', ',');
  return '€ $s';
}

String _maiuscola(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Titolo "Marca Tipo Taglia Colore" tagliato alla lunghezza massima,
/// senza spezzare le parole. Toglie prima il colore, poi la taglia se serve.
String titoloPer(Articolo a, int max) {
  final marca = a.marca.trim();
  final tipo = _maiuscola(a.tipo.trim());
  final taglia = a.taglia.trim().isEmpty ? '' : 'tg ${a.taglia.trim()}';
  final colore = a.colore.trim();
  final tentativi = [
    [marca, tipo, taglia, colore],
    [marca, tipo, taglia],
    [marca, tipo],
    [tipo],
  ];
  for (final parti in tentativi) {
    final t = parti.where((p) => p.isNotEmpty).join(' ');
    if (max <= 0 || t.length <= max) return t;
  }
  // Ultima risorsa: taglia sulla parola.
  final parole = tipo.split(' ');
  var out = '';
  for (final p in parole) {
    final prova = out.isEmpty ? p : '$out $p';
    if (prova.length > max) break;
    out = prova;
  }
  return out.isEmpty ? tipo.substring(0, max) : out;
}

/// Hashtag da marca, tipo e colore (minuscoli, senza spazi né simboli).
List<String> hashtag(Articolo a, {int massimo = 5}) {
  String pulisci(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9àèéìòù]"), '');
  final candidati = <String>[
    a.marca,
    ...a.tipo.split(' ').where((w) => w.length > 3),
    a.colore,
  ].map(pulisci).where((s) => s.length > 2).toList();
  final visti = <String>{};
  return [
    for (final c in candidati)
      if (visti.add(c)) '#$c'
  ].take(massimo).toList();
}

String _scheda(Articolo a) {
  final righe = <String>[
    if (a.marca.isNotEmpty) 'Marca: ${a.marca}',
    if (a.taglia.isNotEmpty) 'Taglia: ${a.taglia}',
    if (a.colore.isNotEmpty) 'Colore: ${a.colore}',
    if (a.materiale.isNotEmpty) 'Materiale: ${a.materiale}',
    'Condizioni: ${a.condizione}',
  ];
  return righe.join('\n');
}

String _consegna(Impostazioni imp) {
  final parti = <String>[
    if (imp.spedizione) 'Spedisco in tutta Italia',
    if (imp.ritiroAMano) 'ritiro a mano${imp.citta.isNotEmpty ? ' a ${imp.citta}' : ''}',
  ];
  if (parti.isEmpty) return '';
  final s = parti.join(', oppure ');
  return '${_maiuscola(s)}.';
}

TestoAnnuncio annuncioPer(Articolo a, Piattaforma p, Impostazioni imp) {
  final titolo = p.maxTitolo == 0 ? '' : titoloPer(a, p.maxTitolo);
  final note = a.note.trim();
  final consegna = _consegna(imp);
  final prezzo = a.pubblicazioni[p]?.prezzo ?? a.prezzo;

  String desc;
  switch (p) {
    case Piattaforma.vinted:
      desc = [
        if (note.isNotEmpty) note,
        _scheda(a),
        if (consegna.isNotEmpty && imp.ritiroAMano) consegna,
        hashtag(a).join(' '),
      ].where((s) => s.isNotEmpty).join('\n\n');
    case Piattaforma.depop:
      // Depop non ha un titolo: la prima riga fa da titolo.
      desc = [
        titoloPer(a, 0),
        if (note.isNotEmpty) note,
        _scheda(a),
        if (consegna.isNotEmpty) consegna,
        hashtag(a, massimo: 5).join(' '),
      ].where((s) => s.isNotEmpty).join('\n\n');
    case Piattaforma.ebay:
      desc = [
        titoloPer(a, 0),
        _scheda(a),
        if (note.isNotEmpty) 'Descrizione:\n$note',
        if (consegna.isNotEmpty) consegna,
      ].join('\n\n');
    case Piattaforma.subito:
    case Piattaforma.wallapop:
    case Piattaforma.facebook:
      desc = [
        if (note.isNotEmpty) note,
        _scheda(a),
        if (consegna.isNotEmpty) consegna,
      ].join('\n\n');
  }
  return TestoAnnuncio(titolo, desc, prezzo);
}
