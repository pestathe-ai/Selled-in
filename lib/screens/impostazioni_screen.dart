import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../models.dart';

class ImpostazioniScreen extends StatefulWidget {
  const ImpostazioniScreen({super.key});

  @override
  State<ImpostazioniScreen> createState() => _ImpostazioniScreenState();
}

class _ImpostazioniScreenState extends State<ImpostazioniScreen> {
  late final TextEditingController citta =
      TextEditingController(text: archivio.impostazioni.citta);

  @override
  void dispose() {
    citta.dispose();
    super.dispose();
  }

  void _salva(Impostazioni i) => archivio.salvaImpostazioni(i);

  Future<void> _attivaAutomazioni(bool v) async {
    final imp = archivio.impostazioni;
    if (!v) {
      _salva(imp.copyWith(automazioni: false));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Attivare le automazioni?'),
        content: const Text(
          'Selled-in aprirà i siti delle piattaforme dentro l\'app e compilerà per te '
          'titolo, descrizione, prezzo e foto.\n\n'
          '• Accedi tu al tuo account: l\'app non vede né salva la password.\n'
          '• Non pubblica mai da sola: l\'ultimo tasto lo premi tu.\n'
          '• I siti cambiano spesso: a volte la compilazione può non trovare i campi.\n'
          '• Le piattaforme possono limitare l\'uso di strumenti esterni: usala con moderazione.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Attiva')),
        ],
      ),
    );
    if (ok == true) _salva(archivio.impostazioni.copyWith(automazioni: true));
  }

  Future<void> _esporta() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/selled-in-articoli.csv');
    await f.writeAsString(archivio.esportaCsv());
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/csv')]));
  }

  Future<void> _modificaUrl(Piattaforma p) async {
    final imp = archivio.impostazioni;
    final c = TextEditingController(text: imp.urlPer(p));
    final nuovo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagina di vendita ${p.nome}'),
        content: TextField(controller: c, keyboardType: TextInputType.url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Predefinita')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Salva')),
        ],
      ),
    );
    if (nuovo == null) return;
    _salva(imp.copyWith(urlPersonalizzati: {...imp.urlPersonalizzati, p: nuovo}));
  }

  @override
  Widget build(BuildContext context) {
    final imp = archivio.impostazioni;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _titolo('Dove vendi'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in Piattaforma.values)
              FilterChip(
                label: Text(p.nome),
                selected: imp.attive.contains(p),
                onSelected: (v) {
                  final nuove = {...imp.attive};
                  v ? nuove.add(p) : nuove.remove(p);
                  if (nuove.isNotEmpty) _salva(imp.copyWith(attive: nuove));
                },
              ),
          ]),
          _titolo('Consegna (nelle descrizioni)'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Spedisco'),
            value: imp.spedizione,
            onChanged: (v) => _salva(imp.copyWith(spedizione: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ritiro a mano'),
            value: imp.ritiroAMano,
            onChanged: (v) => _salva(imp.copyWith(ritiroAMano: v)),
          ),
          if (imp.ritiroAMano)
            TextField(
              controller: citta,
              decoration: const InputDecoration(labelText: 'Città'),
              onChanged: (v) => _salva(archivio.impostazioni.copyWith(citta: v.trim())),
            ),
          _titolo('Articoli fermi'),
          Text('Avvisami dopo ${imp.giorniFermo} giorni senza vendita'),
          Slider(
            value: imp.giorniFermo.toDouble(),
            min: 7,
            max: 60,
            divisions: 53,
            label: '${imp.giorniFermo} giorni',
            onChanged: (v) => _salva(imp.copyWith(giorniFermo: v.round())),
          ),
          Text('Ribasso suggerito: ${imp.percRibasso}%'),
          Slider(
            value: imp.percRibasso.toDouble(),
            min: 5,
            max: 30,
            divisions: 5,
            label: '${imp.percRibasso}%',
            onChanged: (v) => _salva(imp.copyWith(percRibasso: v.round())),
          ),
          _titolo('Automazioni'),
          Card(
            color: imp.automazioni ? Colori.arancio.withValues(alpha: 0.1) : null,
            child: SwitchListTile(
              title: const Text('Compilazione automatica'),
              subtitle: const Text('Inserisce testo, prezzo e foto direttamente sui siti delle piattaforme.'),
              value: imp.automazioni,
              onChanged: _attivaAutomazioni,
            ),
          ),
          if (imp.automazioni) ...[
            const SizedBox(height: 8),
            Text('Pagine di partenza (tocca per cambiarle se un sito si sposta):',
                style: TextStyle(fontSize: 12, color: Colori.inchiostro.withValues(alpha: 0.6))),
            for (final p in imp.attive)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(p.nome),
                subtitle: Text(imp.urlPer(p), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _modificaUrl(p),
              ),
          ],
          _titolo('Dati'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('Esporta in CSV'),
            subtitle: const Text('Apribile con Fogli Google o Excel'),
            onTap: _esporta,
          ),
          const Firma(),
        ],
      ),
    );
  }

  Widget _titolo(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: marchio(16, peso: 700)),
      );
}
