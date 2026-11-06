import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_autenticazione_utenti_service.dart';
import 'package:gestionale_sicurezza/services/lan_prenotazioni_permessi_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String _hashPassword(String password) {
  const salt = 'salt-solamente-per-test';
  return '$salt:${sha256.convert(utf8.encode('$salt:$password'))}';
}

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late Database database;
  late LanAutenticazioneUtentiService autenticazione;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('net015c3b2a_auth_');
    final percorso =
        '${directory.path}${Platform.pathSeparator}autenticazione_test.db';
    database = await databaseFactoryFfi.openDatabase(percorso);
    await database.execute('''
      CREATE TABLE ruoli_utenti (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        attivo INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await database.execute('''
      CREATE TABLE utenti_app (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        cognome TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        ruolo_id INTEGER,
        attivo INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await database.insert('ruoli_utenti', {
      'id': 1,
      'nome': 'Amministratore',
      'attivo': 1,
    });
    await database.insert('ruoli_utenti', {
      'id': 2,
      'nome': 'Operatore',
      'attivo': 1,
    });
    await database.insert('ruoli_utenti', {
      'id': 3,
      'nome': 'Solo lettura',
      'attivo': 1,
    });
    await database.insert('utenti_app', {
      'id': 10,
      'nome': 'Mario',
      'cognome': 'Prova',
      'username': 'Mario.Test',
      'password_hash': _hashPassword('Password-di-prova'),
      'ruolo_id': 2,
      'attivo': 1,
    });
    autenticazione = LanAutenticazioneUtentiService(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('NET015C3B2A identifica utente e ruolo dal database centrale', () async {
    final identita = await autenticazione.verificaCredenziali(
      username: ' mario.test ',
      password: 'Password-di-prova',
    );

    expect(identita, isNotNull);
    expect(identita!.utente.id, 10);
    expect(identita.utente.username, 'Mario.Test');
    expect(identita.ruolo.id, 2);
    expect(identita.ruolo.nome, 'Operatore');
    expect(identita.utente.passwordHash, isNull);
  });

  test('NET015C3B2A nega password errata e utente sconosciuto', () async {
    expect(
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'password-sbagliata',
      ),
      isNull,
    );
    expect(
      await autenticazione.verificaCredenziali(
        username: 'sconosciuto',
        password: 'Password-di-prova',
      ),
      isNull,
    );
  });

  test('NET015C3B2A nega credenziali vuote', () async {
    expect(
      await autenticazione.verificaCredenziali(
        username: ' ',
        password: 'Password-di-prova',
      ),
      isNull,
    );
    expect(
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: ' ',
      ),
      isNull,
    );
  });

  test('NET015C3B2A nega utente e ruolo disattivati', () async {
    await database.update(
      'utenti_app',
      {'attivo': 0},
      where: 'id = ?',
      whereArgs: [10],
    );
    expect(
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      ),
      isNull,
    );
    await database.update(
      'utenti_app',
      {'attivo': 1},
      where: 'id = ?',
      whereArgs: [10],
    );
    await database.update(
      'ruoli_utenti',
      {'attivo': 0},
      where: 'id = ?',
      whereArgs: [2],
    );
    expect(
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      ),
      isNull,
    );
  });

  test('NET015C3B2A nega ruolo assente e hash non valido', () async {
    await database.update(
      'utenti_app',
      {'ruolo_id': 999},
      where: 'id = ?',
      whereArgs: [10],
    );
    expect(
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      ),
      isNull,
    );
    await database.update(
      'utenti_app',
      {'ruolo_id': 2, 'password_hash': 'formato-errato'},
      where: 'id = ?',
      whereArgs: [10],
    );
    expect(
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      ),
      isNull,
    );
  });

  test('NET015C3B2A identita verificata applica matrice permessi', () async {
    final identita = await autenticazione.verificaCredenziali(
      username: 'Mario.Test',
      password: 'Password-di-prova',
    );
    expect(identita, isNotNull);

    const permessi = LanPrenotazioniPermessiService();
    expect(
      permessi.puoEseguire(
        utente: identita!.utente,
        ruolo: identita.ruolo,
        operazione: LanOperazionePrenotazioni.inserire,
      ),
      isTrue,
    );
    expect(
      permessi.puoEseguire(
        utente: identita.utente,
        ruolo: identita.ruolo,
        operazione: LanOperazionePrenotazioni.eliminare,
      ),
      isFalse,
    );
  });

  test(
    'NET015C3B2A non modifica i record del database durante il login',
    () async {
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      );
      await autenticazione.verificaCredenziali(
        username: 'Mario.Test',
        password: 'password-sbagliata',
      );
      expect(await database.query('utenti_app'), hasLength(1));
      expect(await database.query('ruoli_utenti'), hasLength(3));
    },
  );
}
