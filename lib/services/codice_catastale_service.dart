class CodiceCatastaleService {
  static const Map<String, String> _codiciCatastali = {
    // Comuni italiani principali / test iniziali
    'ROMA': 'H501',

    // Stati esteri principali / test iniziali
    'NIGERIA': 'Z335',
  };

  static String normalizzaLuogo(String valore) {
    return valore
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00C0', 'A')
        .replaceAll('\u00C8', 'E')
        .replaceAll('\u00C9', 'E')
        .replaceAll('\u00CC', 'I')
        .replaceAll('\u00D2', 'O')
        .replaceAll('\u00D9', 'U');
  }

  static String? cercaCodiceCatastale(String? luogoNascita) {
    if (luogoNascita == null || luogoNascita.trim().isEmpty) {
      return null;
    }

    final luogoNormalizzato = normalizzaLuogo(luogoNascita);
    return _codiciCatastali[luogoNormalizzato];
  }
}
