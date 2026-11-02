// Modelli dati puri (nessun plugin), testabili in CI.

enum Piattaforma { vinted, subito, wallapop, ebay, depop, facebook }

extension PiattaformaInfo on Piattaforma {
  String get nome => switch (this) {
        Piattaforma.vinted => 'Vinted',
        Piattaforma.subito => 'Subito',
        Piattaforma.wallapop => 'Wallapop',
        Piattaforma.ebay => 'eBay',
        Piattaforma.depop => 'Depop',
        Piattaforma.facebook => 'Facebook Marketplace',
      };

  String get sigla => switch (this) {
        Piattaforma.vinted => 'VI',
        Piattaforma.subito => 'SU',
        Piattaforma.wallapop => 'WA',
        Piattaforma.ebay => 'EB',
        Piattaforma.depop => 'DE',
        Piattaforma.facebook => 'FB',
      };

  /// Lunghezza massima del titolo usata dall'app (valori prudenti, indicativi).
  /// 0 = la piattaforma non usa un titolo separato.
  int get maxTitolo => switch (this) {
        Piattaforma.vinted => 60,
        Piattaforma.subito => 50,
        Piattaforma.wallapop => 50,
        Piattaforma.ebay => 80,
        Piattaforma.depop => 0,
        Piattaforma.facebook => 100,
      };

  /// Pagina di partenza per la compilazione automatica (modificabile nelle impostazioni).
  String get urlVendita => switch (this) {
        Piattaforma.vinted => 'https://www.vinted.it/items/new',
        Piattaforma.subito => 'https://www.subito.it/',
        Piattaforma.wallapop => 'https://it.wallapop.com/',
        Piattaforma.ebay => 'https://www.ebay.it/sl/sell',
        Piattaforma.depop => 'https://www.depop.com/products/create/',
        Piattaforma.facebook => 'https://www.facebook.com/marketplace/create/item',
      };
}

Piattaforma? piattaformaDaNome(String? s) {
  for (final p in Piattaforma.values) {
    if (p.name == s) return p;
  }
  return null;
}

const condizioni = [
  'Nuovo con cartellino',
  'Nuovo senza cartellino',
  'Ottime condizioni',
  'Buone condizioni',
  'Discrete condizioni',
];

class Pubblicazione {
  final DateTime data;
  final double prezzo;
  final bool rimosso; // rimosso dopo la vendita altrove

  const Pubblicazione({required this.data, required this.prezzo, this.rimosso = false});

  Pubblicazione copyWith({DateTime? data, double? prezzo, bool? rimosso}) => Pubblicazione(
        data: data ?? this.data,
        prezzo: prezzo ?? this.prezzo,
        rimosso: rimosso ?? this.rimosso,
      );

  Map<String, dynamic> toJson() =>
      {'data': data.toIso8601String(), 'prezzo': prezzo, 'rimosso': rimosso};

  factory Pubblicazione.fromJson(Map<String, dynamic> j) => Pubblicazione(
        data: DateTime.parse(j['data'] as String),
        prezzo: (j['prezzo'] as num).toDouble(),
        rimosso: j['rimosso'] as bool? ?? false,
      );
}

class Articolo {
  final String id;
  final String tipo; // es. "Giacca in jeans"
  final String marca;
  final String taglia;
  final String colore;
  final String materiale;
  final String condizione;
  final String note; // descrizione libera
  final double prezzo;
  final double? costo; // quanto l'hai pagato (facoltativo)
  final List<String> foto; // percorsi locali
  final DateTime creato;
  final DateTime? ultimoRibasso;
  final Map<Piattaforma, Pubblicazione> pubblicazioni;
  final DateTime? vendutoIl;
  final double? prezzoVendita;
  final Piattaforma? vendutoSu;

