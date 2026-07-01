class ConsensoPrivacy {
  final int? id;
  final String tipoSoggetto;
  final int? soggettoId;
  final String nominativo;
  final String codiceFiscale;
  final String email;
  final String telefono;
  final String finalita;
  final String baseGiuridica;
  final String versioneInformativa;
  final String canaleRaccolta;
  final String stato;
  final String dataConsenso;
  final String dataRevoca;
  final String dataScadenza;
  final String documentoRiferimento;
  final String note;
  final String createdAt;
  final String updatedAt;
  final bool soggettoMinorenne;
  final String consensoPrestatoDa;
  final String? genitoreTutoreNome;
  final String? genitoreTutoreCodiceFiscale;
  final String? genitoreTutoreQualifica;
  final String dataFineConservazione;
  final String motivoRetention;
  final bool retentionBloccata;
  final String noteRetention;

  const ConsensoPrivacy({
    this.id,
    required this.tipoSoggetto,
    this.soggettoId,
    required this.nominativo,
    required this.codiceFiscale,
    required this.email,
    required this.telefono,
    required this.finalita,
    required this.baseGiuridica,
    required this.versioneInformativa,
    required this.canaleRaccolta,
    required this.stato,
    required this.dataConsenso,
    required this.dataRevoca,
    required this.dataScadenza,
    required this.documentoRiferimento,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.soggettoMinorenne = false,
    this.consensoPrestatoDa = 'discente',
    this.genitoreTutoreNome,
    this.genitoreTutoreCodiceFiscale,
    this.genitoreTutoreQualifica,
    this.dataFineConservazione = '',
    this.motivoRetention = '',
    this.retentionBloccata = false,
    this.noteRetention = '',
  });

  factory ConsensoPrivacy.fromMap(Map<String, dynamic> map) {
    return ConsensoPrivacy(
      id: map['id'] as int?,
      tipoSoggetto: map['tipo_soggetto'] as String? ?? 'Altro',
      soggettoId: map['soggetto_id'] as int?,
      nominativo: map['nominativo'] as String? ?? '',
      codiceFiscale: map['codice_fiscale'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      finalita: map['finalita'] as String? ?? '',
      baseGiuridica: map['base_giuridica'] as String? ?? '',
      versioneInformativa: map['versione_informativa'] as String? ?? '',
      canaleRaccolta: map['canale_raccolta'] as String? ?? '',
      stato: map['stato'] as String? ?? 'ATTIVO',
      dataConsenso: map['data_consenso'] as String? ?? '',
      dataRevoca: map['data_revoca'] as String? ?? '',
      dataScadenza: map['data_scadenza'] as String? ?? '',
      documentoRiferimento: map['documento_riferimento'] as String? ?? '',
      note: map['note'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
      soggettoMinorenne: (map['soggetto_minorenne'] as int? ?? 0) == 1,
      consensoPrestatoDa: map['consenso_prestato_da'] as String? ?? 'discente',
      genitoreTutoreNome: map['genitore_tutore_nome'] as String?,
      genitoreTutoreCodiceFiscale:
          map['genitore_tutore_codice_fiscale'] as String?,
      genitoreTutoreQualifica: map['genitore_tutore_qualifica'] as String?,
      dataFineConservazione: map['data_fine_conservazione'] as String? ?? '',
      motivoRetention: map['motivo_retention'] as String? ?? '',
      retentionBloccata: (map['retention_bloccata'] as int? ?? 0) == 1,
      noteRetention: map['note_retention'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tipo_soggetto': tipoSoggetto,
      'soggetto_id': soggettoId,
      'nominativo': nominativo,
      'codice_fiscale': codiceFiscale,
      'email': email,
      'telefono': telefono,
      'finalita': finalita,
      'base_giuridica': baseGiuridica,
      'versione_informativa': versioneInformativa,
      'canale_raccolta': canaleRaccolta,
      'stato': stato,
      'data_consenso': dataConsenso,
      'data_revoca': dataRevoca,
      'data_scadenza': dataScadenza,
      'documento_riferimento': documentoRiferimento,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'soggetto_minorenne': soggettoMinorenne ? 1 : 0,
      'consenso_prestato_da': consensoPrestatoDa,
      'genitore_tutore_nome': genitoreTutoreNome,
      'genitore_tutore_codice_fiscale': genitoreTutoreCodiceFiscale,
      'genitore_tutore_qualifica': genitoreTutoreQualifica,
      'data_fine_conservazione': dataFineConservazione,
      'motivo_retention': motivoRetention,
      'retention_bloccata': retentionBloccata ? 1 : 0,
      'note_retention': noteRetention,
    };
  }

  ConsensoPrivacy copyWith({
    int? id,
    String? tipoSoggetto,
    int? soggettoId,
    String? nominativo,
    String? codiceFiscale,
    String? email,
    String? telefono,
    String? finalita,
    String? baseGiuridica,
    String? versioneInformativa,
    String? canaleRaccolta,
    String? stato,
    String? dataConsenso,
    String? dataRevoca,
    String? dataScadenza,
    String? documentoRiferimento,
    String? note,
    String? createdAt,
    String? updatedAt,
    bool? soggettoMinorenne,
    String? consensoPrestatoDa,
    String? genitoreTutoreNome,
    String? genitoreTutoreCodiceFiscale,
    String? genitoreTutoreQualifica,
    String? dataFineConservazione,
    String? motivoRetention,
    bool? retentionBloccata,
    String? noteRetention,
  }) {
    return ConsensoPrivacy(
      id: id ?? this.id,
      tipoSoggetto: tipoSoggetto ?? this.tipoSoggetto,
      soggettoId: soggettoId ?? this.soggettoId,
      nominativo: nominativo ?? this.nominativo,
      codiceFiscale: codiceFiscale ?? this.codiceFiscale,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      finalita: finalita ?? this.finalita,
      baseGiuridica: baseGiuridica ?? this.baseGiuridica,
      versioneInformativa: versioneInformativa ?? this.versioneInformativa,
      canaleRaccolta: canaleRaccolta ?? this.canaleRaccolta,
      stato: stato ?? this.stato,
      dataConsenso: dataConsenso ?? this.dataConsenso,
      dataRevoca: dataRevoca ?? this.dataRevoca,
      dataScadenza: dataScadenza ?? this.dataScadenza,
      documentoRiferimento: documentoRiferimento ?? this.documentoRiferimento,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      soggettoMinorenne: soggettoMinorenne ?? this.soggettoMinorenne,
      consensoPrestatoDa: consensoPrestatoDa ?? this.consensoPrestatoDa,
      genitoreTutoreNome: genitoreTutoreNome ?? this.genitoreTutoreNome,
      genitoreTutoreCodiceFiscale:
          genitoreTutoreCodiceFiscale ?? this.genitoreTutoreCodiceFiscale,
      genitoreTutoreQualifica:
          genitoreTutoreQualifica ?? this.genitoreTutoreQualifica,
      dataFineConservazione:
          dataFineConservazione ?? this.dataFineConservazione,
      motivoRetention: motivoRetention ?? this.motivoRetention,
      retentionBloccata: retentionBloccata ?? this.retentionBloccata,
      noteRetention: noteRetention ?? this.noteRetention,
    );
  }
}
