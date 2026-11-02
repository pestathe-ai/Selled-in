import 'package:flutter/material.dart';

import '../formatter.dart';
import '../logic.dart';
import '../main.dart';
import '../models.dart';

class StatisticheScreen extends StatefulWidget {
  const StatisticheScreen({super.key});

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  bool soloQuestAnno = true;

  @override
  Widget build(BuildContext context) {
    final oggi = DateTime.now();
    final s = calcolaStatistiche(archivio.articoli, archivio.impostazioni, oggi,
        anno: soloQuestAnno ? oggi.year : null);
    final annuali = calcolaStatistiche(archivio.articoli, archivio.impostazioni, oggi, anno: oggi.year);
    final maxVenduti = s.vendutiPer.values.fold<int>(0, (m, v) => v > m ? v : m);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text('${oggi.year}')),
              const ButtonSegment(value: false, label: Text('Sempre')),
            ],
            selected: {soloQuestAnno},
            onSelectionChanged: (v) => setState(() => soloQuestAnno = v.first),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _Tessera('Incassato', euro(s.incassato)),
              _Tessera('Guadagno', s.guadagno == null ? '—' : euro(s.guadagno!),
                  nota: s.guadagno == null ? 'Indica quanto hai pagato' : 'Sui capi con costo'),
              _Tessera('Venduti', '${s.venduti}'),
              _Tessera('Tempo medio',
                  s.giorniMediVendita == null ? '—' : '${s.giorniMediVendita!.round()} gg',
                  nota: 'Per vendere'),
              _Tessera('In vendita', '${s.inVendita}', nota: 'Valore ${euro(s.valoreInVendita)}'),
              _Tessera('Fermi', '${s.fermi}', colore: s.fermi > 0 ? Colori.arancio : null),
            ],
          ),
          const SizedBox(height: 20),
          Text('Dove vendi di più', style: marchio(16, peso: 700)),
          const SizedBox(height: 8),
          if (s.vendutiPer.isEmpty)
            Text('Ancora nessuna vendita registrata.',
                style: TextStyle(color: Colori.inchiostro.withValues(alpha: 0.6)))
          else
            for (final p in Piattaforma.values.where(s.vendutiPer.containsKey))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.nome)),
                    Text('${s.vendutiPer[p]} · ${euro(s.incassatoPer[p] ?? 0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.vendutiPer[p]! / maxVenduti,
                      minHeight: 8,
                      backgroundColor: Colori.blu.withValues(alpha: 0.08),
                    ),
                  ),
                ]),
              ),
          const SizedBox(height: 20),
          _SogliaFiscale(annuali, oggi.year),
        ],
      ),
    );
  }
}

class _Tessera extends StatelessWidget {
  final String titolo;
  final String valore;
  final String? nota;
  final Color? colore;
  const _Tessera(this.titolo, this.valore, {this.nota, this.colore});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(titolo, style: TextStyle(fontSize: 12, color: Colori.inchiostro.withValues(alpha: 0.6))),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valore, style: marchio(24, colore: colore ?? Colori.blu)),
            ),
            if (nota != null)
              Text(nota!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colori.inchiostro.withValues(alpha: 0.5))),
          ]),
        ),
      );
}

/// Promemoria DAC7: ogni piattaforma comunica al Fisco i venditori che in un anno
/// superano 30 vendite oppure 2.000 € incassati su quella piattaforma.
class _SogliaFiscale extends StatelessWidget {
  final Statistiche s;
  final int anno;
  const _SogliaFiscale(this.s, this.anno);

  @override
  Widget build(BuildContext context) {
    final righe = Piattaforma.values.where(s.vendutiPer.containsKey).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.account_balance_outlined, size: 18, color: Colori.blu),
            const SizedBox(width: 8),
            Text('Soglie di segnalazione $anno', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Con 30 vendite o 2.000 € incassati in un anno sulla stessa piattaforma, '
            'questa comunica i tuoi dati al Fisco (norma DAC7). Non è una tassa: '
            'per dubbi sulla tua situazione chiedi a un commercialista.',
            style: TextStyle(fontSize: 12, color: Colori.inchiostro.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          if (righe.isEmpty)
            const Text('Nessuna vendita quest\'anno.', style: TextStyle(fontSize: 13))
          else
            for (final p in righe)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Expanded(child: Text(p.nome, style: const TextStyle(fontSize: 13))),
                  Text(
                    '${s.vendutiPer[p]}/30 · ${euro(s.incassatoPer[p] ?? 0)}/2.000',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (s.vendutiPer[p]! >= 25 || (s.incassatoPer[p] ?? 0) >= 1700)
                          ? Colori.arancio
                          : Colori.inchiostro,
                    ),
                  ),
                ]),
              ),
        ]),
      ),
    );
  }
}
