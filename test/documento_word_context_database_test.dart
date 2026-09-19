import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gestionale_sicurezza/services/app_database.dart';
import 'package:gestionale_sicurezza/services/database_service.dart';

void main() {
  test(
    'DOC004 recupera il contesto Word completo dalla prenotazione',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final tempDir = await Directory.systemTemp.createTemp(
        'gestionale_sicurezza_doc004_',
      );

      final path =
          '${tempDir.path}${Platform.pathSeparator}doc004_context_test.db';

      try {
        await AppDatabase.instance.close();

        await File(path).create(recursive: true);

        AppDatabase.setDatabasePathOverrideForTesting(path);

        final db = await AppDatabase.instance.database;

        final impresaId = await db.insert('imprese', {
          'intestazione': 'Impresa Demo S.r.l.',
        });

        final discenteId = await db.insert('discenti', {
          'nome': 'Mario',
          'cognome': 'Rossi',
          'luogo_nascita': 'Roma',
          'data_nascita': '01/01/1980',
          'codice_fiscale': 'RSSMRA80A01H501U',
          'impresa_id': impresaId,
        });

        final corsoId = await db.insert('corsi', {
          'denominazione': 'Formazione lavoratori rischio alto',
          'durata_ore': 16,
          'validita_anni': 5,
        });

        final docenteId = await db.insert('docenti', {
          'nome': 'Luca',
          'cognome': 'Bianchi',
          'qualifica': 'Docente formatore',
        });

        final aulaSedeId = await db.insert('aule_sedi', {
          'denominazione': 'Aula Roma',
          'indirizzo': 'Via Esempio 10',
          'comune': 'Roma',
        });

        final prenotazioneId = await db.insert('prenotazioni', {
          'discente_id': discenteId,
          'impresa_id': impresaId,
          'corso_id': corsoId,
          'docente_id': docenteId,
          'aula_sede_id': aulaSedeId,
          'data': '19/09/2026',
          'prot': 'FP-2026-123',
        });

        final contesto = await DatabaseService.instance
            .getDocumentoWordContextByPrenotazioneId(prenotazioneId);

        expect(contesto, isNotNull);

        expect(contesto!.nome, 'Mario');
        expect(contesto.cognome, 'Rossi');
        expect(contesto.codiceFiscale, 'RSSMRA80A01H501U');
        expect(contesto.luogoNascita, 'Roma');
        expect(contesto.dataNascita, '01/01/1980');

        expect(contesto.corso, 'Formazione lavoratori rischio alto');
        expect(contesto.protocollo, 'FP-2026-123');
        expect(contesto.dataCorso, '19/09/2026');

        expect(contesto.sede, 'Aula Roma');
        expect(contesto.indirizzoSede, 'Via Esempio 10');
        expect(contesto.comuneSede, 'Roma');

        expect(contesto.docenteNome, 'Luca');
        expect(contesto.docenteCognome, 'Bianchi');
        expect(contesto.docenteQualifica, 'Docente formatore');

        expect(contesto.impresa, 'Impresa Demo S.r.l.');

        expect(contesto.placeholderValues['{{NOME_COGNOME}}'], 'Mario Rossi');

        expect(contesto.placeholderValues['{{DOCENTE}}'], 'Luca Bianchi');

        final inesistente = await DatabaseService.instance
            .getDocumentoWordContextByPrenotazioneId(999999999);

        expect(
          inesistente,
          isNull,
          reason: 'Una prenotazione inesistente deve restituire null.',
        );
      } finally {
        await AppDatabase.instance.close();

        AppDatabase.setDatabasePathOverrideForTesting(null);

        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    },
  );

  test(
    'DOC004 insertPrenotazione conserva docente sede ed ente attestato',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final tempDir = await Directory.systemTemp.createTemp(
        'gestionale_sicurezza_doc004_insert_',
      );

      final path =
          '${tempDir.path}${Platform.pathSeparator}doc004_insert_test.db';

      try {
        await AppDatabase.instance.close();

        await File(path).create(recursive: true);

        AppDatabase.setDatabasePathOverrideForTesting(path);

        final db = await AppDatabase.instance.database;

        final impresaId = await db.insert('imprese', {
          'intestazione': 'Impresa Insert Demo S.r.l.',
        });

        final discenteId = await db.insert('discenti', {
          'nome': 'Mario',
          'cognome': 'Verdi',
          'impresa_id': impresaId,
        });

        final corsoId = await db.insert('corsi', {
          'denominazione': 'Corso DOC004 insert',
        });

        final docenteId = await db.insert('docenti', {
          'nome': 'Luca',
          'cognome': 'Bianchi',
        });

        final aulaSedeId = await db.insert('aule_sedi', {
          'denominazione': 'Aula DOC004',
          'indirizzo': 'Via Test 10',
          'comune': 'Roma',
        });

        final enteAttestatoId = await db.insert('enti_attestati', {
          'denominazione': 'Ente DOC004',
        });

        final prenotazioneId = await DatabaseService.instance
            .insertPrenotazione({
              'discente_id': discenteId,
              'impresa_id': impresaId,
              'corso_id': corsoId,
              'docente_id': docenteId,
              'aula_sede_id': aulaSedeId,
              'ente_attestato_id': enteAttestatoId,
              'data': '19/09/2026',
              'prot': 'DOC004-INSERT',
              'aperto': 1,
              'conferma': 0,
              'registro': 0,
            });

        final rows = await db.query(
          'prenotazioni',
          columns: ['docente_id', 'aula_sede_id', 'ente_attestato_id'],
          where: 'id = ?',
          whereArgs: [prenotazioneId],
        );

        expect(rows, hasLength(1));

        expect(
          rows.first['docente_id'],
          docenteId,
          reason:
              'La nuova prenotazione deve conservare il docente selezionato.',
        );

        expect(
          rows.first['aula_sede_id'],
          aulaSedeId,
          reason: 'La nuova prenotazione deve conservare la sede selezionata.',
        );

        expect(
          rows.first['ente_attestato_id'],
          enteAttestatoId,
          reason:
              'La nuova prenotazione deve conservare l ente attestato selezionato.',
        );
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
