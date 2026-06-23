class RegistroPresenza {
  final int? id;
  final int prenotazioneId;
  final int? discenteId;
  final String? dataLezione;
  final String? oraInizio;
  final String? oraFine;
  final bool presente;
  final String? firmaDiscentePath;
  final String? firmaDocentePath;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  RegistroPresenza({
    this.id,
    required this.prenotazioneId,
    this.discenteId,
    this.dataLezione,
    this.oraInizio,
    this.oraFine,
    this.presente = false,
    this.firmaDiscentePath,
    this.firmaDocentePath,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory RegistroPresenza.fromMap(Map<String, dynamic> map) {
    return RegistroPresenza(
      id: map['id'] as int?,
      prenotazioneId: map['prenotazione_id'] as int,
      discenteId: map['discente_id'] as int?,
      dataLezione: map['data_lezione'] as String?,
      oraInizio: map['ora_inizio'] as String?,
      oraFine: map['ora_fine'] as String?,
      presente: (map['presente'] ?? 0) == 1,
      firmaDiscentePath: map['firma_discente_path'] as String?,
      firmaDocentePath: map['firma_docente_path'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prenotazione_id': prenotazioneId,
      'discente_id': discenteId,
      'data_lezione': dataLezione,
      'ora_inizio': oraInizio,
      'ora_fine': oraFine,
      'presente': presente ? 1 : 0,
      'firma_discente_path': firmaDiscentePath,
      'firma_docente_path': firmaDocentePath,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  RegistroPresenza copyWith({
    int? id,
    int? prenotazioneId,
    int? discenteId,
    String? dataLezione,
    String? oraInizio,
    String? oraFine,
    bool? presente,
    String? firmaDiscentePath,
    String? firmaDocentePath,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return RegistroPresenza(
      id: id ?? this.id,
      prenotazioneId: prenotazioneId ?? this.prenotazioneId,
      discenteId: discenteId ?? this.discenteId,
      dataLezione: dataLezione ?? this.dataLezione,
      oraInizio: oraInizio ?? this.oraInizio,
      oraFine: oraFine ?? this.oraFine,
      presente: presente ?? this.presente,
      firmaDiscentePath: firmaDiscentePath ?? this.firmaDiscentePath,
      firmaDocentePath: firmaDocentePath ?? this.firmaDocentePath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
