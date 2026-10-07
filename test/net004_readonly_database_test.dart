import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/lan_readonly_database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('NET004 SQLite LAN viene aperto in sola lettura reale', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'gestionale_sicurezza_net004_',
    );

    final dbPath = '${tempDir.path}${Platform.pathSeparator}net004_readonly.db';

    final writableDatabase = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(singleInstance: false),
    );

    await writableDatabase.execute('''
      CREATE TABLE probe (
        id INTEGER PRIMARY KEY,
        valore TEXT NOT NULL
      )
      ''');

    await writableDatabase.insert('probe', {'id': 1, 'valore': 'origine'});

    await writableDatabase.close();

    final readOnlyDatabase = await openLanReadOnlyDatabase(dbPath);

    try {
      final rows = await readOnlyDatabase.query('probe', orderBy: 'id');

      expect(rows.length, 1);

      expect(rows.first['valore'], 'origine');

      await expectLater(
        readOnlyDatabase.insert('probe', {'id': 2, 'valore': 'vietato'}),
        throwsA(isA<DatabaseException>()),
      );

      final rowsAfterWriteAttempt = await readOnlyDatabase.query(
        'probe',
        orderBy: 'id',
      );

      expect(rowsAfterWriteAttempt.length, 1);

      expect(rowsAfterWriteAttempt.first['valore'], 'origine');
    } finally {
      await readOnlyDatabase.close();

      await tempDir.delete(recursive: true);
    }
  });
}
