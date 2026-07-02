class CodiceFiscaleService {
  static String soloLettere(String valore) {
    return valore.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  }

  static String codiceCognome(String cognome) {
    final pulito = soloLettere(cognome);

    final consonanti = pulito.replaceAll(RegExp(r'[AEIOU]'), '');
    final vocali = pulito.replaceAll(RegExp(r'[^AEIOU]'), '');

    final codice = '$consonanti$vocali';

    return codice.padRight(3, 'X').substring(0, 3);
  }

  static String codiceNome(String nome) {
    final pulito = soloLettere(nome);

    final consonanti = pulito.replaceAll(RegExp(r'[AEIOU]'), '');
    final vocali = pulito.replaceAll(RegExp(r'[^AEIOU]'), '');

    String codice;

    if (consonanti.length >= 4) {
      codice = '${consonanti[0]}${consonanti[2]}${consonanti[3]}';
    } else {
      codice = '$consonanti$vocali';
    }

    return codice.padRight(3, 'X').substring(0, 3);
  }

  static String? codiceMese(int mese) {
    const mesi = {
      1: 'A',
      2: 'B',
      3: 'C',
      4: 'D',
      5: 'E',
      6: 'H',
      7: 'L',
      8: 'M',
      9: 'P',
      10: 'R',
      11: 'S',
      12: 'T',
    };

    return mesi[mese];
  }

  static DateTime? parseDataNascita(String? dataNascita) {
    if (dataNascita == null || dataNascita.trim().isEmpty) {
      return null;
    }

    final parti = dataNascita.trim().split('/');

    if (parti.length != 3) {
      return null;
    }

    final giorno = int.tryParse(parti[0]);
    final mese = int.tryParse(parti[1]);
    final anno = int.tryParse(parti[2]);

    if (giorno == null || mese == null || anno == null) {
      return null;
    }

    if (anno < 1900 || mese < 1 || mese > 12 || giorno < 1 || giorno > 31) {
      return null;
    }

    final data = DateTime(anno, mese, giorno);

    if (data.year != anno || data.month != mese || data.day != giorno) {
      return null;
    }

    return data;
  }

  static String? codiceDataSesso({
    required String? dataNascita,
    required String? sesso,
  }) {
    final data = parseDataNascita(dataNascita);

    if (data == null) {
      return null;
    }

    final sessoNormalizzato = sesso?.trim().toUpperCase();

    if (sessoNormalizzato != 'M' && sessoNormalizzato != 'F') {
      return null;
    }

    final anno = (data.year % 100).toString().padLeft(2, '0');
    final mese = codiceMese(data.month);

    if (mese == null) {
      return null;
    }

    final giorno = sessoNormalizzato == 'F' ? data.day + 40 : data.day;

    return '$anno$mese${giorno.toString().padLeft(2, '0')}';
  }

  static String? generaCodiceParziale({
    required String cognome,
    required String nome,
    required String? dataNascita,
    required String? sesso,
    required String? codiceCatastaleNascita,
  }) {
    final codiceData = codiceDataSesso(dataNascita: dataNascita, sesso: sesso);

    final codiceCatastale = codiceCatastaleNascita?.trim().toUpperCase();

    if (codiceData == null) {
      return null;
    }

    if (codiceCatastale == null || codiceCatastale.length != 4) {
      return null;
    }

    return '${codiceCognome(cognome)}'
        '${codiceNome(nome)}'
        '$codiceData'
        '$codiceCatastale';
  }

  static String? carattereControllo(String codiceParziale) {
    final codice = codiceParziale.trim().toUpperCase();

    if (codice.length != 15) {
      return null;
    }

    const valoriDispari = {
      '0': 1,
      '1': 0,
      '2': 5,
      '3': 7,
      '4': 9,
      '5': 13,
      '6': 15,
      '7': 17,
      '8': 19,
      '9': 21,
      'A': 1,
      'B': 0,
      'C': 5,
      'D': 7,
      'E': 9,
      'F': 13,
      'G': 15,
      'H': 17,
      'I': 19,
      'J': 21,
      'K': 2,
      'L': 4,
      'M': 18,
      'N': 20,
      'O': 11,
      'P': 3,
      'Q': 6,
      'R': 8,
      'S': 12,
      'T': 14,
      'U': 16,
      'V': 10,
      'W': 22,
      'X': 25,
      'Y': 24,
      'Z': 23,
    };

    const valoriPari = {
      '0': 0,
      '1': 1,
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      'A': 0,
      'B': 1,
      'C': 2,
      'D': 3,
      'E': 4,
      'F': 5,
      'G': 6,
      'H': 7,
      'I': 8,
      'J': 9,
      'K': 10,
      'L': 11,
      'M': 12,
      'N': 13,
      'O': 14,
      'P': 15,
      'Q': 16,
      'R': 17,
      'S': 18,
      'T': 19,
      'U': 20,
      'V': 21,
      'W': 22,
      'X': 23,
      'Y': 24,
      'Z': 25,
    };

    var somma = 0;

    for (var i = 0; i < codice.length; i++) {
      final carattere = codice[i];

      if (i.isEven) {
        final valore = valoriDispari[carattere];
        if (valore == null) return null;
        somma += valore;
      } else {
        final valore = valoriPari[carattere];
        if (valore == null) return null;
        somma += valore;
      }
    }

    return String.fromCharCode('A'.codeUnitAt(0) + (somma % 26));
  }

  static String? generaCodiceFiscale({
    required String cognome,
    required String nome,
    required String? dataNascita,
    required String? sesso,
    required String? codiceCatastaleNascita,
  }) {
    final codiceParziale = generaCodiceParziale(
      cognome: cognome,
      nome: nome,
      dataNascita: dataNascita,
      sesso: sesso,
      codiceCatastaleNascita: codiceCatastaleNascita,
    );

    if (codiceParziale == null) {
      return null;
    }

    final controllo = carattereControllo(codiceParziale);

    if (controllo == null) {
      return null;
    }

    return '$codiceParziale$controllo';
  }
}
