class Scadenza {
  final int? id;
  final int diarioId;
  final int discenteId;
  final int impresaId;
  final int corsoId;
  final String? dataCorso;
  final String? dataScadenza;
  final String stato;
  final String? note;

  Scadenza({
    this.id,
    required this.diarioId,
    required this.discenteId,
    required this.impresaId,
    required this.corsoId,
    this.dataCorso,
    this.dataScadenza,
    this.stato = 'ATTIVA',
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diario_id': diarioId,
      'discente_id': discenteId,
      'impresa_id': impresaId,
      'corso_id': corsoId,
      'data_corso': dataCorso,
      'data_scadenza': dataScadenza,
      'stato': stato,
      'note': note,
    };
  }
}