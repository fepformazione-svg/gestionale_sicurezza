class Prenotazione {
  final int? id;
  final String discente;
  final String impresa;
  final String corso;
  final String data;
  final String prot;
  final String stato;

  const Prenotazione({
    this.id,
    required this.discente,
    required this.impresa,
    required this.corso,
    required this.data,
    required this.prot,
    this.stato = 'Aperto',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'discente': discente,
      'impresa': impresa,
      'corso': corso,
      'data': data,
      'prot': prot,
      'stato': stato,
    };
  }

  factory Prenotazione.fromMap(Map<String, dynamic> map) {
    return Prenotazione(
      id: map['id'] as int?,
      discente: map['discente'] as String,
      impresa: map['impresa'] as String? ?? '',
      corso: map['corso'] as String,
      data: map['data'] as String? ?? '',
      prot: map['prot'] as String? ?? '',
      stato: map['stato'] as String? ?? 'Aperto',
    );
  }
}