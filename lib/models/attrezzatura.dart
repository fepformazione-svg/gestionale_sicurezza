class Attrezzatura {
  final int? id;
  final String denominazione;
  final String categoria;
  final String codice;
  final String descrizione;
  final int quantita;
  final String unitaMisura;
  final bool attiva;
  final String note;
  final String? createdAt;
  final String? updatedAt;

  Attrezzatura({
    this.id,
    required this.denominazione,
    required this.categoria,
    required this.codice,
    required this.descrizione,
    required this.quantita,
    required this.unitaMisura,
    required this.attiva,
    required this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory Attrezzatura.fromMap(Map<String, dynamic> map) {
    return Attrezzatura(
      id: map['id'] as int?,
      denominazione: map['denominazione'] as String? ?? '',
      categoria: map['categoria'] as String? ?? 'Generica',
      codice: map['codice'] as String? ?? '',
      descrizione: map['descrizione'] as String? ?? '',
      quantita: map['quantita'] as int? ?? 1,
      unitaMisura: map['unita_misura'] as String? ?? 'pz',
      attiva: (map['attiva'] as int? ?? 1) == 1,
      note: map['note'] as String? ?? '',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'denominazione': denominazione,
      'categoria': categoria,
      'codice': codice,
      'descrizione': descrizione,
      'quantita': quantita,
      'unita_misura': unitaMisura,
      'attiva': attiva ? 1 : 0,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Attrezzatura copyWith({
    int? id,
    String? denominazione,
    String? categoria,
    String? codice,
    String? descrizione,
    int? quantita,
    String? unitaMisura,
    bool? attiva,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Attrezzatura(
      id: id ?? this.id,
      denominazione: denominazione ?? this.denominazione,
      categoria: categoria ?? this.categoria,
      codice: codice ?? this.codice,
      descrizione: descrizione ?? this.descrizione,
      quantita: quantita ?? this.quantita,
      unitaMisura: unitaMisura ?? this.unitaMisura,
      attiva: attiva ?? this.attiva,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
