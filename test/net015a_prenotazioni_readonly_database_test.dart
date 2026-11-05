import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gestionale_sicurezza/services/lan_prenotazioni_readonly_service.dart';

void main() {
  test(
    'NET015A1 legge pagine, filtri, conteggi e attrezzature in sola lettura',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp('net015a_db_');
      final databasePath =
          '${directory.path}${Platform.pathSeparator}prenotazioni.db';

      try {
        final database = await databaseFactoryFfi.openDatabase(databasePath);
        try {
          await database.execute('''
          CREATE TABLE prenotazioni (
            id INTEGER PRIMARY KEY,
            discente_id INTEGER,
            impresa_id INTEGER,
            corso_id INTEGER,
            data TEXT,
            prot TEXT,
            aperto INTEGER,
            conferma INTEGER,
            ok INTEGER,
            registro INTEGER,
            seleziona INTEGER,
            docente_id INTEGER,
            aula_sede_id INTEGER,
            ente_attestato_id INTEGER
          )
        ''');
          await database.execute('''
          CREATE TABLE discenti (id INTEGER PRIMARY KEY, nome TEXT, cognome TEXT)
        ''');
          await database.execute('''
          CREATE TABLE imprese (id INTEGER PRIMARY KEY, intestazione TEXT)
        ''');
          await database.execute('''
          CREATE TABLE corsi (id INTEGER PRIMARY KEY, denominazione TEXT)
        ''');
          await database.execute('''
          CREATE TABLE docenti (
            id INTEGER PRIMARY KEY, nome TEXT, cognome TEXT, qualifica TEXT
          )
        ''');
          await database.execute('''
          CREATE TABLE aule_sedi (
            id INTEGER PRIMARY KEY, codice TEXT, denominazione TEXT, comune TEXT
          )
        ''');
          await database.execute('''
          CREATE TABLE enti_attestati (
            id INTEGER PRIMARY KEY, denominazione TEXT, tipo TEXT
          )
        ''');
          await database.execute('''
          CREATE TABLE attrezzature (id INTEGER PRIMARY KEY, denominazione TEXT)
        ''');
          await database.execute('''
          CREATE TABLE prenotazioni_attrezzature (
            prenotazione_id INTEGER,
            attrezzatura_id INTEGER,
            quantita REAL,
            note TEXT
          )
        ''');

          await database.insert('discenti', {
            'id': 1,
            'nome': 'Mario',
            'cognome': 'Rossi',
          });
          await database.insert('imprese', {
            'id': 1,
            'intestazione': 'IMPRESA TEST',
          });
          await database.insert('corsi', {
            'id': 1,
            'denominazione': 'PONTEGGI - 28 ORE',
          });
          await database.insert('docenti', {
            'id': 1,
            'nome': 'Lucia',
            'cognome': 'Bianchi',
            'qualifica': 'Formatrice',
          });
          await database.insert('aule_sedi', {
            'id': 1,
            'codice': 'ROMA',
            'denominazione': 'Sede Roma',
            'comune': 'Roma',
          });
          await database.insert('enti_attestati', {
            'id': 1,
            'denominazione': 'Ente test',
            'tipo': 'Ente',
          });
          await database.insert('attrezzature', {
            'id': 1,
            'denominazione': 'Imbracatura',
          });

          await database.insert('prenotazioni', {
            'id': 1,
            'discente_id': 1,
            'impresa_id': 1,
            'corso_id': 1,
            'data': '2026-11-05',
            'prot': 'P-001',
            'aperto': 1,
            'conferma': 0,
            'ok': 0,
            'registro': 0,
            'seleziona': 0,
            'docente_id': 1,
            'aula_sede_id': 1,
            'ente_attestato_id': 1,
          });
          await database.insert('prenotazioni', {
            'id': 2,
            'discente_id': 1,
            'impresa_id': 1,
            'corso_id': 1,
            'data': '2026-11-04',
            'prot': 'P-002',
            'aperto': 0,
            'conferma': 1,
            'ok': 0,
            'registro': 0,
            'seleziona': 0,
          });
          await database.insert('prenotazioni', {
            'id': 3,
            'impresa_id': 1,
            'corso_id': 1,
            'data': '2026-11-03',
            'prot': 'P-003',
            'aperto': 0,
            'conferma': 0,
            'ok': 0,
            'registro': 0,
            'seleziona': 0,
          });
          await database.insert('prenotazioni_attrezzature', {
            'prenotazione_id': 1,
            'attrezzatura_id': 1,
            'quantita': 2,
            'note': 'controllo',
          });
        } finally {
          await database.close();
        }

        final originalBytes = await File(databasePath).readAsBytes();

        final firstPage = await loadLanPrenotazioniReadOnly(
          databasePath,
          limit: 2,
          offset: 0,
        );
        final firstItems = firstPage['items'] as List<dynamic>;
        expect(firstItems.map((item) => item['id']).toList(), [3, 2]);
        expect(firstItems.first['discente_nome'], 'AZIENDALE / SENZA DISCENTE');

        final counts = firstPage['conteggi'] as Map<String, int>;
        expect(counts, {
          'tutte': 3,
          'aperte': 1,
          'registro': 0,
          'chiuse': 1,
          'da_fare': 1,
          'senza_discente': 1,
          'aziendali_senza_discente': 1,
          'senza_docente': 2,
          'recenti_da_sistemare': 2,
        });

        final openPage = await loadLanPrenotazioniReadOnly(
          databasePath,
          limit: 50,
          offset: 0,
          ricerca: 'Rossi',
          filtro: 'aperte',
        );
        final openItems = openPage['items'] as List<dynamic>;
        expect(openItems.length, 1);
        expect(openItems.single['id'], 1);
        expect(openItems.single['docente_nome'], 'Lucia');
        expect(openItems.single['aula_sede_codice'], 'ROMA');
        expect(openItems.single['ente_attestato_denominazione'], 'Ente test');
        expect(
          openItems.single['attrezzature_sintesi'],
          'Imbracatura x2 - controllo',
        );
        expect((openPage['conteggi'] as Map<String, int>)['tutte'], 2);

        final finalBytes = await File(databasePath).readAsBytes();
        expect(finalBytes, orderedEquals(originalBytes));
        expect(await File('$databasePath-wal').exists(), false);
        expect(await File('$databasePath-shm').exists(), false);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('NET015A1 rifiuta limiti, offset e filtri non validi', () async {
    await expectLater(
      loadLanPrenotazioniReadOnly('non-usato.db', limit: 101, offset: 0),
      throwsArgumentError,
    );
    await expectLater(
      loadLanPrenotazioniReadOnly('non-usato.db', limit: 50, offset: -1),
      throwsArgumentError,
    );
    await expectLater(
      loadLanPrenotazioniReadOnly(
        'non-usato.db',
        limit: 50,
        offset: 0,
        filtro: 'sconosciuto',
      ),
      throwsArgumentError,
    );
  });
}
