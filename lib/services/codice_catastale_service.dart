import '../data/codici_catastali_comuni.dart';

class CodiceCatastaleService {
  static const Map<String, String> _codiciCatastaliStatiEsteri = {
    'AFGHANISTAN': 'Z200',
    'ALBANIA': 'Z100',
    'ALGERIA': 'Z301',
    'ANDORRA': 'Z101',
    'ARGENTINA': 'Z600',
    'AUSTRALIA': 'Z700',
    'AUSTRIA': 'Z102',
    'BANGLADESH': 'Z249',
    'BELGIO': 'Z103',
    'BOLIVIA': 'Z601',
    'BOSNIA-ERZEGOVINA': 'Z153',
    'BOSNIA ERZEGOVINA': 'Z153',
    'BOSNIA ED ERZEGOVINA': 'Z153',
    'BRASILE': 'Z602',
    'BULGARIA': 'Z104',
    'CAMERUN': 'Z306',
    'CANADA': 'Z401',
    'CILE': 'Z603',
    'CINA': 'Z210',
    'REPUBBLICA POPOLARE CINESE': 'Z210',
    'COLOMBIA': 'Z604',
    'COREA DEL NORD': 'Z214',
    'COREA DEL SUD': 'Z213',
    'REPUBBLICA DI COREA': 'Z213',
    "COSTA D'AVORIO": 'Z313',
    'COSTA D AVORIO': 'Z313',
    'COSTA DAVORIO': 'Z313',
    'CROAZIA': 'Z149',
    'DANIMARCA': 'Z107',
    'ECUADOR': 'Z605',
    'EGITTO': 'Z336',
    'EMIRATI ARABI UNITI': 'Z215',
    'ETIOPIA': 'Z315',
    'FEDERAZIONE RUSSA': 'Z154',
    'RUSSIA': 'Z154',
    'FILIPPINE': 'Z216',
    'FINLANDIA': 'Z109',
    'FRANCIA': 'Z110',
    'GERMANIA': 'Z112',
    'GHANA': 'Z318',
    'GIAPPONE': 'Z219',
    'GRECIA': 'Z115',
    'INDIA': 'Z222',
    'INDONESIA': 'Z223',
    'IRAN': 'Z224',
    'IRAQ': 'Z225',
    'IRLANDA': 'Z116',
    'ISLANDA': 'Z117',
    'ISRAELE': 'Z226',
    'KAZAKHSTAN': 'Z255',
    'KENYA': 'Z322',
    'LETTONIA': 'Z145',
    'LITUANIA': 'Z146',
    'MAROCCO': 'Z330',
    'MESSICO': 'Z514',
    'MOLDOVA': 'Z140',
    'NIGERIA': 'Z335',
    'NORVEGIA': 'Z125',
    'NUOVA ZELANDA': 'Z719',
    'PAESI BASSI': 'Z126',
    'OLANDA': 'Z126',
    'PAKISTAN': 'Z236',
    'PERU': 'Z611',
    'POLONIA': 'Z127',
    'PORTOGALLO': 'Z128',
    'REGNO UNITO': 'Z114',
    'GRAN BRETAGNA': 'Z114',
    'INGHILTERRA': 'Z114',
    'UK': 'Z114',
    'UNITED KINGDOM': 'Z114',
    'REPUBBLICA CECA': 'Z156',
    'REPUBBLICA DOMINICANA': 'Z505',
    'ROMANIA': 'Z129',
    'SAN MARINO': 'Z130',
    'SENEGAL': 'Z343',
    'SERBIA': 'Z158',
    'SINGAPORE': 'Z248',
    'SLOVACCHIA': 'Z155',
    'SLOVENIA': 'Z150',
    'SOMALIA': 'Z345',
    'SPAGNA': 'Z131',
    'SRI LANKA': 'Z209',
    'STATI UNITI': 'Z404',
    "STATI UNITI D'AMERICA": 'Z404',
    'STATI UNITI D AMERICA': 'Z404',
    'USA': 'Z404',
    'U.S.A.': 'Z404',
    'U S A': 'Z404',
    'STATI UNITI AMERICA': 'Z404',
    'SUD AFRICA': 'Z347',
    'SVEZIA': 'Z132',
    'SVIZZERA': 'Z133',
    'TUNISIA': 'Z352',
    'TURCHIA': 'Z243',
    'UCRAINA': 'Z138',
    'UNGHERIA': 'Z134',
    'URUGUAY': 'Z613',
    'VENEZUELA': 'Z614',
    'VIETNAM': 'Z251',
  };
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
        _codiciCatastaliStatiEsteri[luogoNormalizzato] ??
        _codiciCatastaliStatiEsteri[luogoArchivioComuni];

    if (codiceStatoEstero != null) {
      return codiceStatoEstero;
    }

    return null;
  }
}
