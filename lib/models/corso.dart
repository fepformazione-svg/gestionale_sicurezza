class Corso {
  final int? id;
  final String denominazione;
  final int durataOre;
  final int validitaAnni;
  final String? modelloTestWordPath;
  final String? modelloGradimentoWordPath;

  Corso({
    this.id,
    required this.denominazione,
    required this.durataOre,
    required this.validitaAnni,
    this.modelloTestWordPath,
    this.modelloGradimentoWordPath,
  });

  factory Corso.fromMap(Map<String, dynamic> map) {
    return Corso(
      id: map['id'] as int?,
      denominazione: (map['denominazione'] ?? '').toString(),
      durataOre: int.tryParse((map['durata_ore'] ?? 0).toString()) ?? 0,
      validitaAnni: int.tryParse((map['validita_anni'] ?? 0).toString()) ?? 0,
      modelloTestWordPath: map['modello_test_word_path']?.toString(),
      modelloGradimentoWordPath: map['modello_gradimento_word_path']
          ?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'denominazione': denominazione,
      'durata_ore': durataOre,
      'validita_anni': validitaAnni,
      'modello_test_word_path': modelloTestWordPath,
      'modello_gradimento_word_path': modelloGradimentoWordPath,
    };
  }
}
