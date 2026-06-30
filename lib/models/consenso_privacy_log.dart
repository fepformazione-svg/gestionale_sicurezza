class ConsensoPrivacyLog {
  final int? id;
  final int? consensoPrivacyId;
  final String azione;
  final String descrizione;
  final String? datiPrima;
  final String? datiDopo;
  final String utente;
  final DateTime dataOra;

  ConsensoPrivacyLog({
    this.id,
    this.consensoPrivacyId,
    required this.azione,
    required this.descrizione,
    this.datiPrima,
    this.datiDopo,
    required this.utente,
    required this.dataOra,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consenso_privacy_id': consensoPrivacyId,
      'azione': azione,
      'descrizione': descrizione,
      'dati_prima': datiPrima,
      'dati_dopo': datiDopo,
      'utente': utente,
      'data_ora': dataOra.toIso8601String(),
    };
  }

  factory ConsensoPrivacyLog.fromMap(Map<String, dynamic> map) {
    return ConsensoPrivacyLog(
      id: map['id'] as int?,
      consensoPrivacyId: map['consenso_privacy_id'] as int?,
      azione: map['azione'] as String? ?? '',
      descrizione: map['descrizione'] as String? ?? '',
      datiPrima: map['dati_prima'] as String?,
      datiDopo: map['dati_dopo'] as String?,
      utente: map['utente'] as String? ?? 'Sistema',
      dataOra:
          DateTime.tryParse(map['data_ora'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
