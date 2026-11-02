import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models.dart';
import 'widgets.dart';

class ModificaScreen extends StatefulWidget {
  final Articolo? articolo;
  const ModificaScreen({super.key, this.articolo});

  @override
  State<ModificaScreen> createState() => _ModificaScreenState();
}

class _ModificaScreenState extends State<ModificaScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController tipo, marca, taglia, colore, materiale, note, prezzo, costo;
  late String condizione;
  late List<String> foto;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.articolo;
    tipo = TextEditingController(text: a?.tipo ?? '');
    marca = TextEditingController(text: a?.marca ?? '');
    taglia = TextEditingController(text: a?.taglia ?? '');
    colore = TextEditingController(text: a?.colore ?? '');
    materiale = TextEditingController(text: a?.materiale ?? '');
    note = TextEditingController(text: a?.note ?? '');
    prezzo = TextEditingController(text: a == null ? '' : _num(a.prezzo));
    costo = TextEditingController(text: a?.costo == null ? '' : _num(a!.costo!));
    condizione = a?.condizione ?? 'Ottime condizioni';
    foto = [...?a?.foto];
  }

  String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [tipo, marca, taglia, colore, materiale, note, prezzo, costo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _aggiungiFoto(ImageSource fonte) async {
    final picker = ImagePicker();
    final scelte = <XFile>[];
    if (fonte == ImageSource.camera) {
      final x = await picker.pickImage(source: fonte, imageQuality: 85, maxWidth: 2000);
      if (x != null) scelte.add(x);
    } else {
      scelte.addAll(await picker.pickMultiImage(imageQuality: 85, maxWidth: 2000));
    }
    for (final x in scelte) {
      final p = await archivio.importaFoto(x.path);
      if (mounted) setState(() => foto.add(p));
    }
  }

  Future<void> _salva() async {
    if (!_form.currentState!.validate()) return;
    setState(() => salvando = true);
    final base = widget.articolo ??
        Articolo(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          tipo: '',
          prezzo: 0,
          creato: DateTime.now(),
        );
    final c = leggiPrezzo(costo.text);
    final nuovoPrezzo = leggiPrezzo(prezzo.text)!;
    final a = base.copyWith(
      tipo: tipo.text.trim(),
      marca: marca.text.trim(),
      taglia: taglia.text.trim(),
      colore: colore.text.trim(),
      materiale: materiale.text.trim(),
      note: note.text.trim(),
      condizione: condizione,
      prezzo: nuovoPrezzo,
      costo: c,
      azzeraCosto: c == null,
      foto: foto,
      // Se il prezzo cambia, aggiorna anche quello degli annunci già online.
      pubblicazioni: {
        for (final e in base.pubblicazioni.entries)
          e.key: base.prezzo != nuovoPrezzo ? e.value.copyWith(prezzo: nuovoPrezzo) : e.value,
      },
    );
    await archivio.salvaArticolo(a);
    if (mounted) Navigator.pop(context, a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.articolo == null ? 'Nuovo articolo' : 'Modifica')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Foto', style: marchio(15, peso: 700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < foto.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(children: [
                        Miniatura(foto[i], lato: 92),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => foto.removeAt(i)),
                            child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 14, color: Colors.white)),
                          ),
                        ),
                        if (i == 0)
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colori.arancio, borderRadius: BorderRadius.circular(6)),
                              child: const Text('Copertina',
                                  style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                      ]),
                    ),
                  _BottoneFoto(Icons.photo_library_outlined, 'Galleria',
                      () => _aggiungiFoto(ImageSource.gallery)),
                  _BottoneFoto(Icons.photo_camera_outlined, 'Scatta',
                      () => _aggiungiFoto(ImageSource.camera)),
                ],
              ),
            ),
            if (foto.length < 4)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Consiglio: almeno 4 foto, con etichetta e dettagli.',
                    style: TextStyle(fontSize: 12, color: Colori.inchiostro.withValues(alpha: 0.6))),
              ),
            const SizedBox(height: 20),
            _campo(tipo, 'Cos\'è *', 'es. Giacca in jeans',
                obbligatorio: true, maiuscola: TextCapitalization.sentences),
            Row(children: [
              Expanded(child: _campo(marca, 'Marca', 'es. Levi\'s', maiuscola: TextCapitalization.words)),
              const SizedBox(width: 12),
              Expanded(child: _campo(taglia, 'Taglia', 'es. M / 42')),
            ]),
            Row(children: [
              Expanded(child: _campo(colore, 'Colore', 'es. blu')),
              const SizedBox(width: 12),
              Expanded(child: _campo(materiale, 'Materiale', 'es. cotone')),
            ]),
            DropdownButtonFormField<String>(
              initialValue: condizioni.contains(condizione) ? condizione : condizioni.first,
              decoration: const InputDecoration(labelText: 'Condizioni'),
              items: [for (final c in condizioni) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => condizione = v ?? condizione),
            ),
            const SizedBox(height: 12),
            _campo(note, 'Descrizione', 'Misure, difetti, come veste, perché lo vendi…',
                righe: 4, maiuscola: TextCapitalization.sentences),
            Row(children: [
              Expanded(
                child: _campo(prezzo, 'Prezzo *', '€',
                    numero: true,
                    obbligatorio: true,
                    valida: (s) => (leggiPrezzo(s ?? '') ?? 0) > 0 ? null : 'Prezzo non valido'),
              ),
              const SizedBox(width: 12),
              Expanded(child: _campo(costo, 'Pagato (facoltativo)', '€', numero: true)),
            ]),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: salvando ? null : _salva,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, String hint,
          {bool obbligatorio = false,
          bool numero = false,
          int righe = 1,
          TextCapitalization maiuscola = TextCapitalization.none,
          String? Function(String?)? valida}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          minLines: righe,
          maxLines: righe == 1 ? 1 : 8,
          textCapitalization: maiuscola,
          keyboardType: numero ? const TextInputType.numberWithOptions(decimal: true) : null,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: valida ??
              (obbligatorio ? (s) => (s ?? '').trim().isEmpty ? 'Campo obbligatorio' : null : null),
        ),
      );
}

class _BottoneFoto extends StatelessWidget {
  final IconData icona;
  final String testo;
  final VoidCallback onTap;
  const _BottoneFoto(this.icona, this.testo, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 92,
            decoration: BoxDecoration(
              border: Border.all(color: Colori.blu.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icona, color: Colori.blu),
              const SizedBox(height: 4),
              Text(testo, style: const TextStyle(fontSize: 12, color: Colori.blu)),
            ]),
          ),
        ),
      );
}
