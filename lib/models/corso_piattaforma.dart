class CorsoPiattaforma {
  final int? id;
  final int corsoId;
  final String piattaforma;
  final String codice;
  final String? note;
  final bool attivo;

  const CorsoPiattaforma({
    this.id,
    required this.corsoId,
    required this.piattaforma,
    required this.codice,
    this.note,
    this.attivo = true,
  });

  factory CorsoPiattaforma.fromMap(Map<String, dynamic> map) {
    return CorsoPiattaforma(
      id: int.tryParse((map['id'] ?? '').toString()),
      corsoId: int.tryParse((map['corso_id'] ?? 0).toString()) ?? 0,
      piattaforma: (map['piattaforma'] ?? '').toString(),
      codice: (map['codice'] ?? '').toString(),
      note: map['note']?.toString(),
      attivo: int.tryParse((map['attivo'] ?? 1).toString()) != 0,
    );
  }

  Map<String, dynamic> toMap() {
    final notePulite = note?.trim();

    return {
      'corso_id': corsoId,
      'piattaforma': piattaforma.trim(),
      'codice': codice.trim(),
      'note': notePulite == null || notePulite.isEmpty ? null : notePulite,
      'attivo': attivo ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  CorsoPiattaforma copyWith({
    int? id,
    int? corsoId,
    String? piattaforma,
    String? codice,
    String? note,
    bool? attivo,
  }) {
    return CorsoPiattaforma(
      id: id ?? this.id,
      corsoId: corsoId ?? this.corsoId,
      piattaforma: piattaforma ?? this.piattaforma,
      codice: codice ?? this.codice,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
    );
  }
}
