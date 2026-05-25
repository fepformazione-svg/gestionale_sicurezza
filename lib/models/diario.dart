class Diario {
  final int? id;
  final int prenotazioneId;
  final int discenteId;
  final int impresaId;
  final int corsoId;
  final String? dataCorso;
  final String? protocollo;
  final int daFatturare;
  final String? fattura;
  final String? percorsoPdf;

  Diario({
    this.id,
    required this.prenotazioneId,
    required this.discenteId,
    required this.impresaId,
    required this.corsoId,
    this.dataCorso,
    this.protocollo,
    this.daFatturare = 0,
    this.fattura,
    this.percorsoPdf,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prenotazione_id': prenotazioneId,
      'discente_id': discenteId,
      'impresa_id': impresaId,
      'corso_id': corsoId,
      'data_corso': dataCorso,
      'protocollo': protocollo,
      'da_fatturare': daFatturare,
      'fattura': fattura,
      'percorso_pdf': percorsoPdf,
    };
  }
}