import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/lan_intestazione_azienda_readonly_service.dart';

void main() {
  test('NET014K legge intestazione aziendale in sola lettura', () async {
    sqfliteFfiInit();

    final directory = await Directory.systemTemp.createTemp(
      'net014_intestazione_test_',
    );

    try {
      final databasePath =
          '${directory.path}${Platform.pathSeparator}azienda_test.db';

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
          'note': 'INFORMAZIONE INTERNA RISERVATA',
        });

        await database.insert('dati_azienda', {
          'id': 2,
          'ragione_sociale': 'AZIENDA DA NON UTILIZZARE',
          'nome_commerciale': 'SECONDA AZIENDA',
        });
      } finally {
        await database.close();
      }

      final intestazione = await loadLanIntestazioneAziendaReadOnly(
        databasePath,
      );

      expect(intestazione, isNotNull);

      expect(intestazione!.keys.toSet(), {
        'titolo',
        'sottotitolo',
        'dettaglio',
      });

      expect(intestazione['titolo'], 'F&P Formazione e Privacy');

      expect(
        intestazione['sottotitolo'],
        'F&P S.r.l.s. - P.IVA 01234567890 - CF 01234567890',
      );

      expect(
        intestazione['dettaglio'],
        'Via dei Corsi 12 - 00100 Roma RM - '
        'Tel. 0600000000 - info@example.it - '
        'PEC fep@pec.it - https://example.it',
      );

      expect(intestazione.containsKey('logo_path'), false);
      expect(intestazione.containsKey('note'), false);

      expect(intestazione.toString().contains('RISERVATA'), false);

      expect(intestazione.toString().contains('riservato'), false);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
