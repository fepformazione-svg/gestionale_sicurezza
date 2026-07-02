class Discente {
  final int? id;

  final String nome;
  final String cognome;

  final String? luogoNascita;
  final String? dataNascita;

  final String? sesso;
  final String? codiceCatastaleNascita;
  final String? codiceFiscale;

  final int? impresaId;
  final String? nomeImpresa;

  final int visitaMedicaSvolta;
  final String? dataVisitaMedica;
  final String? scadenzaVisitaMedica;

  final int informativaPrivacyFirmata;
  final String? dataFirmaInformativaPrivacy;
  final String? documentoPrivacyDiscentePath;
  final String? notePrivacyDiscente;

  Discente({
    this.id,
    required this.nome,
    required this.cognome,
    this.luogoNascita,
    this.dataNascita,
    this.sesso,
    this.codiceCatastaleNascita,
    this.codiceFiscale,
    this.impresaId,
    this.nomeImpresa,
    this.visitaMedicaSvolta = 0,
    this.dataVisitaMedica,
    this.scadenzaVisitaMedica,
    this.informativaPrivacyFirmata = 0,
    this.dataFirmaInformativaPrivacy,
    this.documentoPrivacyDiscentePath,
    this.notePrivacyDiscente,
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

      sesso: map['sesso']?.toString(),

      codiceCatastaleNascita: map['codice_catastale_nascita']?.toString(),

      codiceFiscale: map['codice_fiscale']?.toString(),

      impresaId: map['impresa_id'] as int?,

      nomeImpresa: map['nome_impresa']?.toString(),

      visitaMedicaSvolta:
          int.tryParse((map['visita_medica_svolta'] ?? 0).toString()) ?? 0,

      dataVisitaMedica: map['data_visita_medica']?.toString(),

      scadenzaVisitaMedica: map['scadenza_visita_medica']?.toString(),

      informativaPrivacyFirmata:
          int.tryParse((map['informativa_privacy_firmata'] ?? 0).toString()) ??
          0,

      dataFirmaInformativaPrivacy: map['data_firma_informativa_privacy']
          ?.toString(),

      documentoPrivacyDiscentePath: map['documento_privacy_discente_path']
          ?.toString(),

      notePrivacyDiscente: map['note_privacy_discente']?.toString(),
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
      'sesso': sesso,
      'codice_catastale_nascita': codiceCatastaleNascita,
      'codice_fiscale': codiceFiscale,
      'impresa_id': impresaId,
      'visita_medica_svolta': visitaMedicaSvolta,
      'data_visita_medica': dataVisitaMedica,
      'scadenza_visita_medica': scadenzaVisitaMedica,
      'informativa_privacy_firmata': informativaPrivacyFirmata,
      'data_firma_informativa_privacy': dataFirmaInformativaPrivacy,
      'documento_privacy_discente_path': documentoPrivacyDiscentePath,
      'note_privacy_discente': notePrivacyDiscente,
    };
  }
}
