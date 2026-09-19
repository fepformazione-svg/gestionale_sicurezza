class DocumentoWordContext {
  final String nome;
  final String cognome;
  final String codiceFiscale;
  final String luogoNascita;
  final String dataNascita;

  final String corso;
  final String protocollo;
  final String dataCorso;

  final String sede;
  final String indirizzoSede;
  final String comuneSede;

  final String docenteNome;
  final String docenteCognome;
  final String docenteQualifica;

  final String impresa;

  const DocumentoWordContext({
    required this.nome,
    required this.cognome,
    required this.codiceFiscale,
    required this.luogoNascita,
    required this.dataNascita,
    required this.corso,
    required this.protocollo,
    required this.dataCorso,
    required this.sede,
    required this.indirizzoSede,
    required this.comuneSede,
    required this.docenteNome,
    required this.docenteCognome,
    required this.docenteQualifica,
    required this.impresa,
  });

  String get nomeCognome {
    return '$nome $cognome'.trim();
  }

  String get docente {
    return '$docenteNome $docenteCognome'.trim();
  }

  Map<String, String> get placeholderValues {
    return {
      '{{NOME}}': nome,
      '{{COGNOME}}': cognome,
      '{{NOME_COGNOME}}': nomeCognome,
      '{{CODICE_FISCALE}}': codiceFiscale,
      '{{LUOGO_NASCITA}}': luogoNascita,
      '{{DATA_NASCITA}}': dataNascita,
      '{{CORSO}}': corso,
      '{{PROTOCOLLO}}': protocollo,
      '{{DATA_CORSO}}': dataCorso,
      '{{SEDE}}': sede,
      '{{INDIRIZZO_SEDE}}': indirizzoSede,
      '{{COMUNE_SEDE}}': comuneSede,
      '{{DOCENTE}}': docente,
      '{{QUALIFICA_DOCENTE}}': docenteQualifica,
      '{{IMPRESA}}': impresa,
    };
  }

  DocumentoWordContext senzaDiscente() {
    return DocumentoWordContext(
      nome: '',
      cognome: '',
      codiceFiscale: '',
      luogoNascita: '',
      dataNascita: '',
      corso: corso,
      protocollo: protocollo,
      dataCorso: dataCorso,
      sede: sede,
      indirizzoSede: indirizzoSede,
      comuneSede: comuneSede,
      docenteNome: docenteNome,
      docenteCognome: docenteCognome,
      docenteQualifica: docenteQualifica,
      impresa: impresa,
    );
  }
}
