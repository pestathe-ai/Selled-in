import 'package:flutter_test/flutter_test.dart';
import 'package:selled_in/autofill.dart';
import 'package:selled_in/formatter.dart';
import 'package:selled_in/logic.dart';
import 'package:selled_in/models.dart';

Articolo giacca({Map<Piattaforma, Pubblicazione> pubs = const {}, double? costo}) => Articolo(
      id: '1',
      tipo: 'giacca in jeans oversize',
      marca: "Levi's",
      taglia: 'M',
      colore: 'blu',
      materiale: 'cotone',
      note: 'Indossata due volte, nessun difetto.',
      prezzo: 35,
      costo: costo,
      creato: DateTime(2026, 1, 1),
      pubblicazioni: pubs,
    );

void main() {
  const imp = Impostazioni();

  group('formattazione', () {
    test('titolo completo e lunghezza massima', () {
      final a = giacca();
      expect(titoloPer(a, 0), "Levi's Giacca in jeans oversize tg M blu");
      for (final p in Piattaforma.values.where((p) => p.maxTitolo > 0)) {
        expect(titoloPer(a, p.maxTitolo).length, lessThanOrEqualTo(p.maxTitolo));
      }
      expect(titoloPer(a, 35), "Levi's Giacca in jeans oversize");
      expect(titoloPer(a, 30), 'Giacca in jeans oversize');
    });

    test('Depop senza titolo, descrizione con hashtag', () {
      final t = annuncioPer(giacca(), Piattaforma.depop, imp);
      expect(t.titolo, isEmpty);
      expect(t.descrizione.split('\n').first, contains('Giacca'));
      expect(t.descrizione, contains('#levis'));
    });

    test('eBay ha la scheda con marca e condizioni', () {
      final t = annuncioPer(giacca(), Piattaforma.ebay, imp);
      expect(t.descrizione, contains("Marca: Levi's"));
      expect(t.descrizione, contains('Condizioni: Ottime condizioni'));
      expect(t.descrizione, contains('Spedisco'));
    });

    test('hashtag senza doppioni e al massimo 5', () {
      final h = hashtag(giacca());
      expect(h.length, lessThanOrEqualTo(5));
      expect(h.toSet().length, h.length);
    });

    test('euro', () {
      expect(euro(35), '€ 35');
      expect(euro(12.5), '€ 12,50');
    });
  });

  group('logica', () {
    test('articolo fermo dopo N giorni', () {
      final a = giacca(pubs: {Piattaforma.vinted: Pubblicazione(data: DateTime(2026, 1, 1), prezzo: 35)});
      expect(isFermo(a, imp, DateTime(2026, 1, 15)), isFalse);
      expect(isFermo(a, imp, DateTime(2026, 1, 22)), isTrue);
      final ribassato = applicaRibasso(a, 30, DateTime(2026, 1, 22));
      expect(isFermo(ribassato, imp, DateTime(2026, 1, 25)), isFalse);
      expect(ribassato.pubblicazioni[Piattaforma.vinted]!.prezzo, 30);
    });

    test('mai pubblicato non è fermo', () {
      expect(isFermo(giacca(), imp, DateTime(2027, 1, 1)), isFalse);
    });

    test('prezzo suggerito rispetta il costo', () {
      expect(prezzoSuggerito(giacca(), imp), 30); // 31.5 -> 30
      expect(prezzoSuggerito(giacca(costo: 33), imp), 33);
      final economico = Articolo(id: 'x', tipo: 't', prezzo: 5, creato: DateTime(2026));
      expect(prezzoSuggerito(economico, imp), 4);
    });

    test('vendita: annunci da togliere e statistiche', () {
      final a = giacca(costo: 10, pubs: {
        Piattaforma.vinted: Pubblicazione(data: DateTime(2026, 1, 1), prezzo: 35),
        Piattaforma.subito: Pubblicazione(data: DateTime(2026, 1, 3), prezzo: 35),
      });
      final v = segnaVenduto(a, Piattaforma.vinted, 32, DateTime(2026, 1, 11));
      expect(v.daRimuovere, [Piattaforma.subito]);
      final s = calcolaStatistiche([v], imp, DateTime(2026, 2, 1), anno: 2026);
      expect(s.venduti, 1);
      expect(s.incassato, 32);
      expect(s.guadagno, 22);
      expect(s.giorniMediVendita, 10);
      expect(s.vendutiPer[Piattaforma.vinted], 1);
    });

    test('JSON andata e ritorno', () {
      final a = segnaVenduto(
          giacca(costo: 10, pubs: {Piattaforma.ebay: Pubblicazione(data: DateTime(2026, 1, 1), prezzo: 35)}),
          Piattaforma.ebay,
          30,
          DateTime(2026, 2, 1));
      final b = Articolo.fromJson(a.toJson());
      expect(b.toJson(), a.toJson());
      final i = Impostazioni.fromJson(const Impostazioni(automazioni: true).toJson());
      expect(i.automazioni, isTrue);
      expect(i.attive, const Impostazioni().attive);
    });
  });

  group('compilazione automatica', () {
    test('lo script contiene i dati codificati in modo sicuro', () {
      final js = scriptCompilazione(titolo: 'Giacca "bella"', descrizione: "riga 1\nl'altra", prezzo: 12.5);
      expect(js, contains(r'Giacca \"bella\"'));
      expect(js, contains(r'riga 1\nl'));
      expect(js, contains('"12,50"'));
      expect(js, contains('$canaleJs.postMessage'));
    });

    test('esito leggibile', () {
      final e = EsitoCompilazione.daMessaggio('{"compilati":["titolo","prezzo"],"mancanti":["descrizione"]}');
      expect(e.riepilogo, contains('descrizione'));
      expect(EsitoCompilazione.daMessaggio('rotto').compilati, isEmpty);
    });
  });
}
