import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gestionale_sicurezza/services/lan_corsi_readonly_service.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET014D HTTP autenticato legge corsi da SQLite', () async {
    sqfliteFfiInit();

    final directory = await Directory.systemTemp.createTemp(
      'net014_integration_',
    );

    try {
      final databasePath = '${directory.path}${Platform.pathSeparator}test.db';

      final database = await databaseFactoryFfi.openDatabase(databasePath);

      try {
        await database.execute('''
          CREATE TABLE corsi (
            id INTEGER PRIMARY KEY,
            denominazione TEXT NOT NULL,
            durata_ore INTEGER,
            validita_anni INTEGER,
            modello_test_word_path TEXT,
            modello_gradimento_word_path TEXT
          )
        ''');

        await database.insert('corsi', {
          'id': 7,
          'denominazione': 'PONTEGGI - 28 ORE',
          'durata_ore': 28,
          'validita_anni': 4,
          'modello_test_word_path': 'RISERVATO/test.docx',
          'modello_gradimento_word_path': 'RISERVATO/gradimento.docx',
        });
      } finally {
        await database.close();
      }

      final server = LanServerService(
        apiToken: 'token-test-net014',
        corsiProvider: () => loadLanCorsiReadOnly(databasePath),
      );

      await server.start(address: InternetAddress.loopbackIPv4, port: 0);

      final client = HttpClient();

      try {
        final deniedRequest = await client.get(
          InternetAddress.loopbackIPv4.address,
          server.port,
          '/api/corsi',
        );

        final deniedResponse = await deniedRequest.close();

        expect(deniedResponse.statusCode, HttpStatus.unauthorized);

        await deniedResponse.transform(utf8.decoder).join();

        final request = await client.get(
          InternetAddress.loopbackIPv4.address,
          server.port,
          '/api/corsi',
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
        expect(json['count'], 1);

        final items = json['items'] as List<dynamic>;

        expect(items.single, {
          'id': 7,
          'denominazione': 'PONTEGGI - 28 ORE',
          'durata_ore': 28,
          'validita_anni': 4,
        });
      } finally {
        client.close(force: true);
        await server.stop();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
