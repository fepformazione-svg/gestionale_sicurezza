class UtenteApp {
  final int? id;
  final String nome;
  final String cognome;
  final String? email;
  final String username;
  final String? passwordHash;
  final int? ruoloId;
  final int attivo;
  final String? ultimoAccesso;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  const UtenteApp({
    this.id,
    required this.nome,
    required this.cognome,
    this.email,
    required this.username,
    this.passwordHash,
    this.ruoloId,
    this.attivo = 1,
    this.ultimoAccesso,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory UtenteApp.fromMap(Map<String, dynamic> map) {
    return UtenteApp(
      id: map['id'] as int?,
      nome: map['nome'] as String? ?? '',
      cognome: map['cognome'] as String? ?? '',
      email: map['email'] as String?,
      username: map['username'] as String? ?? '',
      passwordHash: map['password_hash'] as String?,
      ruoloId: map['ruolo_id'] as int?,
      attivo: map['attivo'] as int? ?? 1,
      ultimoAccesso: map['ultimo_accesso'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'username': username,
      'password_hash': passwordHash,
      'ruolo_id': ruoloId,
      'attivo': attivo,
      'ultimo_accesso': ultimoAccesso,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UtenteApp copyWith({
    int? id,
    String? nome,
    String? cognome,
    String? email,
    String? username,
    String? passwordHash,
    int? ruoloId,
    int? attivo,
    String? ultimoAccesso,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return UtenteApp(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      email: email ?? this.email,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      ruoloId: ruoloId ?? this.ruoloId,
      attivo: attivo ?? this.attivo,
      ultimoAccesso: ultimoAccesso ?? this.ultimoAccesso,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAttivo => attivo == 1;

  String get nomeCompleto {
    final completo = '$cognome $nome'.trim();
    return completo.isEmpty ? username : completo;
  }
}
