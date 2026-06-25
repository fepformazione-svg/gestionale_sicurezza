class RegistroTrattamento {
  final int? id;
  final String nomeTrattamento;
  final String finalita;
  final String baseGiuridica;
  final String categorieDati;
  final String categorieInteressati;
  final String destinatari;
  final String trasferimentoExtraUe;
  final String tempiConservazione;
  final String misureSicurezza;
  final String responsabileInterno;
  final String note;
  final bool attivo;
  final String? createdAt;
  final String? updatedAt;

  RegistroTrattamento({
    this.id,
    required this.nomeTrattamento,
    required this.finalita,
    required this.baseGiuridica,
    required this.categorieDati,
    required this.categorieInteressati,
    required this.destinatari,
    required this.trasferimentoExtraUe,
    required this.tempiConservazione,
    required this.misureSicurezza,
    required this.responsabileInterno,
    required this.note,
    this.attivo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory RegistroTrattamento.fromMap(Map<String, dynamic> map) {
    return RegistroTrattamento(
      id: map['id'] as int?,
      nomeTrattamento: map['nome_trattamento']?.toString() ?? '',
      finalita: map['finalita']?.toString() ?? '',
      baseGiuridica: map['base_giuridica']?.toString() ?? '',
      categorieDati: map['categorie_dati']?.toString() ?? '',
      categorieInteressati: map['categorie_interessati']?.toString() ?? '',
      destinatari: map['destinatari']?.toString() ?? '',
      trasferimentoExtraUe: map['trasferimento_extra_ue']?.toString() ?? '',
      tempiConservazione: map['tempi_conservazione']?.toString() ?? '',
      misureSicurezza: map['misure_sicurezza']?.toString() ?? '',
      responsabileInterno: map['responsabile_interno']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      attivo: map['attivo'] == null ? true : map['attivo'] == 1,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_trattamento': nomeTrattamento,
      'finalita': finalita,
      'base_giuridica': baseGiuridica,
      'categorie_dati': categorieDati,
      'categorie_interessati': categorieInteressati,
      'destinatari': destinatari,
      'trasferimento_extra_ue': trasferimentoExtraUe,
      'tempi_conservazione': tempiConservazione,
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
    String? categorieDati,
    String? categorieInteressati,
    String? destinatari,
    String? trasferimentoExtraUe,
    String? tempiConservazione,
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
      categorieDati: categorieDati ?? this.categorieDati,
      categorieInteressati:
          categorieInteressati ?? this.categorieInteressati,
      destinatari: destinatari ?? this.destinatari,
      trasferimentoExtraUe:
          trasferimentoExtraUe ?? this.trasferimentoExtraUe,
      tempiConservazione:
          tempiConservazione ?? this.tempiConservazione,
      misureSicurezza: misureSicurezza ?? this.misureSicurezza,
      responsabileInterno:
          responsabileInterno ?? this.responsabileInterno,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
