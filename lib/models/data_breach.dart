class DataBreach {
  final int? id;
  final String dataEvento;
  final String dataRilevazione;
  final String descrizione;
  final String categorieDati;
  final String categorieInteressati;
  final String numeroInteressati;
  final String conseguenze;
  final String misureAdottate;
  final String rischio;
  final bool notificatoGarante;
  final String dataNotificaGarante;
  final bool comunicatoInteressati;
  final String dataComunicazioneInteressati;
  final String motivazioneMancataNotifica;
  final String responsabileInterno;
  final String stato;
  final String note;
  final String createdAt;
  final String updatedAt;

  DataBreach({
    this.id,
    required this.dataEvento,
    required this.dataRilevazione,
    required this.descrizione,
    required this.categorieDati,
    required this.categorieInteressati,
    required this.numeroInteressati,
    required this.conseguenze,
    required this.misureAdottate,
    required this.rischio,
    required this.notificatoGarante,
    required this.dataNotificaGarante,
    required this.comunicatoInteressati,
    required this.dataComunicazioneInteressati,
    required this.motivazioneMancataNotifica,
    required this.responsabileInterno,
    required this.stato,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DataBreach.fromMap(Map<String, dynamic> map) {
    return DataBreach(
      id: map['id'] as int?,
      dataEvento: map['data_evento'] ?? '',
      dataRilevazione: map['data_rilevazione'] ?? '',
      descrizione: map['descrizione'] ?? '',
      categorieDati: map['categorie_dati'] ?? '',
      categorieInteressati: map['categorie_interessati'] ?? '',
      numeroInteressati: map['numero_interessati'] ?? '',
      conseguenze: map['conseguenze'] ?? '',
      misureAdottate: map['misure_adottate'] ?? '',
      rischio: map['rischio'] ?? 'Da valutare',
      notificatoGarante: (map['notificato_garante'] ?? 0) == 1,
      dataNotificaGarante: map['data_notifica_garante'] ?? '',
      comunicatoInteressati: (map['comunicato_interessati'] ?? 0) == 1,
      dataComunicazioneInteressati: map['data_comunicazione_interessati'] ?? '',
      motivazioneMancataNotifica: map['motivazione_mancata_notifica'] ?? '',
      responsabileInterno: map['responsabile_interno'] ?? '',
      stato: map['stato'] ?? 'Aperto',
      note: map['note'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_evento': dataEvento,
      'data_rilevazione': dataRilevazione,
      'descrizione': descrizione,
      'categorie_dati': categorieDati,
      'categorie_interessati': categorieInteressati,
      'numero_interessati': numeroInteressati,
      'conseguenze': conseguenze,
      'misure_adottate': misureAdottate,
      'rischio': rischio,
      'notificato_garante': notificatoGarante ? 1 : 0,
      'data_notifica_garante': dataNotificaGarante,
      'comunicato_interessati': comunicatoInteressati ? 1 : 0,
      'data_comunicazione_interessati': dataComunicazioneInteressati,
      'motivazione_mancata_notifica': motivazioneMancataNotifica,
      'responsabile_interno': responsabileInterno,
      'stato': stato,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DataBreach copyWith({
    int? id,
    String? dataEvento,
    String? dataRilevazione,
    String? descrizione,
    String? categorieDati,
    String? categorieInteressati,
    String? numeroInteressati,
    String? conseguenze,
    String? misureAdottate,
    String? rischio,
    bool? notificatoGarante,
    String? dataNotificaGarante,
    bool? comunicatoInteressati,
    String? dataComunicazioneInteressati,
    String? motivazioneMancataNotifica,
    String? responsabileInterno,
    String? stato,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return DataBreach(
      id: id ?? this.id,
      dataEvento: dataEvento ?? this.dataEvento,
      dataRilevazione: dataRilevazione ?? this.dataRilevazione,
      descrizione: descrizione ?? this.descrizione,
      categorieDati: categorieDati ?? this.categorieDati,
      categorieInteressati: categorieInteressati ?? this.categorieInteressati,
      numeroInteressati: numeroInteressati ?? this.numeroInteressati,
      conseguenze: conseguenze ?? this.conseguenze,
      misureAdottate: misureAdottate ?? this.misureAdottate,
      rischio: rischio ?? this.rischio,
      notificatoGarante: notificatoGarante ?? this.notificatoGarante,
      dataNotificaGarante: dataNotificaGarante ?? this.dataNotificaGarante,
      comunicatoInteressati:
          comunicatoInteressati ?? this.comunicatoInteressati,
      dataComunicazioneInteressati:
          dataComunicazioneInteressati ?? this.dataComunicazioneInteressati,
      motivazioneMancataNotifica:
          motivazioneMancataNotifica ?? this.motivazioneMancataNotifica,
      responsabileInterno: responsabileInterno ?? this.responsabileInterno,
      stato: stato ?? this.stato,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
