// Script per la compilazione automatica (funzione opzionale "Automazioni").
// Cerca nella pagina i campi titolo, descrizione e prezzo e li riempie.
// Non preme mai "Pubblica": l'ultima conferma resta sempre all'utente.
import 'dart:convert';

const canaleJs = 'SelledIn';

const _parole = {
  'titolo': ['title', 'titolo', 'titulo', 'nome articolo', 'oggetto', 'headline'],
  'descrizione': ['description', 'descrizione', 'descripción', 'descripcion', 'dettagli', 'testo'],
  'prezzo': ['price', 'prezzo', 'precio', 'importo', 'amount'],
};

String scriptCompilazione({
  required String titolo,
  required String descrizione,
  required double prezzo,
}) {
  final dati = jsonEncode({
    'titolo': titolo,
    'descrizione': descrizione,
    'prezzo': prezzo == prezzo.roundToDouble()
        ? prezzo.toStringAsFixed(0)
        : prezzo.toStringAsFixed(2).replaceAll('.', ','),
  });
  final parole = jsonEncode(_parole);
  return '''
(function(dati, parole){
  function testo(el){
    var t = [el.name, el.id, el.placeholder, el.getAttribute('aria-label'),
             el.getAttribute('data-testid'), el.getAttribute('autocomplete')];
    if (el.id) { var l = document.querySelector('label[for="' + el.id + '"]'); if (l) t.push(l.innerText || l.textContent); }
    var c = el.closest('label'); if (c) t.push(c.innerText || c.textContent);
    var lb = el.getAttribute('aria-labelledby');
    if (lb) { lb.split(' ').forEach(function(i){ var x = document.getElementById(i); if (x) t.push(x.innerText || x.textContent); }); }
    return t.filter(Boolean).join(' ').toLowerCase();
  }
  function visibile(el){ var r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0 && !el.disabled && !el.readOnly; }
  function imposta(el, v){
    el.focus();
    if (el.isContentEditable) {
      el.textContent = v;
    } else {
      var proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
      var d = Object.getOwnPropertyDescriptor(proto, 'value');
      if (d && d.set) { d.set.call(el, v); } else { el.value = v; }
    }
    ['input', 'change', 'keyup', 'blur'].forEach(function(n){ el.dispatchEvent(new Event(n, {bubbles: true})); });
  }
  var campi = Array.prototype.slice.call(document.querySelectorAll(
    'input:not([type]), input[type=text], input[type=number], input[type=tel], textarea, [contenteditable=true]'))
    .filter(visibile)
    .filter(function(el){ return !/search|cerca|buscar|query/.test(testo(el)); });
  var usati = [], esito = {compilati: [], mancanti: []};
  ['titolo', 'descrizione', 'prezzo'].forEach(function(k){
    var migliore = null, punti = 0;
    campi.forEach(function(el){
      if (usati.indexOf(el) >= 0) return;
      var t = testo(el), p = 0;
      parole[k].forEach(function(w){ if (t.indexOf(w) >= 0) p += 2; });
      if (k === 'descrizione' && (el.tagName === 'TEXTAREA' || el.isContentEditable)) p += 1;
      if (k === 'prezzo' && (el.type === 'number' || el.inputMode === 'decimal' || el.inputMode === 'numeric')) p += 1;
      if (k === 'titolo' && el.tagName === 'TEXTAREA') p -= 1;
      if (p > punti) { punti = p; migliore = el; }
    });
    if (!migliore && k === 'descrizione') {
      migliore = campi.filter(function(el){ return el.tagName === 'TEXTAREA' && usati.indexOf(el) < 0; })[0] || null;
    }
    if (migliore && dati[k]) { imposta(migliore, dati[k]); usati.push(migliore); esito.compilati.push(k); }
    else { esito.mancanti.push(k); }
  });
  if (window.$canaleJs) { $canaleJs.postMessage(JSON.stringify(esito)); }
})($dati, $parole);
''';
}

class EsitoCompilazione {
  final List<String> compilati;
  final List<String> mancanti;
  const EsitoCompilazione(this.compilati, this.mancanti);

  factory EsitoCompilazione.daMessaggio(String msg) {
    try {
      final j = jsonDecode(msg) as Map<String, dynamic>;
      return EsitoCompilazione(
        List<String>.from(j['compilati'] as List? ?? const []),
        List<String>.from(j['mancanti'] as List? ?? const []),
      );
    } catch (_) {
      return const EsitoCompilazione([], ['titolo', 'descrizione', 'prezzo']);
    }
  }

  String get riepilogo {
    if (compilati.isEmpty) {
      return 'Non ho trovato i campi in questa pagina. Apri il modulo "Vendi" e riprova.';
    }
    final ok = 'Compilati: ${compilati.join(', ')}.';
    return mancanti.isEmpty ? '$ok Controlla, aggiungi le foto e pubblica.' : '$ok Da fare a mano: ${mancanti.join(', ')}.';
  }
}
