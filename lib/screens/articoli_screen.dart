import 'package:flutter/material.dart';

import '../formatter.dart';
import '../logic.dart';
import '../main.dart';
import '../models.dart';
import 'dettaglio_screen.dart';
import 'modifica_screen.dart';
import 'widgets.dart';

enum Filtro { inVendita, daRimuovere, venduti }

class ArticoliScreen extends StatefulWidget {
  final VoidCallback onVaiARivedere;
  const ArticoliScreen({super.key, required this.onVaiARivedere});

  @override
  State<ArticoliScreen> createState() => _ArticoliScreenState();
}

class _ArticoliScreenState extends State<ArticoliScreen> {
  Filtro filtro = Filtro.inVendita;

  @override
  Widget build(BuildContext context) {
    final imp = archivio.impostazioni;
    final oggi = DateTime.now();
    final tutti = archivio.articoli;
    final daRimuovere = tutti.where((a) => a.daRimuovere.isNotEmpty).toList();
    final fermi = tutti.where((a) => isFermo(a, imp, oggi)).length;
    final lista = switch (filtro) {
      Filtro.inVendita => tutti.where((a) => !a.venduto).toList(),
      Filtro.daRimuovere => daRimuovere,
      Filtro.venduti => tutti.where((a) => a.venduto).toList()
        ..sort((a, b) => b.vendutoIl!.compareTo(a.vendutoIl!)),
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Text('Selled', style: marchio(22, colore: Colori.blu)),
          Text('-in', style: marchio(22, colore: Colori.arancio)),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colori.arancio,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ModificaScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo articolo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          if (daRimuovere.isNotEmpty && filtro != Filtro.daRimuovere)
            _Banner(
              icona: Icons.warning_amber_rounded,
              colore: Colors.red.shade700,
              testo: '${daRimuovere.length} ${daRimuovere.length == 1 ? 'articolo venduto è' : 'articoli venduti sono'} ancora online altrove. Toglili per evitare doppie vendite.',
              azione: 'Vedi',
              onTap: () => setState(() => filtro = Filtro.daRimuovere),
            ),
          if (fermi > 0 && filtro == Filtro.inVendita)
            _Banner(
              icona: Icons.trending_down,
              colore: Colori.arancio,
              testo: '$fermi ${fermi == 1 ? 'articolo è fermo' : 'articoli sono fermi'} da più di ${imp.giorniFermo} giorni.',
              azione: 'Rivedi',
              onTap: widget.onVaiARivedere,
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('In vendita', Filtro.inVendita),
              _chip('Da togliere${daRimuovere.isEmpty ? '' : ' (${daRimuovere.length})'}', Filtro.daRimuovere),
              _chip('Venduti', Filtro.venduti),
            ]),
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            (switch (filtro) {
              Filtro.inVendita => const Vuoto(
                  icona: Icons.checkroom,
                  titolo: 'Nessun articolo in vendita',
                  testo: 'Aggiungi un articolo una volta sola: Selled-in prepara l\'annuncio per ogni piattaforma.'),
              Filtro.daRimuovere => const Vuoto(
                  icona: Icons.check_circle_outline,
                  titolo: 'Tutto in ordine',
                  testo: 'Nessun annuncio da togliere.'),
              Filtro.venduti => const Vuoto(
                  icona: Icons.sell_outlined, titolo: 'Ancora nessuna vendita', testo: 'Arriverà!'),
            })
          else
            ...lista.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RigaArticolo(a, fermo: isFermo(a, imp, oggi)),
                )),
          const Firma(),
        ],
      ),
    );
  }

  Widget _chip(String testo, Filtro f) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(testo),
          selected: filtro == f,
          onSelected: (_) => setState(() => filtro = f),
        ),
      );
}

class _Banner extends StatelessWidget {
  final IconData icona;
  final Color colore;
  final String testo;
  final String azione;
  final VoidCallback onTap;
  const _Banner(
      {required this.icona, required this.colore, required this.testo, required this.azione, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: colore.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icona, color: colore),
          const SizedBox(width: 10),
          Expanded(child: Text(testo, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: onTap, child: Text(azione)),
        ]),
      );
}

class _RigaArticolo extends StatelessWidget {
  final Articolo a;
  final bool fermo;
  const _RigaArticolo(this.a, {required this.fermo});

  @override
  Widget build(BuildContext context) {
    final giorni = giorniTra(a.online, a.vendutoIl ?? DateTime.now());
    final sotto = a.venduto
        ? 'Venduto su ${a.vendutoSu?.nome ?? '?'} a ${euro(a.prezzoVendita ?? a.prezzo)}'
        : a.pubblicazioni.isEmpty
            ? 'Non ancora pubblicato'
            : 'Online da $giorni ${giorni == 1 ? 'giorno' : 'giorni'}';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => DettaglioScreen(id: a.id))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Miniatura(a.foto.isEmpty ? null : a.foto.first),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titoloPer(a, 0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sotto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: fermo ? Colori.arancio : Colori.inchiostro.withValues(alpha: 0.6))),
                const SizedBox(height: 6),
                Row(children: [
                  for (final p in a.pubblicazioni.keys)
                    EtichettaPiattaforma(p,
                        attenua: a.venduto && p != a.vendutoSu && a.pubblicazioni[p]!.rimosso),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            Text(euro(a.venduto ? (a.prezzoVendita ?? a.prezzo) : a.prezzo),
                style: marchio(16, peso: 700, colore: Colori.blu)),
          ]),
        ),
      ),
    );
  }
}
