import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/lan_imprese_readonly_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'NET013 - carica imprese LAN in sola lettura con soli campi consentiti',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('net013_imprese_');

      final dbPath = '${tempDir.path}${Platform.pathSeparator}test.db';

      try {
        final db = await databaseFactoryFfi.openDatabase(dbPath);

        try {
          await db.execute('''
            CREATE TABLE imprese (
              id INTEGER PRIMARY KEY,
              intestazione TEXT NOT NULL,
              partita_iva TEXT,
              referente TEXT,
              created_at TEXT,
              updated_at TEXT,
              codice_fiscale TEXT,
              indirizzo TEXT,
              telefono TEXT,
              informativa_privacy_impresa_firmata INTEGER,
              data_firma_informativa_privacy_impresa TEXT,
              documento_privacy_impresa_path TEXT,
              note_privacy_impresa TEXT
            )
          ''');

          await db.insert('imprese', {
            'id': 2,
            'intestazione': 'Zeta S.r.l.',
            'partita_iva': '22222222222',
            'codice_fiscale': 'CFZETA',
            'indirizzo': 'Via Zeta 2',
            'telefono': '0200000002',
            'referente': 'Mario Rossi',
            'informativa_privacy_impresa_firmata': 1,
            'data_firma_informativa_privacy_impresa': '2026-01-01',
            'documento_privacy_impresa_path': r'C:\privacy\zeta.pdf',
            'note_privacy_impresa': 'NON ESPORRE',
          });

          await db.insert('imprese', {
            'id': 1,
            'intestazione': 'Alfa S.r.l.',
            'partita_iva': '11111111111',
            'codice_fiscale': 'CFALFA',
            'indirizzo': 'Via Alfa 1',
            'telefono': '0200000001',
            'referente': 'Luigi Bianchi',
            'informativa_privacy_impresa_firmata': 0,
            'documento_privacy_impresa_path': r'C:\privacy\alfa.pdf',
            'note_privacy_impresa': 'RISERVATO',
          });
        } finally {
          await db.close();
        }

        final result = await loadLanImpreseReadOnly(dbPath);

        expect(result, hasLength(2));

        expect(result.map((e) => e['intestazione']).toList(), <String>[
          'Alfa S.r.l.',
          'Zeta S.r.l.',
        ]);

        const expectedKeys = <String>{
          'id',
          'intestazione',
          'partita_iva',
          'codice_fiscale',
          'indirizzo',
          'telefono',
          'referente',
        };

        for (final impresa in result) {
          expect(impresa.keys.toSet(), expectedKeys);

          expect(
            impresa.containsKey('informativa_privacy_impresa_firmata'),
            isFalse,
          );

          expect(
            impresa.containsKey('data_firma_informativa_privacy_impresa'),
            isFalse,
          );

          expect(
            impresa.containsKey('documento_privacy_impresa_path'),
            isFalse,
          );

          expect(impresa.containsKey('note_privacy_impresa'), isFalse);

          expect(impresa.containsKey('created_at'), isFalse);

          expect(impresa.containsKey('updated_at'), isFalse);
        }

        expect(result.first, {
          'id': 1,
          'intestazione': 'Alfa S.r.l.',
          'partita_iva': '11111111111',
          'codice_fiscale': 'CFALFA',
          'indirizzo': 'Via Alfa 1',
          'telefono': '0200000001',
          'referente': 'Luigi Bianchi',
        });
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );
}
