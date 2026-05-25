class Corso {
  final int? id;
  final String denominazione;
  final int durataOre;
  final int validitaAnni;

  Corso({
    this.id,
    required this.denominazione,
    required this.durataOre,
    required this.validitaAnni,
  });

  factory Corso.fromMap(Map<String, dynamic> map) {
    return Corso(
      id: map['id'] as int?,
      denominazione: (map['denominazione'] ?? '').toString(),
      durataOre: int.tryParse((map['durata_ore'] ?? 0).toString()) ?? 0,
      validitaAnni: int.tryParse((map['validita_anni'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'denominazione': denominazione,
      'durata_ore': durataOre,
      'validita_anni': validitaAnni,
    };
  }
}