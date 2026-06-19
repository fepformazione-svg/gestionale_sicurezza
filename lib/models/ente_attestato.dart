class EnteAttestato {
  final int? id;
  final String denominazione;
  final String tipo;
  final String? codiceAccreditamento;
  final String? referente;
  final String? telefono;
  final String? email;
  final String? pec;
  final String? indirizzo;
  final String? comune;
  final String? note;
  final int attivo;
  final String? createdAt;
  final String? updatedAt;

  const EnteAttestato({
    this.id,
    required this.denominazione,
    required this.tipo,
    this.codiceAccreditamento,
    this.referente,
    this.telefono,
    this.email,
    this.pec,
    this.indirizzo,
    this.comune,
    this.note,
    this.attivo = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory EnteAttestato.fromMap(Map<String, dynamic> map) {
    return EnteAttestato(
      id: map['id'] as int?,
      denominazione: map['denominazione'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'Ente',
      codiceAccreditamento: map['codice_accreditamento'] as String?,
      referente: map['referente'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
      pec: map['pec'] as String?,
      indirizzo: map['indirizzo'] as String?,
      comune: map['comune'] as String?,
      note: map['note'] as String?,
      attivo: map['attivo'] as int? ?? 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'denominazione': denominazione.trim(),
      'tipo': tipo.trim().isEmpty ? 'Ente' : tipo.trim(),
      'codice_accreditamento': codiceAccreditamento?.trim(),
      'referente': referente?.trim(),
      'telefono': telefono?.trim(),
      'email': email?.trim(),
      'pec': pec?.trim(),
      'indirizzo': indirizzo?.trim(),
      'comune': comune?.trim(),
      'note': note?.trim(),
      'attivo': attivo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  EnteAttestato copyWith({
    int? id,
    String? denominazione,
    String? tipo,
    String? codiceAccreditamento,
    String? referente,
    String? telefono,
    String? email,
    String? pec,
    String? indirizzo,
    String? comune,
    String? note,
    int? attivo,
    String? createdAt,
    String? updatedAt,
  }) {
    return EnteAttestato(
      id: id ?? this.id,
      denominazione: denominazione ?? this.denominazione,
      tipo: tipo ?? this.tipo,
      codiceAccreditamento: codiceAccreditamento ?? this.codiceAccreditamento,
      referente: referente ?? this.referente,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      pec: pec ?? this.pec,
      indirizzo: indirizzo ?? this.indirizzo,
      comune: comune ?? this.comune,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
