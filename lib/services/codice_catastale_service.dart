import '../data/codici_catastali_comuni.dart';
import '../data/codici_catastali_stati_esteri.dart';

class CodiceCatastaleService {
  static String normalizzaLuogo(String valore) {
    return valore
        .trim()
        .toUpperCase()
        .replaceAll('\u2019', "'")
        .replaceAll('\u2018', "'")
        .replaceAll('\u0060', "'")
        .replaceAll('\u00B4', "'")
        .replaceAll('\u2010', '-')
        .replaceAll('\u2011', '-')
        .replaceAll('\u2012', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00C0', 'A')
        .replaceAll('\u00C8', 'E')
        .replaceAll('\u00C9', 'E')
        .replaceAll('\u00CC', 'I')
        .replaceAll('\u00D2', 'O')
        .replaceAll('\u00D9', 'U');
  }

  static String normalizzaLuogoArchivioComuni(String valore) {
    return normalizzaLuogo(valore)
        .replaceAll("'", ' ')
        .replaceAll('-', ' ')
        .replaceAll('.', ' ')
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? messaggioComuneItalianoAmbiguo(String? luogoNascita) {
    if (luogoNascita == null || luogoNascita.trim().isEmpty) {
      return null;
    }

    final luogoArchivioComuni = normalizzaLuogoArchivioComuni(luogoNascita);
    final comuniAmbigui = comuniCatastaliItalianiAmbigui[luogoArchivioComuni];

    if (comuniAmbigui == null || comuniAmbigui.isEmpty) {
      return null;
    }

    final esempi = comuniAmbigui
        .map((comune) => '${comune.nome} ${comune.provincia}')
        .join(' oppure ');

    return 'Comune di nascita ambiguo: specificare anche la provincia, ad esempio $esempi.';
  }

  static String? cercaCodiceCatastaleComuneAmbiguo(String luogoNascita) {
    final luogoArchivioComuni = normalizzaLuogoArchivioComuni(luogoNascita);

    for (final gruppo in comuniCatastaliItalianiAmbigui.entries) {
      final nomeComune = gruppo.key;

      for (final comune in gruppo.value) {
        final provincia = comune.provincia;

        if (provincia.isEmpty) {
          continue;
        }

        final chiaviConProvincia = <String>{
          '$nomeComune $provincia',
          '$provincia $nomeComune',
        };

        if (chiaviConProvincia.contains(luogoArchivioComuni)) {
          return comune.codiceCatastale;
        }
      }
    }

    return null;
  }

  static String? cercaCodiceCatastale(String? luogoNascita) {
    if (luogoNascita == null || luogoNascita.trim().isEmpty) {
      return null;
    }

    final luogoNormalizzato = normalizzaLuogo(luogoNascita);
    final luogoArchivioComuni = normalizzaLuogoArchivioComuni(luogoNascita);

    final codiceComuneUnivoco =
        codiciCatastaliComuniItaliani[luogoArchivioComuni];

    if (codiceComuneUnivoco != null) {
      return codiceComuneUnivoco;
    }

    final codiceComuneAmbiguo = cercaCodiceCatastaleComuneAmbiguo(luogoNascita);

    if (codiceComuneAmbiguo != null) {
      return codiceComuneAmbiguo;
    }

    if (comuniCatastaliItalianiAmbigui.containsKey(luogoArchivioComuni)) {
      return null;
    }

    final codiceStatoEstero =
        codiciCatastaliStatiEsteri[luogoNormalizzato] ??
        codiciCatastaliStatiEsteri[luogoArchivioComuni];

    if (codiceStatoEstero != null) {
      return codiceStatoEstero;
    }

    return null;
  }
}
