import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../formatter.dart';
import '../logic.dart';
import '../main.dart';
import '../models.dart';
import 'compila_screen.dart';
import 'modifica_screen.dart';
import 'widgets.dart';

class DettaglioScreen extends StatelessWidget {
  final String id;
  const DettaglioScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: archivio,
      builder: (context, _) {
        final a = archivio.trova(id);
        if (a == null) return const Scaffold();
        final imp = archivio.impostazioni;
        final piattaforme = {...imp.attive, ...a.pubblicazioni.keys}.toList()
          ..sort((x, y) => x.index.compareTo(y.index));
        return Scaffold(
          appBar: AppBar(
            title: Text(titoloPer(a, 0), maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Modifica',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ModificaScreen(articolo: a))),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'elimina') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Eliminare l\'articolo?'),
                        content: const Text('Verranno cancellate anche le sue foto nell\'app.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Elimina')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      Navigator.pop(context);
                      await archivio.elimina(a);
                    }
                  } else if (v == 'riapri') {
                    await archivio.salvaArticolo(a.copyWith(azzeraVendita: true));
                  }
                },
                itemBuilder: (_) => [
                  if (a.venduto) const PopupMenuItem(value: 'riapri', child: Text('Rimetti in vendita')),
                  const PopupMenuItem(value: 'elimina', child: Text('Elimina')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              if (a.foto.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: a.foto.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Miniatura(a.foto[i], lato: 160),
                  ),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Text(euro(a.prezzo), style: marchio(28, colore: Colori.blu)),
                const Spacer(),
                if (!a.venduto) ...[
                  OutlinedButton.icon(
                    onPressed: () => _ribassa(context, a),
                    icon: const Icon(Icons.trending_down, size: 18),
                    label: const Text('Ribassa'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _vendi(context, a, piattaforme),
                    icon: const Icon(Icons.sell, size: 18),
                    label: const Text('Venduto'),
                  ),
                ],
              ]),
              Text([a.condizione, if (a.costo != null) 'pagato ${euro(a.costo!)}'].join(' · '),
                  style: TextStyle(color: Colori.inchiostro.withValues(alpha: 0.6))),
              if (a.venduto) ...[
                const SizedBox(height: 16),
                _Venduto(a),
              ],
              const SizedBox(height: 20),
              Text(a.venduto ? 'Annunci' : 'Pubblica', style: marchio(18, peso: 700)),
              const SizedBox(height: 4),
              if (!a.venduto)
                Text('Tocca una piattaforma: titolo, descrizione e foto sono già pronti.',
                    style: TextStyle(fontSize: 13, color: Colori.inchiostro.withValues(alpha: 0.6))),
              const SizedBox(height: 10),
              for (final p in piattaforme)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RigaPiattaforma(a, p),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _ribassa(BuildContext context, Articolo a) async {
    final suggerito = prezzoSuggerito(a, archivio.impostazioni);
    final c = TextEditingController(text: suggerito.toStringAsFixed(0));
    final nuovo = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo prezzo'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ora: ${euro(a.prezzo)}. Suggerito: ${euro(suggerito)}.'),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '€ '),
          ),
          const SizedBox(height: 8),
          const Text('Ricordati di aggiornarlo anche negli annunci online.',
              style: TextStyle(fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, leggiPrezzo(c.text)), child: const Text('Applica')),
        ],
      ),
    );
    if (nuovo != null && nuovo > 0) {
      await archivio.salvaArticolo(applicaRibasso(a, nuovo, DateTime.now()));
    }
  }

  Future<void> _vendi(BuildContext context, Articolo a, List<Piattaforma> piattaforme) async {
    final opzioni = a.pubblicazioni.isNotEmpty ? a.pubblicazioni.keys.toList() : piattaforme;
    Piattaforma scelta = opzioni.first;
    final c = TextEditingController(text: a.prezzo.toStringAsFixed(a.prezzo == a.prezzo.roundToDouble() ? 0 : 2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Venduto!'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dove?'),
            Wrap(spacing: 6, children: [
              for (final p in opzioni)
                ChoiceChip(label: Text(p.nome), selected: p == scelta, onSelected: (_) => set(() => scelta = p)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prezzo finale', prefixText: '€ '),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Conferma')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final aggiornato = segnaVenduto(a, scelta, leggiPrezzo(c.text) ?? a.prezzo, DateTime.now());
      await archivio.salvaArticolo(aggiornato);
      if (context.mounted && aggiornato.daRimuovere.isNotEmpty) {
        avviso(context, 'Ora toglilo da: ${aggiornato.daRimuovere.map((p) => p.nome).join(', ')}');
      }
    }
  }
}

class _Venduto extends StatelessWidget {
  final Articolo a;
  const _Venduto(this.a);

  @override
  Widget build(BuildContext context) {
    final altri = a.pubblicazioni.keys.where((p) => p != a.vendutoSu).toList();
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Venduto su ${a.vendutoSu?.nome ?? '?'} a ${euro(a.prezzoVendita ?? a.prezzo)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (a.costo != null)
            Text('Guadagno: ${euro((a.prezzoVendita ?? a.prezzo) - a.costo!)}'),
          if (altri.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Togli l\'annuncio dalle altre piattaforme:'),
            for (final p in altri)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: a.pubblicazioni[p]!.rimosso,
                title: Text(p.nome),
                onChanged: (v) => archivio.salvaArticolo(a.copyWith(pubblicazioni: {
                  ...a.pubblicazioni,
                  p: a.pubblicazioni[p]!.copyWith(rimosso: v ?? false),
                })),
              ),
          ],
        ]),
      ),
    );
  }
}

