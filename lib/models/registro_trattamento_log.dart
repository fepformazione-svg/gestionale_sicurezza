class RegistroTrattamentoLog {
  final int? id;
  final int? trattamentoId;
  final String azione;
  final String descrizione;
  final String? datiPrima;
  final String? datiDopo;
  final String? utente;
  final String dataOra;

  RegistroTrattamentoLog({
    this.id,
    this.trattamentoId,
    required this.azione,
    required this.descrizione,
    this.datiPrima,
    this.datiDopo,
    this.utente,
    required this.dataOra,
  });

  factory RegistroTrattamentoLog.fromMap(Map<String, dynamic> map) {
    return RegistroTrattamentoLog(
      id: map['id'] as int?,
      trattamentoId: map['trattamento_id'] as int?,
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
      'trattamento_id': trattamentoId,
      'azione': azione,
      'descrizione': descrizione,
      'dati_prima': datiPrima,
      'dati_dopo': datiDopo,
      'utente': utente,
      'data_ora': dataOra,
    };
  }
}
