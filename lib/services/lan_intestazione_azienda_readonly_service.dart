import 'package:gestionale_sicurezza/services/lan_readonly_database_service.dart';

String _testoPulito(Object? valore) {
  return valore?.toString().trim() ?? '';
}

String _unisciParti(List<String> parti, {String separatore = ' - '}) {
  return parti.where((parte) => parte.trim().isNotEmpty).join(separatore);
}

Future<Map<String, dynamic>?> loadLanIntestazioneAziendaReadOnly(
  String databasePath,
) async {
  final database = await openLanReadOnlyDatabase(databasePath);

  try {
    final rows = await database.rawQuery('''
      SELECT
        ragione_sociale,
        nome_commerciale,
        partita_iva,
        codice_fiscale,
        indirizzo,
        cap,
        comune,
        provincia,
        telefono,
        email,
        pec,
        sito_web
      FROM dati_azienda
      ORDER BY id ASC
      LIMIT 1
    ''');

    if (rows.isEmpty) return null;

    final dati = rows.first;

    final ragioneSociale = _testoPulito(dati['ragione_sociale']);
    final nomeCommerciale = _testoPulito(dati['nome_commerciale']);
    final partitaIva = _testoPulito(dati['partita_iva']);
    final codiceFiscale = _testoPulito(dati['codice_fiscale']);
    final indirizzo = _testoPulito(dati['indirizzo']);
    final cap = _testoPulito(dati['cap']);
    final comune = _testoPulito(dati['comune']);
    final provincia = _testoPulito(dati['provincia']);
    final telefono = _testoPulito(dati['telefono']);
    final email = _testoPulito(dati['email']);
    final pec = _testoPulito(dati['pec']);
    final sitoWeb = _testoPulito(dati['sito_web']);

    final titolo = nomeCommerciale.isNotEmpty
        ? nomeCommerciale
        : ragioneSociale.isNotEmpty
        ? ragioneSociale
        : 'F&P Formazione e Prevenzione';

    final sede = _unisciParti([
      indirizzo,
      _unisciParti([cap, comune, provincia], separatore: ' '),
    ]);

    final datiFiscali = _unisciParti([
      if (partitaIva.isNotEmpty) 'P.IVA $partitaIva',
      if (codiceFiscale.isNotEmpty) 'CF $codiceFiscale',
    ]);

    final contatti = _unisciParti([
      if (telefono.isNotEmpty) 'Tel. $telefono',
      if (email.isNotEmpty) email,
      if (pec.isNotEmpty) 'PEC $pec',
      if (sitoWeb.isNotEmpty) sitoWeb,
    ]);

    return <String, dynamic>{
      'titolo': titolo,
      'sottotitolo': _unisciParti([ragioneSociale, datiFiscali]),
      'dettaglio': _unisciParti([sede, contatti]),
    };
  } finally {
    await database.close();
  }
}
