import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_prenotazioni_permessi_service.dart';
import 'package:gestionale_sicurezza/services/lan_sessioni_utenti_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String _hashPassword(String password) {
  const salt = 'salt-test-sessioni';
  return '$salt:${sha256.convert(utf8.encode('$salt:$password'))}';
}

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late Database database;
  late LanSessioniUtentiService sessioni;
  late DateTime adesso;

  Future<LanSessioneUtenteCreata> apri() async {
    final sessione = await sessioni.apriSessione(
      username: ' mario.test ',
      password: 'Password-di-prova',
    );
    expect(sessione, isNotNull);
    return sessione!;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('net015c3b2b_sessioni_');
    database = await databaseFactoryFfi.openDatabase(
      '${directory.path}${Platform.pathSeparator}sessioni_test.db',
    );
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
    for (final ruolo in <Map<String, Object?>>[
      {'id': 1, 'nome': 'Amministratore', 'attivo': 1},
      {'id': 2, 'nome': 'Operatore', 'attivo': 1},
      {'id': 3, 'nome': 'Solo lettura', 'attivo': 1},
    ]) {
      await database.insert('ruoli_utenti', ruolo);
    }
    await database.insert('utenti_app', {
      'id': 10,
      'nome': 'Mario',
      'cognome': 'Prova',
      'username': 'Mario.Test',
      'password_hash': _hashPassword('Password-di-prova'),
      'ruolo_id': 2,
      'attivo': 1,
    });
    adesso = DateTime.utc(2026, 11, 6, 9);
    sessioni = LanSessioniUtentiService(
      database: database,
      durata: const Duration(minutes: 15),
      massimoSessioniAttive: 3,
      orologio: () => adesso,
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'NET015C3B2B emette token casuale e rilegge identita senza hash',
    () async {
      final creata = await apri();
      expect(creata.token, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(creata.scadenzaUtc, DateTime.utc(2026, 11, 6, 9, 15));
      expect(sessioni.numeroSessioniAttive, 1);

      final identita = await sessioni.verificaSessione(creata.token);
      expect(identita, isNotNull);
      expect(identita!.utente.id, 10);
      expect(identita.utente.username, 'Mario.Test');
      expect(identita.utente.passwordHash, isNull);
      expect(identita.ruolo.nome, 'Operatore');
    },
  );

  test('NET015C3B2B non crea sessioni con credenziali errate', () async {
    expect(
      await sessioni.apriSessione(
        username: 'Mario.Test',
        password: 'password-errata',
      ),
      isNull,
    );
    expect(
      await sessioni.apriSessione(
        username: 'sconosciuto',
        password: 'Password-di-prova',
      ),
      isNull,
    );
    expect(sessioni.numeroSessioniAttive, 0);
  });

  test('NET015C3B2B sessioni distinte e revoca selettiva', () async {
    final prima = await apri();
    final seconda = await apri();
    expect(prima.token, isNot(seconda.token));
    expect(sessioni.numeroSessioniAttive, 2);
    expect(sessioni.revocaSessione(prima.token), isTrue);
    expect(sessioni.revocaSessione(prima.token), isFalse);
    expect(await sessioni.verificaSessione(prima.token), isNull);
    expect(await sessioni.verificaSessione(seconda.token), isNotNull);
  });

  test('NET015C3B2B scade esattamente al limite e libera spazio', () async {
    final creata = await apri();
    adesso = adesso.add(const Duration(minutes: 14, seconds: 59));
    expect(await sessioni.verificaSessione(creata.token), isNotNull);
    adesso = adesso.add(const Duration(seconds: 1));
    expect(await sessioni.verificaSessione(creata.token), isNull);
    expect(sessioni.numeroSessioniAttive, 0);
    expect(await sessioni.verificaSessione(creata.token), isNull);
    expect(
      await sessioni.apriSessione(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      ),
      isNotNull,
    );
  });

  test('NET015C3B2B rifiuta token assenti, alterati o malformati', () async {
    final creata = await apri();
    expect(await sessioni.verificaSessione(''), isNull);
    expect(await sessioni.verificaSessione('Bearer ${creata.token}'), isNull);
    expect(await sessioni.verificaSessione('${creata.token}x'), isNull);
    expect(await sessioni.verificaSessione('A'.padRight(43, 'A')), isNull);
    expect(await sessioni.verificaSessione(creata.token), isNotNull);
    expect(sessioni.revocaSessione('A'.padRight(500, 'A')), isFalse);
  });

  test('NET015C3B2B nega eliminazione a Operatore', () async {
    final creata = await apri();
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: creata.token,
        operazione: LanOperazionePrenotazioni.inserire,
      ),
      isTrue,
    );
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: creata.token,
        operazione: LanOperazionePrenotazioni.eliminare,
      ),
      isFalse,
    );
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: 'token-sbagliato',
        operazione: LanOperazionePrenotazioni.consultare,
      ),
      isFalse,
    );
  });

  test('NET015C3B2B disattivazione utente invalida subito il token', () async {
    final creata = await apri();
    await database.update(
      'utenti_app',
      {'attivo': 0},
      where: 'id = ?',
      whereArgs: [10],
    );
    expect(await sessioni.verificaSessione(creata.token), isNull);
    await database.update(
      'utenti_app',
      {'attivo': 1},
      where: 'id = ?',
      whereArgs: [10],
    );
    expect(await sessioni.verificaSessione(creata.token), isNull);
    expect(sessioni.numeroSessioniAttive, 0);
  });

  test('NET015C3B2B disattivazione ruolo invalida subito il token', () async {
    final creata = await apri();
    await database.update(
      'ruoli_utenti',
      {'attivo': 0},
      where: 'id = ?',
      whereArgs: [2],
    );
    expect(await sessioni.verificaSessione(creata.token), isNull);
    expect(sessioni.numeroSessioniAttive, 0);
  });

  test('NET015C3B2B cambio ruolo non eleva una sessione esistente', () async {
    final creata = await apri();
    await database.update(
      'utenti_app',
      {'ruolo_id': 1},
      where: 'id = ?',
      whereArgs: [10],
    );
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: creata.token,
        operazione: LanOperazionePrenotazioni.eliminare,
      ),
      isFalse,
    );
    expect(await sessioni.verificaSessione(creata.token), isNull);
    final nuova = await apri();
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: nuova.token,
        operazione: LanOperazionePrenotazioni.eliminare,
      ),
      isTrue,
    );
  });

  test(
    'NET015C3B2B rinomina ruolo o username richiede nuovo accesso',
    () async {
      final prima = await apri();
      await database.update(
        'ruoli_utenti',
        {'nome': 'Amministratore'},
        where: 'id = ?',
        whereArgs: [2],
      );
      expect(await sessioni.verificaSessione(prima.token), isNull);

      final seconda = await apri();
      await database.update(
        'utenti_app',
        {'username': 'Mario.Aggiornato'},
        where: 'id = ?',
        whereArgs: [10],
      );
      expect(await sessioni.verificaSessione(seconda.token), isNull);
    },
  );

  test('NET015C3B2B applica i permessi di Solo lettura', () async {
    await database.update(
      'utenti_app',
      {'ruolo_id': 3},
      where: 'id = ?',
      whereArgs: [10],
    );
    final creata = await apri();
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: creata.token,
        operazione: LanOperazionePrenotazioni.consultare,
      ),
      isTrue,
    );
    expect(
      await sessioni.puoEseguirePrenotazioni(
        token: creata.token,
        operazione: LanOperazionePrenotazioni.inserire,
      ),
      isFalse,
    );
  });

  test('NET015C3B2B revoca massiva e riavvio invalidano i token', () async {
    final prima = await apri();
    final seconda = await apri();
    expect(sessioni.revocaSessioniUtente(10), 2);
    expect(await sessioni.verificaSessione(prima.token), isNull);
    expect(await sessioni.verificaSessione(seconda.token), isNull);

    final terza = await apri();
    final nuovoGestore = LanSessioniUtentiService(database: database);
    expect(await nuovoGestore.verificaSessione(terza.token), isNull);
    sessioni.revocaTutteLeSessioni();
    expect(sessioni.numeroSessioniAttive, 0);
  });

  test('NET015C3B2B applica il limite massimo delle sessioni', () async {
    final prima = await apri();
    await apri();
    await apri();
    expect(sessioni.numeroSessioniAttive, 3);
    expect(
      await sessioni.apriSessione(
        username: 'Mario.Test',
        password: 'Password-di-prova',
      ),
      isNull,
    );
    expect(sessioni.revocaSessione(prima.token), isTrue);
    expect(await apri(), isNotNull);
  });

  test('NET015C3B2B non modifica utenti o ruoli in SQLite', () async {
    final prima = await database.query('utenti_app');
    final ruoliPrima = await database.query('ruoli_utenti');
    final creata = await apri();
    await sessioni.verificaSessione(creata.token);
    await sessioni.puoEseguirePrenotazioni(
      token: creata.token,
      operazione: LanOperazionePrenotazioni.consultare,
    );
    sessioni.revocaSessione(creata.token);
    expect(await database.query('utenti_app'), prima);
    expect(await database.query('ruoli_utenti'), ruoliPrima);
  });

  test('NET015C3B2B rifiuta configurazioni pericolose', () {
    expect(
      () => LanSessioniUtentiService(database: database, durata: Duration.zero),
      throwsArgumentError,
    );
    expect(
      () => LanSessioniUtentiService(
        database: database,
        massimoSessioniAttive: 0,
      ),
      throwsArgumentError,
    );
  });
}
