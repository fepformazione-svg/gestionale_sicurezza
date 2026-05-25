class Impresa {
  final int? id;

  final String intestazione;

  final String? partitaIva;

  final String? referente;

  Impresa({
    this.id,
    required this.intestazione,
    this.partitaIva,
    this.referente,
  });

  // =========================================================
  // FROM MAP
  // =========================================================

  factory Impresa.fromMap(
    Map<String, dynamic> map,
  ) {
    return Impresa(
      id: map['id'] as int?,

      intestazione:
          (map['intestazione'] ?? '')
              .toString(),

      partitaIva:
          map['partita_iva']
              ?.toString(),

      referente:
          map['referente']
              ?.toString(),
    );
  }

  // =========================================================
  // TO MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'intestazione':
          intestazione,

      'partita_iva':
          partitaIva,

      'referente':
          referente,
    };
  }

  // =========================================================
  // COMPATIBILITÀ VECCHIO CODICE
  // =========================================================

  String get nome => intestazione;
}