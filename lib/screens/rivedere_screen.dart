import 'package:flutter/material.dart';

import '../formatter.dart';
import '../logic.dart';
import '../main.dart';
import 'dettaglio_screen.dart';
import 'widgets.dart';

class RivedereScreen extends StatelessWidget {
  const RivedereScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final imp = archivio.impostazioni;
    final oggi = DateTime.now();
    final fermi = archivio.articoli.where((a) => isFermo(a, imp, oggi)).toList()
      ..sort((a, b) => a.online.compareTo(b.online));
    final mai = archivio.articoli.where((a) => !a.venduto && a.pubblicazioni.isEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Da rivedere')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text('Articoli online da più di ${imp.giorniFermo} giorni senza ribassi.',
              style: TextStyle(color: Colori.inchiostro.withValues(alpha: 0.7))),
          const SizedBox(height: 12),
          if (fermi.isEmpty)
            const Vuoto(
                icona: Icons.celebration_outlined,
                titolo: 'Nessun articolo fermo',
                testo: 'Qui compariranno gli annunci che non si muovono, con cosa fare.'),
          for (final a in fermi) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  InkWell(
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => DettaglioScreen(id: a.id))),
                    child: Row(children: [
                      Miniatura(a.foto.isEmpty ? null : a.foto.first, lato: 48),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(titoloPer(a, 0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                              '${euro(a.prezzo)} · fermo da ${giorniTra(a.ultimoRibasso ?? a.online, oggi)} giorni',
                              style: const TextStyle(fontSize: 12, color: Colori.arancio)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  for (final c in consigli(a, imp, oggi))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('•  '),
                        Expanded(child: Text(c, style: const TextStyle(fontSize: 13))),
                      ]),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final nuovo = prezzoSuggerito(a, imp);
                        await archivio.salvaArticolo(applicaRibasso(a, nuovo, DateTime.now()));
                        if (context.mounted) {
                          avviso(context,
                              'Prezzo portato a ${euro(nuovo)}. Aggiornalo anche negli annunci online.');
                        }
                      },
                      icon: const Icon(Icons.trending_down, size: 18),
                      label: Text('Ribassa a ${euro(prezzoSuggerito(a, imp))}'),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (mai.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Mai pubblicati', style: marchio(16, peso: 700)),
            const SizedBox(height: 8),
            for (final a in mai)
              Card(
                child: ListTile(
                  leading: Miniatura(a.foto.isEmpty ? null : a.foto.first, lato: 40),
                  title: Text(titoloPer(a, 0), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: const Text('Pronto da pubblicare'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => DettaglioScreen(id: a.id))),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
