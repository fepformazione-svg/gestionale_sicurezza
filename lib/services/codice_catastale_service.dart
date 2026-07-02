import '../data/codici_catastali_comuni.dart';

class CodiceCatastaleService {
  static const Map<String, String> _codiciCatastali = {
    // Comuni italiani principali
    'ALBANO LAZIALE': 'A132',
    'ANCONA': 'A271',
    'ANZIO': 'A323',
    'AREZZO': 'A390',
    'ARICCIA': 'A401',
    'BARI': 'A662',
    'BERGAMO': 'A794',
    'BOLOGNA': 'A944',
    'BOLZANO': 'A952',
    'BRESCIA': 'B157',
    'CAGLIARI': 'B354',
    'CASTEL GANDOLFO': 'C116',
    'CATANIA': 'C351',
    'CIAMPINO': 'M272',
    'CIVITAVECCHIA': 'C773',
    'FERRARA': 'D548',
    'FIUMICINO': 'M297',
    'FIRENZE': 'D612',
    'FOGGIA': 'D643',
    'FORLI': 'D704',
    'FORLÃƒÅ’': 'D704',
    'FRASCATI': 'D773',
    'GENOVA': 'D969',
    'GENZANO DI ROMA': 'D972',
    'GROTTAFERRATA': 'E204',
    'GUIDONIA MONTECELIO': 'E263',
    'LANUVIO': 'C767',
    'LATINA': 'E472',
    'LIVORNO': 'E625',
    'MESSINA': 'F158',
    'MILANO': 'F205',
    'MODENA': 'F257',
    'MONZA': 'F704',
    'NAPOLI': 'F839',
    'NETTUNO': 'F880',
    'NOVARA': 'F952',
    'PADOVA': 'G224',
    'PALERMO': 'G273',
    'PARMA': 'G337',
    'PERUGIA': 'G478',
    'PESCARA': 'G482',
    'PIACENZA': 'G535',
    'POLI': 'G784',
    'POMEZIA': 'G811',
    'PRATO': 'G999',
    'RAVENNA': 'H199',
    'REGGIO CALABRIA': 'H224',
    'REGGIO EMILIA': 'H223',
    'RIMINI': 'H294',
    'ROMA': 'H501',
    'SALERNO': 'H703',
    'SASSARI': 'I452',
    'SIRACUSA': 'I754',
    'TERNI': 'L117',
    'TIVOLI': 'L182',
    'TORINO': 'L219',
    'TRENTO': 'L378',
    'TRIESTE': 'L424',
    'VENEZIA': 'L736',
    'VELLETRI': 'L719',
    'VERONA': 'L781',
    'VICENZA': 'L840',

    // Stati esteri principali
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
    'COSTA DÃ¢â‚¬â„¢AVORIO': 'Z313',
    'COSTA D AVORIO': 'Z313',
    "COSTA D'AVORIO": 'Z313',
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
    'STATI UNITI DÃ¢â‚¬â„¢AMERICA': 'Z404',
    "STATI UNITI D'AMERICA": 'Z404',
    'STATI UNITI D AMERICA': 'Z404',
    'USA': 'Z404',
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

    return _codiciCatastali[luogoNormalizzato] ??
        _codiciCatastali[luogoArchivioComuni];
  }
}
