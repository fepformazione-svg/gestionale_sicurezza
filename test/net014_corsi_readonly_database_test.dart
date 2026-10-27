import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gestionale_sicurezza/services/lan_corsi_readonly_service.dart';

void main() {
  test('NET014C legge corsi dal database in sola lettura', () async {
    sqfliteFfiInit();

    final directory = await Directory.systemTemp.createTemp(
      'net014_corsi_test_',
    );

    try {
      final databasePath =
          '${directory.path}${Platform.pathSeparator}corsi_test.db';

      final database = await databaseFactoryFfi.openDatabase(databasePath);

      try {
        await database.execute('''
          CREATE TABLE corsi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            denominazione TEXT NOT NULL,
            durata_ore INTEGER DEFAULT 0,
            validita_anni INTEGER DEFAULT 0,
            modello_test_word_path TEXT,
            modello_gradimento_word_path TEXT,
            created_at TEXT,
            updated_at TEXT
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

        await database.insert('corsi', {
          'id': 2,
          'denominazione': 'ANTINCENDIO LIVELLO 2',
          'durata_ore': 8,
          'validita_anni': 5,
        });
      } finally {
        await database.close();
      }

      final corsi = await loadLanCorsiReadOnly(databasePath);

      expect(corsi.length, 2);

      expect(corsi.map((corso) => corso['denominazione']).toList(), [
        'ANTINCENDIO LIVELLO 2',
        'PONTEGGI - 28 ORE',
      ]);

      expect(corsi.last, {
        'id': 7,
        'denominazione': 'PONTEGGI - 28 ORE',
        'durata_ore': 28,
        'validita_anni': 4,
      });

      for (final corso in corsi) {
        expect(corso.keys.toSet(), {
          'id',
          'denominazione',
          'durata_ore',
          'validita_anni',
        });
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
