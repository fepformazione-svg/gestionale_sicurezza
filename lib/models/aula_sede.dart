class AulaSede {
  final int? id;
  final String codice;
  final String denominazione;
  final String tipo;
  final String indirizzo;
  final String comune;
  final int? capienza;
  final String note;
  final bool attiva;
  final String? createdAt;
  final String? updatedAt;

  AulaSede({
    this.id,
    this.codice = '',
    required this.denominazione,
    required this.tipo,
    required this.indirizzo,
    required this.comune,
    this.capienza,
    required this.note,
    required this.attiva,
    this.createdAt,
    this.updatedAt,
  });

  factory AulaSede.fromMap(Map<String, dynamic> map) {
    return AulaSede(
      id: map['id'] as int?,
      codice: map['codice'] as String? ?? '',
      denominazione: map['denominazione'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'Aula',
      indirizzo: map['indirizzo'] as String? ?? '',
      comune: map['comune'] as String? ?? '',
      capienza: map['capienza'] as int?,
      note: map['note'] as String? ?? '',
      attiva: (map['attiva'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codice': codice,
      'denominazione': denominazione,
      'tipo': tipo,
      'indirizzo': indirizzo,
      'comune': comune,
      'capienza': capienza,
      'note': note,
      'attiva': attiva ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  AulaSede copyWith({
    int? id,
    String? codice,
    String? denominazione,
    String? tipo,
    String? indirizzo,
    String? comune,
    int? capienza,
    String? note,
    bool? attiva,
    String? createdAt,
    String? updatedAt,
  }) {
    return AulaSede(
      id: id ?? this.id,
      codice: codice ?? this.codice,
      denominazione: denominazione ?? this.denominazione,
      tipo: tipo ?? this.tipo,
      indirizzo: indirizzo ?? this.indirizzo,
      comune: comune ?? this.comune,
      capienza: capienza ?? this.capienza,
      note: note ?? this.note,
      attiva: attiva ?? this.attiva,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