  const Articolo({
    required this.id,
    required this.tipo,
    this.marca = '',
    this.taglia = '',
    this.colore = '',
    this.materiale = '',
    this.condizione = 'Ottime condizioni',
    this.note = '',
    required this.prezzo,
    this.costo,
    this.foto = const [],
    required this.creato,
    this.ultimoRibasso,
    this.pubblicazioni = const {},
    this.vendutoIl,
    this.prezzoVendita,
    this.vendutoSu,
  });

  bool get venduto => vendutoIl != null;

  /// Prima data in cui l'articolo è stato messo online (o creato, se mai pubblicato).
  DateTime get online {
    if (pubblicazioni.isEmpty) return creato;
    return pubblicazioni.values.map((p) => p.data).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Piattaforme da cui togliere l'annuncio dopo la vendita.
  List<Piattaforma> get daRimuovere => !venduto
      ? const []
      : pubblicazioni.entries
          .where((e) => e.key != vendutoSu && !e.value.rimosso)
          .map((e) => e.key)
          .toList();

  Articolo copyWith({
    String? tipo,
    String? marca,
    String? taglia,
    String? colore,
    String? materiale,
    String? condizione,
    String? note,
    double? prezzo,
    double? costo,
    bool azzeraCosto = false,
    List<String>? foto,
    DateTime? ultimoRibasso,
    Map<Piattaforma, Pubblicazione>? pubblicazioni,
    DateTime? vendutoIl,
    double? prezzoVendita,
    Piattaforma? vendutoSu,
    bool azzeraVendita = false,
  }) =>
      Articolo(
        id: id,
        tipo: tipo ?? this.tipo,
        marca: marca ?? this.marca,
        taglia: taglia ?? this.taglia,
        colore: colore ?? this.colore,
        materiale: materiale ?? this.materiale,
        condizione: condizione ?? this.condizione,
        note: note ?? this.note,
        prezzo: prezzo ?? this.prezzo,
        costo: azzeraCosto ? null : (costo ?? this.costo),
        foto: foto ?? this.foto,
        creato: creato,
        ultimoRibasso: ultimoRibasso ?? this.ultimoRibasso,
        pubblicazioni: pubblicazioni ?? this.pubblicazioni,
        vendutoIl: azzeraVendita ? null : (vendutoIl ?? this.vendutoIl),
        prezzoVendita: azzeraVendita ? null : (prezzoVendita ?? this.prezzoVendita),
        vendutoSu: azzeraVendita ? null : (vendutoSu ?? this.vendutoSu),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'marca': marca,
        'taglia': taglia,
        'colore': colore,
        'materiale': materiale,
        'condizione': condizione,
        'note': note,
        'prezzo': prezzo,
        'costo': costo,
        'foto': foto,
        'creato': creato.toIso8601String(),
        'ultimoRibasso': ultimoRibasso?.toIso8601String(),
        'pubblicazioni': {for (final e in pubblicazioni.entries) e.key.name: e.value.toJson()},
        'vendutoIl': vendutoIl?.toIso8601String(),
        'prezzoVendita': prezzoVendita,
        'vendutoSu': vendutoSu?.name,
      };

  factory Articolo.fromJson(Map<String, dynamic> j) {
    final pubs = <Piattaforma, Pubblicazione>{};
    final raw = (j['pubblicazioni'] as Map?) ?? const {};
    raw.forEach((k, v) {
      final p = piattaformaDaNome(k as String);
      if (p != null) pubs[p] = Pubblicazione.fromJson(Map<String, dynamic>.from(v as Map));
    });
    DateTime? d(String k) => j[k] == null ? null : DateTime.parse(j[k] as String);
    return Articolo(
      id: j['id'] as String,
      tipo: j['tipo'] as String? ?? '',
      marca: j['marca'] as String? ?? '',
      taglia: j['taglia'] as String? ?? '',
      colore: j['colore'] as String? ?? '',
      materiale: j['materiale'] as String? ?? '',
      condizione: j['condizione'] as String? ?? 'Ottime condizioni',
      note: j['note'] as String? ?? '',
      prezzo: (j['prezzo'] as num? ?? 0).toDouble(),
      costo: (j['costo'] as num?)?.toDouble(),
      foto: List<String>.from(j['foto'] as List? ?? const []),
      creato: DateTime.parse(j['creato'] as String),
      ultimoRibasso: d('ultimoRibasso'),
      pubblicazioni: pubs,
      vendutoIl: d('vendutoIl'),
      prezzoVendita: (j['prezzoVendita'] as num?)?.toDouble(),
      vendutoSu: piattaformaDaNome(j['vendutoSu'] as String?),
    );
  }
}

class Impostazioni {
  final Set<Piattaforma> attive;
  final int giorniFermo; // dopo quanti giorni un articolo è "fermo"
  final int percRibasso; // ribasso suggerito in %
  final bool spedizione; // menziona la spedizione nelle descrizioni
  final bool ritiroAMano;
  final String citta;
  final bool automazioni; // funzioni "versione 2"
  final Map<Piattaforma, String> urlPersonalizzati;

