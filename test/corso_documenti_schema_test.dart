import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/app_database.dart';

void main() {
  test(
    'schema corsi aggiunge i percorsi Word preservando i dati esistenti',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final tempDir = await Directory.systemTemp.createTemp(
        'gestionale_sicurezza_doc001_',
      );

      final path =
          '${tempDir.path}${Platform.pathSeparator}doc001_schema_test.db';

      try {
        await AppDatabase.instance.close();

        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 11,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE corsi (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  denominazione TEXT NOT NULL,
                  durata_ore INTEGER DEFAULT 0,
                  validita_anni INTEGER DEFAULT 0,
                  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                  updated_at TEXT
                )
              ''');

              await db.insert('corsi', {
                'denominazione': 'Corso legacy DOC001',
                'durata_ore': 8,
                'validita_anni': 5,
              });
            },
          ),
        );

        await legacyDb.close();

        AppDatabase.setDatabasePathOverrideForTesting(path);

        final db = await AppDatabase.instance.database;

        final righe = await db.query(
          'corsi',
          where: 'denominazione = ?',
          whereArgs: ['Corso legacy DOC001'],
        );

        expect(
          righe,
          hasLength(1),
          reason: 'Il corso esistente non deve essere perso.',
        );

        expect(righe.first['durata_ore'], 8);

        expect(righe.first['validita_anni'], 5);

        final schema = await db.rawQuery('PRAGMA table_info(corsi)');

        final colonne = schema
            .map((riga) => riga['name']?.toString())
            .whereType<String>()
            .toSet();

        expect(colonne, contains('modello_test_word_path'));

        expect(colonne, contains('modello_gradimento_word_path'));

        final corsoAggiornato = await db.query(
          'corsi',
          where: 'denominazione = ?',
          whereArgs: ['Corso legacy DOC001'],
        );

        expect(corsoAggiornato.first['modello_test_word_path'], isNull);

        expect(corsoAggiornato.first['modello_gradimento_word_path'], isNull);

        final versione = await db.rawQuery('PRAGMA user_version');

        expect(versione.first.values.first, 12);
      } finally {
        await AppDatabase.instance.close();

        AppDatabase.setDatabasePathOverrideForTesting(null);

        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    },
  );
}
