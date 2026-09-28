import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/app_database.dart';

void main() {
  test('SEDI001 migra aule_sedi da schema 12 a 13 preservando i dati', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final tempDir = await Directory.systemTemp.createTemp(
      'gestionale_sicurezza_sedi001_',
    );

    final path =
        '${tempDir.path}${Platform.pathSeparator}sedi001_schema_test.db';

    try {
      await AppDatabase.instance.close();
      AppDatabase.setDatabasePathOverrideForTesting(null);

      final dbVersione12 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 12,
          onCreate: (db, version) async {
            await db.execute('''
                CREATE TABLE aule_sedi (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  denominazione TEXT NOT NULL,
                  tipo TEXT NOT NULL DEFAULT 'Aula',
                  indirizzo TEXT NOT NULL DEFAULT '',
                  comune TEXT NOT NULL DEFAULT '',
                  capienza INTEGER,
                  note TEXT NOT NULL DEFAULT '',
                  attiva INTEGER NOT NULL DEFAULT 1,
                  created_at TEXT,
                  updated_at TEXT
                )
              ''');

            await db.insert('aule_sedi', {
              'denominazione': 'UFFICI CARDO',
              'tipo': 'Sede cliente',
              'indirizzo': 'VIA FRANCESCO ANTOLISEI 6',
              'comune': 'ROMA',
              'capienza': 20,
              'note': 'Dato storico SEDI001',
              'attiva': 1,
            });
          },
        ),
      );

      await dbVersione12.close();

      AppDatabase.setDatabasePathOverrideForTesting(path);

      final db = await AppDatabase.instance.database;

      final versioneRows = await db.rawQuery('PRAGMA user_version');
      final versione = versioneRows.first['user_version'] as int;

      expect(
        versione,
        13,
        reason: 'SEDI001 deve portare lo schema database alla versione 13.',
      );

      final info = await db.rawQuery('PRAGMA table_info(aule_sedi)');

      final colonne = info
          .map((riga) => riga['name']?.toString() ?? '')
          .toSet();

      expect(
        colonne,
        contains('codice'),
        reason: 'La tabella aule_sedi deve contenere la colonna codice.',
      );

      final sedi = await db.query(
        'aule_sedi',
        where: 'denominazione = ?',
        whereArgs: ['UFFICI CARDO'],
      );

      expect(sedi, hasLength(1));

      final sede = sedi.single;

      expect(sede['denominazione'], 'UFFICI CARDO');
      expect(sede['indirizzo'], 'VIA FRANCESCO ANTOLISEI 6');
      expect(sede['comune'], 'ROMA');
      expect(sede['note'], 'Dato storico SEDI001');

      expect(
        sede['codice'],
        '',
        reason:
            'Le sedi esistenti devono ricevere codice vuoto senza perdere dati.',
      );
    } finally {
      await AppDatabase.instance.close();

      AppDatabase.setDatabasePathOverrideForTesting(null);

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });
}