  const Impostazioni({
    this.attive = const {Piattaforma.vinted, Piattaforma.subito, Piattaforma.wallapop, Piattaforma.ebay},
    this.giorniFermo = 21,
    this.percRibasso = 10,
    this.spedizione = true,
    this.ritiroAMano = false,
    this.citta = '',
    this.automazioni = false,
    this.urlPersonalizzati = const {},
  });

  String urlPer(Piattaforma p) {
    final u = urlPersonalizzati[p]?.trim() ?? '';
    return u.isEmpty ? p.urlVendita : u;
  }

  Impostazioni copyWith({
    Set<Piattaforma>? attive,
    int? giorniFermo,
    int? percRibasso,
    bool? spedizione,
    bool? ritiroAMano,
    String? citta,
    bool? automazioni,
    Map<Piattaforma, String>? urlPersonalizzati,
  }) =>
      Impostazioni(
        attive: attive ?? this.attive,
        giorniFermo: giorniFermo ?? this.giorniFermo,
        percRibasso: percRibasso ?? this.percRibasso,
        spedizione: spedizione ?? this.spedizione,
        ritiroAMano: ritiroAMano ?? this.ritiroAMano,
        citta: citta ?? this.citta,
        automazioni: automazioni ?? this.automazioni,
        urlPersonalizzati: urlPersonalizzati ?? this.urlPersonalizzati,
      );

  Map<String, dynamic> toJson() => {
        'attive': attive.map((p) => p.name).toList(),
        'giorniFermo': giorniFermo,
        'percRibasso': percRibasso,
        'spedizione': spedizione,
        'ritiroAMano': ritiroAMano,
        'citta': citta,
        'automazioni': automazioni,
        'url': {for (final e in urlPersonalizzati.entries) e.key.name: e.value},
      };

  factory Impostazioni.fromJson(Map<String, dynamic> j) {
    final url = <Piattaforma, String>{};
    ((j['url'] as Map?) ?? const {}).forEach((k, v) {
      final p = piattaformaDaNome(k as String);
      if (p != null) url[p] = v as String;
    });
    final attive = <Piattaforma>{
      for (final s in (j['attive'] as List? ?? const []))
        if (piattaformaDaNome(s as String) != null) piattaformaDaNome(s)!,
    };
    return Impostazioni(
      attive: attive.isEmpty ? const Impostazioni().attive : attive,
      giorniFermo: j['giorniFermo'] as int? ?? 21,
      percRibasso: j['percRibasso'] as int? ?? 10,
      spedizione: j['spedizione'] as bool? ?? true,
      ritiroAMano: j['ritiroAMano'] as bool? ?? false,
      citta: j['citta'] as String? ?? '',
      automazioni: j['automazioni'] as bool? ?? false,
      urlPersonalizzati: url,
    );
  }
}
