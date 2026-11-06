import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_prenotazioni_write_service.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// NET015C3 collega HTTP e SQLite solo dentro questo test. Non modifica
// bin/lan_server.dart e non abilita la scrittura sul server operativo.
const _tokenTest = 'token-solo-net015c3';
const _operatoreFixture = 'NET015C3_OPERATORE_DI_TEST';

Future<Database> _creaDatabaseTemporaneo(String percorso) async {
  final database = await databaseFactoryFfi.openDatabase(percorso);

  try {
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
  } catch (_) {
    await database.close();
    rethrow;
  }
}

LanServerService _creaServerDiTest(Database database) {
  final servizio = LanPrenotazioniWriteService(database);
  return LanServerService(
    apiToken: _tokenTest,
    prenotazioniInsertProvider: (dati) => servizio.inserisciPrenotazione(
      dati: dati,
      // Identita' stabilita dal test, mai letta dal JSON del client.
      // NON equivale ancora ad autenticazione individuale in produzione.
      operatore: _operatoreFixture,
    ),
  );
}

Map<String, dynamic> _datiValidi() => {
  'discente_id': 1,
  'impresa_id': 1,
  'corso_id': 1,
  'data': '2026-11-06',
  'prot': 'PROVA-NET015C3',
};

Future<({int stato, Map<String, dynamic> risposta})> _inviaPost(
  HttpClient client,
  int porta, {
  required Map<String, dynamic> dati,
  String? token = _tokenTest,
}) async {
  final richiesta = await client.post(
    InternetAddress.loopbackIPv4.address,
    porta,
    '/api/prenotazioni',
  );
  richiesta.headers.contentType = ContentType.json;
  if (token != null) {
    richiesta.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
  richiesta.write(jsonEncode({'dati': dati}));
  final risposta = await richiesta.close();
  final contenuto = await risposta.transform(utf8.decoder).join();
  return (
    stato: risposta.statusCode,
    risposta: jsonDecode(contenuto) as Map<String, dynamic>,
  );
}

void main() {
  sqfliteFfiInit();

  late Directory cartellaTemporanea;
  late Database database;

  setUp(() async {
    cartellaTemporanea = await Directory.systemTemp.createTemp('net015c3_');
    final percorso =
        '${cartellaTemporanea.path}${Platform.pathSeparator}net015c3_test.db';
    database = await _creaDatabaseTemporaneo(percorso);
  });

  tearDown(() async {
    await database.close();
    await cartellaTemporanea.delete(recursive: true);
  });

  test(
    'NET015C3 POST HTTP inserisce prenotazione e audit nel DB temporaneo',
    () async {
      final server = _creaServerDiTest(database);
      await server.start(address: InternetAddress.loopbackIPv4, port: 0);
      final client = HttpClient();

      try {
        final risultato = await _inviaPost(
          client,
          server.port,
          dati: _datiValidi(),
        );
        expect(risultato.stato, HttpStatus.created);
        final id = risultato.risposta['id'];
        expect(id, isA<int>());

        final prenotazioni = await database.query('prenotazioni');
        final audit = await database.query('lan_prenotazioni_audit');
        expect(prenotazioni, hasLength(1));
        expect(prenotazioni.single['id'], id);
        expect(prenotazioni.single['conferma'], 0);
        expect(prenotazioni.single['prot'], 'PROVA-NET015C3');
        expect(audit, hasLength(1));
        expect(audit.single['prenotazione_id'], id);
        expect(audit.single['operazione'], 'INSERT');
        expect(audit.single['operatore'], _operatoreFixture);
      } finally {
        client.close(force: true);
        await server.stop();
      }
    },
  );

  test('NET015C3 rifiuta dati non validi e operatore falsificato', () async {
    final server = _creaServerDiTest(database);
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      for (final dati in [
        {..._datiValidi(), 'corso_id': 999},
        {..._datiValidi(), 'conferma': 1},
        {..._datiValidi(), 'operatore': 'OPERATORE_FALSO'},
      ]) {
        final risultato = await _inviaPost(client, server.port, dati: dati);
        expect(risultato.stato, HttpStatus.badRequest);
        expect(risultato.risposta['error'], 'invalid_prenotazione');
      }
      expect(await database.query('prenotazioni'), isEmpty);
      expect(await database.query('lan_prenotazioni_audit'), isEmpty);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C3 senza token non scrive nulla nel DB temporaneo', () async {
    final server = _creaServerDiTest(database);
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final risultato = await _inviaPost(
        client,
        server.port,
        dati: _datiValidi(),
        token: null,
      );
      expect(risultato.stato, HttpStatus.unauthorized);
      expect(await database.query('prenotazioni'), isEmpty);
      expect(await database.query('lan_prenotazioni_audit'), isEmpty);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C3 senza audit annulla la prenotazione via HTTP', () async {
    final server = _creaServerDiTest(database);
    await database.execute('DROP TABLE lan_prenotazioni_audit');
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final risultato = await _inviaPost(
        client,
        server.port,
        dati: _datiValidi(),
      );
      expect(risultato.stato, HttpStatus.internalServerError);
      expect(risultato.risposta['error'], 'prenotazione_insert_failed');
      expect(await database.query('prenotazioni'), isEmpty);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
