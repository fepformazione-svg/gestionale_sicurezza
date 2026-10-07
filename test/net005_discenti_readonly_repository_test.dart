import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/lan_discenti_readonly_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test(
    'NET005 legge discenti e intestazione impresa in sola lettura',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'gestionale_sicurezza_net005_',
      );

      final dbPath =
          '${tempDir.path}${Platform.pathSeparator}net005_discenti.db';

      final writableDatabase = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(singleInstance: false),
      );

      await writableDatabase.execute('''
        CREATE TABLE imprese (
          id INTEGER PRIMARY KEY,
          intestazione TEXT NOT NULL
        )
        ''');

      await writableDatabase.execute('''
        CREATE TABLE discenti (
          id INTEGER PRIMARY KEY,
          nome TEXT NOT NULL,
          cognome TEXT,
          impresa_id INTEGER,
          FOREIGN KEY (impresa_id)
            REFERENCES imprese(id)
        )
        ''');

      await writableDatabase.insert('imprese', {
        'id': 10,
        'intestazione': 'Impresa Alfa',
      });

      await writableDatabase.insert('discenti', {
        'id': 1,
        'nome': 'Mario',
        'cognome': 'Rossi',
        'impresa_id': 10,
      });

      await writableDatabase.insert('discenti', {
        'id': 2,
        'nome': 'Luigi',
        'cognome': 'Bianchi',
        'impresa_id': null,
      });

      await writableDatabase.close();

      try {
        final rows = await loadLanDiscentiReadOnly(dbPath);

        expect(rows.length, 2);

        expect(rows[0], {
          'id': 2,
          'nome': 'Luigi',
          'cognome': 'Bianchi',
          'impresa_id': null,
          'nome_impresa': null,
        });

        expect(rows[1], {
          'id': 1,
          'nome': 'Mario',
          'cognome': 'Rossi',
          'impresa_id': 10,
          'nome_impresa': 'Impresa Alfa',
        });
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );
}
