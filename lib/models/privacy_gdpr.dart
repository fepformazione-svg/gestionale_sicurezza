class PrivacyGdpr {
  final int? id;
  final String titolo;
  final String? titolareTrattamento;
  final String? referentePrivacy;
  final String? baseGiuridica;
  final String? finalitaTrattamento;
  final String? categorieDati;
  final String? periodoConservazione;
  final String? misureSicurezza;
  final String? note;
  final bool attivo;
  final String? createdAt;
  final String? updatedAt;

  const PrivacyGdpr({
    this.id,
    required this.titolo,
    this.titolareTrattamento,
    this.referentePrivacy,
    this.baseGiuridica,
    this.finalitaTrattamento,
    this.categorieDati,
    this.periodoConservazione,
    this.misureSicurezza,
    this.note,
    this.attivo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PrivacyGdpr.fromMap(Map<String, dynamic> map) {
    return PrivacyGdpr(
      id: map['id'] as int?,
      titolo: map['titolo'] as String? ?? '',
      titolareTrattamento: map['titolare_trattamento'] as String?,
      referentePrivacy: map['referente_privacy'] as String?,
      baseGiuridica: map['base_giuridica'] as String?,
      finalitaTrattamento: map['finalita_trattamento'] as String?,
      categorieDati: map['categorie_dati'] as String?,
      periodoConservazione: map['periodo_conservazione'] as String?,
      misureSicurezza: map['misure_sicurezza'] as String?,
      note: map['note'] as String?,
      attivo: (map['attivo'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'titolare_trattamento': titolareTrattamento,
      'referente_privacy': referentePrivacy,
      'base_giuridica': baseGiuridica,
      'finalita_trattamento': finalitaTrattamento,
      'categorie_dati': categorieDati,
      'periodo_conservazione': periodoConservazione,
      'misure_sicurezza': misureSicurezza,
      'note': note,
      'attivo': attivo ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  PrivacyGdpr copyWith({
    int? id,
    String? titolo,
    String? titolareTrattamento,
    String? referentePrivacy,
    String? baseGiuridica,
    String? finalitaTrattamento,
    String? categorieDati,
    String? periodoConservazione,
    String? misureSicurezza,
    String? note,
    bool? attivo,
    String? createdAt,
    String? updatedAt,
  }) {
    return PrivacyGdpr(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      titolareTrattamento: titolareTrattamento ?? this.titolareTrattamento,
      referentePrivacy: referentePrivacy ?? this.referentePrivacy,
      baseGiuridica: baseGiuridica ?? this.baseGiuridica,
      finalitaTrattamento: finalitaTrattamento ?? this.finalitaTrattamento,
      categorieDati: categorieDati ?? this.categorieDati,
      periodoConservazione: periodoConservazione ?? this.periodoConservazione,
      misureSicurezza: misureSicurezza ?? this.misureSicurezza,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
