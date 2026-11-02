import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';

class Miniatura extends StatelessWidget {
  final String? percorso;
  final double lato;
  const Miniatura(this.percorso, {super.key, this.lato = 56});

  @override
  Widget build(BuildContext context) {
    final vuota = Container(
      width: lato,
      height: lato,
      color: Colori.blu.withValues(alpha: 0.08),
      child: const Icon(Icons.checkroom, color: Colori.blu),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: percorso == null
          ? vuota
          : Image.file(
              File(percorso!),
              width: lato,
              height: lato,
              fit: BoxFit.cover,
              cacheWidth: (lato * 3).round(),
              errorBuilder: (_, __, ___) => vuota,
            ),
    );
  }
}

class EtichettaPiattaforma extends StatelessWidget {
  final Piattaforma p;
  final bool attenua;
  const EtichettaPiattaforma(this.p, {super.key, this.attenua = false});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: attenua ? Colors.transparent : Colori.blu.withValues(alpha: 0.1),
          border: attenua ? Border.all(color: Colori.inchiostro.withValues(alpha: 0.2)) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(p.sigla,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: attenua ? Colori.inchiostro.withValues(alpha: 0.4) : Colori.blu)),
      );
}

class Vuoto extends StatelessWidget {
  final IconData icona;
  final String titolo;
  final String testo;
  const Vuoto({super.key, required this.icona, required this.titolo, required this.testo});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icona, size: 48, color: Colori.blu.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(titolo, style: marchio(18, peso: 700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(testo,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colori.inchiostro.withValues(alpha: 0.7))),
          ],
        ),
      );
}

void avviso(BuildContext context, String testo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(testo), behavior: SnackBarBehavior.floating));
}

double? leggiPrezzo(String s) => double.tryParse(s.trim().replaceAll('€', '').replaceAll(',', '.').trim());
