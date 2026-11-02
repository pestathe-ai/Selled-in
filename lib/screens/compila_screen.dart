import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../autofill.dart';
import '../formatter.dart';
import '../main.dart';
import '../models.dart';
import 'widgets.dart';

/// Funzione "Automazioni": apre il sito della piattaforma dentro l'app,
/// compila il modulo e passa le foto dell'articolo al pulsante di caricamento.
/// Non pubblica mai da sola.
class CompilaScreen extends StatefulWidget {
  final Articolo articolo;
  final Piattaforma piattaforma;
  const CompilaScreen({super.key, required this.articolo, required this.piattaforma});

  @override
  State<CompilaScreen> createState() => _CompilaScreenState();
}

class _CompilaScreenState extends State<CompilaScreen> {
  late final WebViewController _web;
  int _progresso = 0;
  bool _guidaVisibile = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progresso = p);
        },
      ))
      ..addJavaScriptChannel(canaleJs, onMessageReceived: (m) {
        if (!mounted) return;
        avviso(context, EsitoCompilazione.daMessaggio(m.message).riepilogo);
      })
      ..loadRequest(Uri.parse(archivio.impostazioni.urlPer(widget.piattaforma)));

    final piattaformaWeb = _web.platform;
    if (piattaformaWeb is AndroidWebViewController) {
      piattaformaWeb.setOnShowFileSelector(_sceltaFile);
      piattaformaWeb.setMediaPlaybackRequiresUserGesture(true);
    }
  }

  /// Quando il sito chiede di caricare foto, offre quelle dell'articolo.
  Future<List<String>> _sceltaFile(FileSelectorParams params) async {
    final foto = widget.articolo.foto.where((f) => File(f).existsSync()).toList();
    final scelta = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (foto.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.collections, color: Colori.blu),
              title: Text('Usa le foto dell\'articolo (${foto.length})'),
              onTap: () => Navigator.pop(c, 'articolo'),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Scegli dalla galleria'),
            onTap: () => Navigator.pop(c, 'galleria'),
          ),
        ]),
      ),
    );
    if (scelta == 'articolo') {
      return [for (final f in foto) Uri.file(f).toString()];
    }
    if (scelta == 'galleria') {
      final x = await ImagePicker().pickMultiImage();
      return [for (final f in x) Uri.file(f.path).toString()];
    }
    return [];
  }

  Future<void> _compila() async {
    final t = annuncioPer(widget.articolo, widget.piattaforma, archivio.impostazioni);
    final titolo = t.titolo.isNotEmpty ? t.titolo : titoloPer(widget.articolo, 0);
    try {
      await _web.runJavaScript(scriptCompilazione(
        titolo: titolo,
        descrizione: t.descrizione,
        prezzo: t.prezzo,
      ));
    } catch (e) {
      if (mounted) avviso(context, 'Compilazione non riuscita su questa pagina.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.piattaforma;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.nome),
        actions: [
          IconButton(
            tooltip: 'Ricarica',
            icon: const Icon(Icons.refresh),
            onPressed: () => _web.reload(),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fatto'),
          ),
        ],
        bottom: _progresso < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progresso / 100, minHeight: 3))
            : null,
      ),
      body: Column(children: [
        if (_guidaVisibile)
          Container(
            color: Colori.blu.withValues(alpha: 0.08),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(children: [
              Expanded(
                child: Text(
                  '1. Accedi se richiesto e apri il modulo "Vendi".\n'
                  '2. Tocca "Compila": inserisco titolo, descrizione e prezzo.\n'
                  '3. Al caricamento foto scegli "Usa le foto dell\'articolo".\n'
                  '4. Controlla, completa categoria e taglia, premi Pubblica. Poi "Fatto".',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _guidaVisibile = false),
              ),
            ]),
          ),
        Expanded(child: WebViewWidget(controller: _web)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colori.arancio,
        foregroundColor: Colors.white,
        onPressed: _compila,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Compila'),
      ),
    );
  }
}
