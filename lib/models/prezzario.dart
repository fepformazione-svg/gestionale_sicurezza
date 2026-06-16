class Prezzario {
  final int? id;
  final int impresaId;
  final int corsoId;
  final double prezzo;
  final String note;
  final String? createdAt;
  final String? updatedAt;

  // Campi letti dalla JOIN, utili per mostrare la tabella Prezzario
  final String? impresa;
  final String? corso;

  Prezzario({
    this.id,
    required this.impresaId,
    required this.corsoId,
    required this.prezzo,
    this.note = '',
    this.createdAt,
    this.updatedAt,
    this.impresa,
    this.corso,
  });

  factory Prezzario.fromMap(Map<String, dynamic> map) {
    return Prezzario(
      id: map['id'] as int?,
      impresaId: map['impresa_id'] as int,
      corsoId: map['corso_id'] as int,
      prezzo: (map['prezzo'] as num?)?.toDouble() ?? 0,
      note: (map['note'] ?? '').toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      impresa: map['impresa']?.toString(),
      corso: map['corso']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'impresa_id': impresaId,
      'corso_id': corsoId,
      'prezzo': prezzo,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'impresa_id': impresaId,
      'corso_id': corsoId,
      'prezzo': prezzo,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'impresa_id': impresaId,
      'corso_id': corsoId,
      'prezzo': prezzo,
      'note': note,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Prezzario copyWith({
    int? id,
    int? impresaId,
    int? corsoId,
    double? prezzo,
    String? note,
    String? createdAt,
    String? updatedAt,
    String? impresa,
    String? corso,
  }) {
    return Prezzario(
      id: id ?? this.id,
      impresaId: impresaId ?? this.impresaId,
      corsoId: corsoId ?? this.corsoId,
      prezzo: prezzo ?? this.prezzo,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      impresa: impresa ?? this.impresa,
      corso: corso ?? this.corso,
    );
  }
}
