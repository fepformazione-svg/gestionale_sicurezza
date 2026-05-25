class Discente {
  final int? id;

  final String nome;
  final String cognome;

  final String? luogoNascita;
  final String? dataNascita;

  final String? codiceFiscale;

  final int? impresaId;
  final String? nomeImpresa;

  final int visitaMedicaSvolta;
  final String? dataVisitaMedica;
  final String? scadenzaVisitaMedica;

  Discente({
    this.id,
    required this.nome,
    required this.cognome,
    this.luogoNascita,
    this.dataNascita,
    this.codiceFiscale,
    this.impresaId,
    this.nomeImpresa,
    this.visitaMedicaSvolta = 0,
    this.dataVisitaMedica,
    this.scadenzaVisitaMedica,
  });

  // =========================================================
  // NOMINATIVI
  // =========================================================

  String get nomeCompleto => '$cognome $nome'.trim();

  String get nominativoCompleto => '$cognome $nome'.trim();

  // =========================================================
  // FROM MAP
  // =========================================================

  factory Discente.fromMap(Map<String, dynamic> map) {
    return Discente(
      id: map['id'] as int?,

      nome: (map['nome'] ?? '').toString(),

      cognome: (map['cognome'] ?? '').toString(),

      luogoNascita: map['luogo_nascita']?.toString(),

      dataNascita: map['data_nascita']?.toString(),

      codiceFiscale: map['codice_fiscale']?.toString(),

      impresaId: map['impresa_id'] as int?,

      nomeImpresa: map['nome_impresa']?.toString(),

      visitaMedicaSvolta:
          int.tryParse(
            (map['visita_medica_svolta'] ?? 0).toString(),
          ) ??
          0,

      dataVisitaMedica:
          map['data_visita_medica']?.toString(),

      scadenzaVisitaMedica:
          map['scadenza_visita_medica']?.toString(),
    );
  }

  // =========================================================
  // TO MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cognome': cognome,
      'luogo_nascita': luogoNascita,
      'data_nascita': dataNascita,
      'codice_fiscale': codiceFiscale,
      'impresa_id': impresaId,
      'visita_medica_svolta': visitaMedicaSvolta,
      'data_visita_medica': dataVisitaMedica,
      'scadenza_visita_medica': scadenzaVisitaMedica,
    };
  }
}