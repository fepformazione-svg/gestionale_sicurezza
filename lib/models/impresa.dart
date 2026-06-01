class Impresa {
  final int? id;

  final String intestazione;
  final String? partitaIva;
  final String? codiceFiscale;
  final String? indirizzo;
  final String? telefono;
  final String? referente;

  Impresa({
    this.id,
    required this.intestazione,
    this.partitaIva,
    this.codiceFiscale,
    this.indirizzo,
    this.telefono,
    this.referente,
  });

  factory Impresa.fromMap(Map<String, dynamic> map) {
    return Impresa(
      id: map['id'] as int?,
      intestazione: (map['intestazione'] ?? '').toString(),
      partitaIva: map['partita_iva']?.toString(),
      codiceFiscale: map['codice_fiscale']?.toString(),
      indirizzo: map['indirizzo']?.toString(),
      telefono: map['telefono']?.toString(),
      referente: map['referente']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'intestazione': intestazione,
      'partita_iva': partitaIva,
      'codice_fiscale': codiceFiscale,
      'indirizzo': indirizzo,
      'telefono': telefono,
      'referente': referente,
    };
  }

  String get nome => intestazione;
}