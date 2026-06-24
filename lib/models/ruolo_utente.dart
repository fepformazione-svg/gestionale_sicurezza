class RuoloUtente {
  final int? id;
  final String nome;
  final String? descrizione;
  final int attivo;
  final String? createdAt;
  final String? updatedAt;

  const RuoloUtente({
    this.id,
    required this.nome,
    this.descrizione,
    this.attivo = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory RuoloUtente.fromMap(Map<String, dynamic> map) {
    return RuoloUtente(
      id: map['id'] as int?,
      nome: map['nome'] as String? ?? '',
      descrizione: map['descrizione'] as String?,
      attivo: map['attivo'] as int? ?? 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descrizione': descrizione,
      'attivo': attivo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  RuoloUtente copyWith({
    int? id,
    String? nome,
    String? descrizione,
    int? attivo,
    String? createdAt,
    String? updatedAt,
  }) {
    return RuoloUtente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      attivo: attivo ?? this.attivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAttivo => attivo == 1;
}
