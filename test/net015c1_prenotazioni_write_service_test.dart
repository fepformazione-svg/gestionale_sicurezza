import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gestionale_sicurezza/services/lan_prenotazioni_write_service.dart';

Future<Database> _creaDatabaseTest(String percorso) async {
  final database = await databaseFactoryFfi.openDatabase(percorso);
  await database.execute('''
    CREATE TABLE prenotazioni (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      discente_id INTEGER,
      impresa_id INTEGER,
      corso_id INTEGER,
      docente_id INTEGER,
      aula_sede_id INTEGER,
      ente_attestato_id INTEGER,
      data TEXT,
      prot TEXT,
      aperto INTEGER,
      conferma INTEGER,
      registro INTEGER,
      updated_at TEXT
    )
  ''');
  for (final tabella in [
    'discenti',
    'imprese',
    'corsi',
    'docenti',
    'aule_sedi',
    'enti_attestati',
  ]) {
    await database.execute('CREATE TABLE $tabella (id INTEGER PRIMARY KEY)');
  }
  await database.execute('''
    CREATE TABLE lan_prenotazioni_audit (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prenotazione_id INTEGER NOT NULL,
      operazione TEXT NOT NULL,
      operatore TEXT NOT NULL,
      timestamp_utc TEXT NOT NULL
    )
  ''');
  await database.insert('discenti', {'id': 1});
  await database.insert('imprese', {'id': 1});
  await database.insert('corsi', {'id': 1});
  return database;
}

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late Database database;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('net015c1_');
    final percorso =
        '${directory.path}${Platform.pathSeparator}net015c1_test.db';
    database = await _creaDatabaseTest(percorso);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Map<String, dynamic> datiValidi() => {
    'discente_id': 1,
    'impresa_id': 1,
    'corso_id': 1,
    'data': '2026-11-06',
    'prot': 'PROVA-NET015C1',
  };

  test(
    'NET015C1 inserisce prenotazione e audit nella stessa transazione',
    () async {
      final servizio = LanPrenotazioniWriteService(database);
      final id = await servizio.inserisciPrenotazione(
        dati: datiValidi(),
        operatore: 'operatore-prova',
      );

      final righe = await database.query(
        'prenotazioni',
        where: 'id = ?',
        whereArgs: [id],
      );
      final audit = await database.query('lan_prenotazioni_audit');
      expect(righe, hasLength(1));
      expect(righe.single['conferma'], 0);
      expect(righe.single['prot'], 'PROVA-NET015C1');
      expect(audit, hasLength(1));
      expect(audit.single['prenotazione_id'], id);
      expect(audit.single['operatore'], 'operatore-prova');
      expect(audit.single['operazione'], 'INSERT');
    },
  );

  test('NET015C1 rifiuta riferimenti inesistenti senza scrivere', () async {
    final servizio = LanPrenotazioniWriteService(database);
    await expectLater(
      servizio.inserisciPrenotazione(
        dati: {...datiValidi(), 'corso_id': 999},
        operatore: 'operatore-prova',
      ),
      throwsArgumentError,
    );
    expect(await database.query('prenotazioni'), isEmpty);
    expect(await database.query('lan_prenotazioni_audit'), isEmpty);
  });

  test('NET015C1 rifiuta conferme e dati non autorizzati', () async {
    final servizio = LanPrenotazioniWriteService(database);
    await expectLater(
      servizio.inserisciPrenotazione(
        dati: {...datiValidi(), 'conferma': 1},
        operatore: 'operatore-prova',
      ),
      throwsArgumentError,
    );
    await expectLater(
      servizio.inserisciPrenotazione(
        dati: {...datiValidi(), 'campo_imprevisto': 'valore'},
        operatore: 'operatore-prova',
      ),
      throwsArgumentError,
    );
    await expectLater(
      servizio.inserisciPrenotazione(dati: datiValidi(), operatore: ' '),
      throwsArgumentError,
    );
    expect(await database.query('prenotazioni'), isEmpty);
  });

  test(
    'NET015C1 rollback prenotazione quando il registro audit fallisce',
    () async {
      final servizio = LanPrenotazioniWriteService(database);
      await database.execute('DROP TABLE lan_prenotazioni_audit');
      await expectLater(
        servizio.inserisciPrenotazione(
          dati: datiValidi(),
          operatore: 'operatore-prova',
        ),
        throwsA(isA<Exception>()),
      );
      expect(await database.query('prenotazioni'), isEmpty);
    },
  );
}
