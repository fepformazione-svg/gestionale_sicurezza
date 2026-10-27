import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../bin/lan_server.dart' as lan_runner;

void main() {
  test('NET014K-14 runner collega intestazione SQLite al server LAN', () async {
    sqfliteFfiInit();

    final directory = await Directory.systemTemp.createTemp(
      'net014_runner_test_',
    );

    final databasePath =
        '${directory.path}${Platform.pathSeparator}azienda_test.db';

    try {
      final database = await databaseFactoryFfi.openDatabase(databasePath);

      try {
        await database.execute('''
          CREATE TABLE dati_azienda (
            id INTEGER PRIMARY KEY,
            ragione_sociale TEXT,
            nome_commerciale TEXT,
            partita_iva TEXT,
            codice_fiscale TEXT,
            indirizzo TEXT,
            cap TEXT,
            comune TEXT,
            provincia TEXT,
            telefono TEXT,
            email TEXT,
            pec TEXT,
            sito_web TEXT,
            logo_path TEXT,
            note TEXT
          )
        ''');

        await database.insert('dati_azienda', {
          'id': 1,
          'ragione_sociale': 'F&P S.r.l.s.',
          'nome_commerciale': 'F&P Formazione e Privacy',
          'partita_iva': '01234567890',
          'codice_fiscale': '01234567890',
          'indirizzo': 'Via dei Corsi 12',
          'cap': '00100',
          'comune': 'Roma',
          'provincia': 'RM',
          'telefono': '0600000000',
          'email': 'info@example.it',
          'pec': 'fep@pec.it',
          'sito_web': 'https://example.it',
          'logo_path': r'C:\riservato\logo.png',
          'note': 'INFORMAZIONE RISERVATA',
        });
      } finally {
        await database.close();
      }

      final server = lan_runner.buildLanServerService(
        databasePath: databasePath,
        apiToken: 'token-test-net014',
      );

      await server.start(address: InternetAddress.loopbackIPv4, port: 0);

      final client = HttpClient();

      try {
        final request = await client.get(
          InternetAddress.loopbackIPv4.address,
          server.port,
          '/api/intestazione-azienda',
        );

        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer token-test-net014',
        );

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, HttpStatus.ok);

        final json = jsonDecode(body) as Map<String, dynamic>;

        expect(json['sola_lettura'], true);

        final intestazione = json['intestazione'] as Map<String, dynamic>;

        expect(intestazione.keys.toSet(), {
          'titolo',
          'sottotitolo',
          'dettaglio',
        });

        expect(intestazione['titolo'], 'F&P Formazione e Privacy');

        expect(intestazione.toString().contains('RISERVATA'), false);
      } finally {
        client.close(force: true);
        await server.stop();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
