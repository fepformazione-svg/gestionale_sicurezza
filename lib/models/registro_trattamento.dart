class RegistroTrattamento {
  final int? id;
  final String nomeTrattamento;
  final String? finalita;
  final String? baseGiuridica;
  final String? categorieInteressati;
  final String? categorieDati;
  final String? categorieDestinatari;
  final String? trasferimentiExtraUe;
  final String? terminiCancellazione;
  final String? misureSicurezza;
  final String? responsabileInterno;
  final String? note;
  final bool attivo;
  final String createdAt;
  final String updatedAt;

  RegistroTrattamento({
    this.id,
    required this.nomeTrattamento,
    this.finalita,
    this.baseGiuridica,
    this.categorieInteressati,
    this.categorieDati,
    this.categorieDestinatari,
    this.trasferimentiExtraUe,
    this.terminiCancellazione,
    this.misureSicurezza,
    this.responsabileInterno,
    this.note,
    this.attivo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RegistroTrattamento.fromMap(Map<String, dynamic> map) {
    return RegistroTrattamento(
      id: map['id'] as int?,
      nomeTrattamento: map['nome_trattamento'] as String,
      finalita: map['finalita'] as String?,
      baseGiuridica: map['base_giuridica'] as String?,
      categorieInteressati: map['categorie_interessati'] as String?,
      categorieDati: map['categorie_dati'] as String?,
      categorieDestinatari: map['categorie_destinatari'] as String?,
      trasferimentiExtraUe: map['trasferimenti_extra_ue'] as String?,
      terminiCancellazione: map['termini_cancellazione'] as String?,
      misureSicurezza: map['misure_sicurezza'] as String?,
      responsabileInterno: map['responsabile_interno'] as String?,
      note: map['note'] as String?,
      attivo: (map['attivo'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_trattamento': nomeTrattamento,
      'finalita': finalita,
      'base_giuridica': baseGiuridica,
      'categorie_interessati': categorieInteressati,
      'categorie_dati': categorieDati,
      'categorie_destinatari': categorieDestinatari,
      'trasferimenti_extra_ue': trasferimentiExtraUe,
      'termini_cancellazione': terminiCancellazione,
      'misure_sicurezza': misureSicurezza,
      'responsabile_interno': responsabileInterno,
      'note': note,
      'attivo': attivo ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  RegistroTrattamento copyWith({
    int? id,
    String? nomeTrattamento,
    String? finalita,
    String? baseGiuridica,
    String? categorieInteressati,
    String? categorieDati,
    String? categorieDestinatari,
    String? trasferimentiExtraUe,
    String? terminiCancellazione,
    String? misureSicurezza,
    String? responsabileInterno,
    String? note,
    bool? attivo,
    String? createdAt,
    String? updatedAt,
  }) {
    return RegistroTrattamento(
      id: id ?? this.id,
      nomeTrattamento: nomeTrattamento ?? this.nomeTrattamento,
      finalita: finalita ?? this.finalita,
      baseGiuridica: baseGiuridica ?? this.baseGiuridica,
      categorieInteressati: categorieInteressati ?? this.categorieInteressati,
      categorieDati: categorieDati ?? this.categorieDati,
      categorieDestinatari: categorieDestinatari ?? this.categorieDestinatari,
      trasferimentiExtraUe: trasferimentiExtraUe ?? this.trasferimentiExtraUe,
      terminiCancellazione: terminiCancellazione ?? this.terminiCancellazione,
      misureSicurezza: misureSicurezza ?? this.misureSicurezza,
      responsabileInterno: responsabileInterno ?? this.responsabileInterno,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
