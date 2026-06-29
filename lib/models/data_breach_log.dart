class DataBreachLog {
  final int? id;
  final int? dataBreachId;
  final String azione;
  final String descrizione;
  final String? datiPrima;
  final String? datiDopo;
  final String? utente;
  final String dataOra;

  DataBreachLog({
    this.id,
    this.dataBreachId,
    required this.azione,
    required this.descrizione,
    this.datiPrima,
    this.datiDopo,
    this.utente,
    required this.dataOra,
  });

  factory DataBreachLog.fromMap(Map<String, dynamic> map) {
    return DataBreachLog(
      id: map['id'] as int?,
      dataBreachId: map['data_breach_id'] as int?,
      azione: map['azione']?.toString() ?? '',
      descrizione: map['descrizione']?.toString() ?? '',
      datiPrima: map['dati_prima']?.toString(),
      datiDopo: map['dati_dopo']?.toString(),
      utente: map['utente']?.toString(),
      dataOra: map['data_ora']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_breach_id': dataBreachId,
      'azione': azione,
      'descrizione': descrizione,
      'dati_prima': datiPrima,
      'dati_dopo': datiDopo,
      'utente': utente,
      'data_ora': dataOra,
    };
  }
}