class _RigaPiattaforma extends StatelessWidget {
  final Articolo a;
  final Piattaforma p;
  const _RigaPiattaforma(this.a, this.p);

  @override
  Widget build(BuildContext context) {
    final pub = a.pubblicazioni[p];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pub != null ? Colori.blu : Colori.blu.withValues(alpha: 0.1),
          child: Text(p.sigla,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: pub != null ? Colors.white : Colori.blu)),
        ),
        title: Text(p.nome),
        subtitle: Text(pub == null
            ? 'Non pubblicato'
            : 'Pubblicato il ${pub.data.day}/${pub.data.month} a ${euro(pub.prezzo)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: Colori.carta,
          builder: (_) => PreparaAnnuncio(articoloId: a.id, piattaforma: p),
        ),
      ),
    );
  }
}

class PreparaAnnuncio extends StatelessWidget {
  final String articoloId;
  final Piattaforma piattaforma;
  const PreparaAnnuncio({super.key, required this.articoloId, required this.piattaforma});

  Future<void> _copia(BuildContext context, String testo, String cosa) async {
    await Clipboard.setData(ClipboardData(text: testo));
    if (context.mounted) avviso(context, '$cosa copiato');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: archivio,
      builder: (context, _) {
        final a = archivio.trova(articoloId);
        if (a == null) return const SizedBox();
        final imp = archivio.impostazioni;
        final p = piattaforma;
        final t = annuncioPer(a, p, imp);
        final pub = a.pubblicazioni[p];
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Text('Annuncio per ${p.nome}', style: marchio(20, peso: 700)),
              const SizedBox(height: 12),
              if (imp.automazioni && !a.venduto) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colori.arancio, minimumSize: const Size.fromHeight(50)),
                  onPressed: () async {
                    final pubblicato = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => CompilaScreen(articolo: a, piattaforma: p)),
                    );
                    if (pubblicato == true) await _segnaPubblicato(a, p);
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Compila in automatico'),
                ),
                const SizedBox(height: 4),
                Text('Apre il sito, inserisce testo, prezzo e foto. Tu controlli e premi Pubblica.',
                    style: TextStyle(fontSize: 12, color: Colori.inchiostro.withValues(alpha: 0.6))),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Oppure a mano', style: marchio(15, peso: 700)),
                const SizedBox(height: 8),
              ],
              if (t.titolo.isNotEmpty)
                _Blocco(
                  etichetta: 'Titolo (${t.titolo.length}/${p.maxTitolo})',
                  testo: t.titolo,
                  onCopia: () => _copia(context, t.titolo, 'Titolo'),
                ),
              _Blocco(
                etichetta: 'Descrizione',
                testo: t.descrizione,
                onCopia: () => _copia(context, t.descrizione, 'Descrizione'),
              ),
              _Blocco(
                etichetta: 'Prezzo',
                testo: euro(t.prezzo),
                onCopia: () => _copia(
                    context,
                    t.prezzo == t.prezzo.roundToDouble()
                        ? t.prezzo.toStringAsFixed(0)
                        : t.prezzo.toStringAsFixed(2).replaceAll('.', ','),
                    'Prezzo'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: a.foto.isEmpty
                        ? null
                        : () => SharePlus.instance.share(ShareParams(
                              files: [for (final f in a.foto) XFile(f)],
                              text: t.completo,
                            )),
                    icon: const Icon(Icons.share),
                    label: Text(a.foto.isEmpty ? 'Nessuna foto' : 'Condividi foto (${a.foto.length})'),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                  'Le foto si aprono nel menu Condividi: scegli l\'app di ${p.nome}, se la propone. '
                  'Il testo viene incollato dove l\'app lo accetta.',
                  style: TextStyle(fontSize: 12, color: Colori.inchiostro.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              if (!a.venduto)
                pub == null
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        onPressed: () => _segnaPubblicato(a, p),
                        icon: const Icon(Icons.check),
                        label: const Text('Segna come pubblicato'),
                      )
                    : TextButton(
                        onPressed: () {
                          final nuove = {...a.pubblicazioni}..remove(p);
                          archivio.salvaArticolo(a.copyWith(pubblicazioni: nuove));
                        },
                        child: Text('Non è più su ${p.nome}'),
                      ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _segnaPubblicato(Articolo a, Piattaforma p) async {
    final fresco = archivio.trova(a.id) ?? a;
    await archivio.salvaArticolo(fresco.copyWith(pubblicazioni: {
      ...fresco.pubblicazioni,
      p: Pubblicazione(data: DateTime.now(), prezzo: fresco.prezzo),
    }));
  }
}

class _Blocco extends StatelessWidget {
  final String etichetta;
  final String testo;
  final VoidCallback onCopia;
  const _Blocco({required this.etichetta, required this.testo, required this.onCopia});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(etichetta,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colori.inchiostro.withValues(alpha: 0.6))),
                ),
                TextButton.icon(
                  onPressed: onCopia,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copia'),
                ),
              ]),
              SelectableText(testo),
            ]),
          ),
        ),
      );
}
