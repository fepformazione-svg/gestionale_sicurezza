import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/aula_sede.dart';
import '../models/attrezzatura.dart';
import '../models/ente_attestato.dart';
import '../models/registro_presenza.dart';
import '../models/ruolo_utente.dart';
import '../models/utente_app.dart';
import '../models/registro_trattamento.dart';
import '../models/registro_trattamento_log.dart';
import '../models/data_breach.dart';
import '../models/data_breach_log.dart';
import '../models/consenso_privacy.dart';
import '../models/consenso_privacy_log.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  static const String databaseName = 'gestionale_sicurezza.db';

  Future<Database> get database async {
    if (_database != null) return _database!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final documentsPath = Platform.environment['USERPROFILE'] != null
        ? join(
            Platform.environment['USERPROFILE']!,
            'Documents',
            'Gestionale Sicurezza',
          )
        : await databaseFactory.getDatabasesPath();

    if (!Directory(documentsPath).existsSync()) {
      Directory(documentsPath).createSync(recursive: true);
    }

    final path = join(documentsPath, databaseName);

    debugPrint('DATABASE PATH: $path');

    _database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 10,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );

    return _database!;
  }

  Future<void> createConsensiPrivacyTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS consensi_privacy (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo_soggetto TEXT NOT NULL DEFAULT 'Altro',
      soggetto_id INTEGER,
      nominativo TEXT NOT NULL,
      codice_fiscale TEXT,
      email TEXT,
      telefono TEXT,
      finalita TEXT NOT NULL,
      base_giuridica TEXT,
      versione_informativa TEXT,
      canale_raccolta TEXT,
      stato TEXT NOT NULL DEFAULT 'ATTIVO',
      data_consenso TEXT NOT NULL,
      data_revoca TEXT,
      data_scadenza TEXT,
      documento_riferimento TEXT,
      note TEXT,
      soggetto_minorenne INTEGER NOT NULL DEFAULT 0,
      consenso_prestato_da TEXT NOT NULL DEFAULT 'discente',
      genitore_tutore_nome TEXT,
genitore_tutore_codice_fiscale TEXT,
genitore_tutore_qualifica TEXT,
data_fine_conservazione TEXT,
motivo_retention TEXT,
retention_bloccata INTEGER NOT NULL DEFAULT 0,
note_retention TEXT,
created_at TEXT NOT NULL,
updated_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS consensi_privacy_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      consenso_privacy_id INTEGER,
      azione TEXT NOT NULL,
      descrizione TEXT NOT NULL,
      dati_prima TEXT,
      dati_dopo TEXT,
      utente TEXT NOT NULL,
      data_ora TEXT NOT NULL,
      FOREIGN KEY (consenso_privacy_id) REFERENCES consensi_privacy (id) ON DELETE SET NULL
    )
  ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _ensureAllColumns(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createTables(db);
    await _ensureAllColumns(db);
    await _createIndexes(db);
  }

  Future<void> _onOpen(Database db) async {
    await _createTables(db);
    await _ensureAllColumns(db);
    await _createIndexes(db);
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS imprese (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intestazione TEXT NOT NULL,
        partita_iva TEXT,
        codice_fiscale TEXT,
        indirizzo TEXT,
        telefono TEXT,
        referente TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS discenti (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    cognome TEXT DEFAULT '',
    luogo_nascita TEXT,
    data_nascita TEXT,
    codice_fiscale TEXT,
    impresa_id INTEGER,
    visita_medica_svolta INTEGER DEFAULT 0,
    data_visita_medica TEXT,
    scadenza_visita_medica TEXT,
    informativa_privacy_firmata INTEGER DEFAULT 0,
    data_firma_informativa_privacy TEXT,
    documento_privacy_discente_path TEXT,
    note_privacy_discente TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT,
    FOREIGN KEY (impresa_id) REFERENCES imprese(id)
  )
''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS corsi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        denominazione TEXT NOT NULL,
        durata_ore INTEGER DEFAULT 0,
        validita_anni INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prenotazioni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discente_id INTEGER,
        impresa_id INTEGER,
        corso_id INTEGER,
        data TEXT,
        prot TEXT,
        aperto INTEGER DEFAULT 1,
        conferma INTEGER DEFAULT 0,
        ok INTEGER DEFAULT 0,
        registro INTEGER DEFAULT 0,
        seleziona INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (discente_id) REFERENCES discenti(id),
        FOREIGN KEY (impresa_id) REFERENCES imprese(id),
        FOREIGN KEY (corso_id) REFERENCES corsi(id)
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS registri_presenze (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prenotazione_id INTEGER NOT NULL,
    discente_id INTEGER,
    data_lezione TEXT,
    ora_inizio TEXT,
    ora_fine TEXT,
    presente INTEGER DEFAULT 0,
    firma_discente_path TEXT,
    firma_docente_path TEXT,
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prenotazione_id) REFERENCES prenotazioni(id),
    FOREIGN KEY (discente_id) REFERENCES discenti(id)
  )
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_registri_presenze_prenotazione
  ON registri_presenze (prenotazione_id)
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_registri_presenze_discente
  ON registri_presenze (discente_id)
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_registri_presenze_data_lezione
  ON registri_presenze (data_lezione)
''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS diario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prenotazione_id INTEGER,
        discente_id INTEGER,
        impresa_id INTEGER,
        corso_id INTEGER,
        data TEXT,
        prot TEXT,
        scadenza TEXT,
        da_fatturare INTEGER DEFAULT 0,
        fattura TEXT,
        invio TEXT,
        rinnovo TEXT,
        pdf_attestato TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (prenotazione_id) REFERENCES prenotazioni(id),
        FOREIGN KEY (discente_id) REFERENCES discenti(id),
        FOREIGN KEY (impresa_id) REFERENCES imprese(id),
        FOREIGN KEY (corso_id) REFERENCES corsi(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS scadenze (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diario_id INTEGER,
        discente_id INTEGER,
        impresa_id INTEGER,
        corso_id INTEGER,
        data_corso TEXT,
        data_scadenza TEXT,
        stato TEXT,
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (diario_id) REFERENCES diario(id),
        FOREIGN KEY (discente_id) REFERENCES discenti(id),
        FOREIGN KEY (impresa_id) REFERENCES imprese(id),
        FOREIGN KEY (corso_id) REFERENCES corsi(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pdf_documenti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diario_id INTEGER,
        tipo_documento TEXT,
        percorso_pdf TEXT NOT NULL,
        attivo INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (diario_id) REFERENCES diario(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prezzario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        impresa_id INTEGER,
        corso_id INTEGER,
        prezzo REAL DEFAULT 0,
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (impresa_id) REFERENCES imprese(id),
        FOREIGN KEY (corso_id) REFERENCES corsi(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medici_strutture (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT DEFAULT 'Medico',
        denominazione TEXT NOT NULL,
        referente TEXT,
        telefono TEXT,
        email TEXT,
        indirizzo TEXT,
        note TEXT,
        attivo INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS visite_mediche (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discente_id INTEGER NOT NULL,
        medico_struttura_id INTEGER,
        data_visita TEXT,
        data_scadenza TEXT,
        esito TEXT,
        giudizio TEXT,
        note TEXT,
        documento_path TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dati_azienda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS docenti (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    cognome TEXT NOT NULL,
    telefono TEXT,
    email TEXT,
    codice_fiscale TEXT,
    qualifica TEXT,
    note TEXT,
    attivo INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS aule_sedi (
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

    await db.execute('''
  CREATE TABLE IF NOT EXISTS attrezzature (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    denominazione TEXT NOT NULL,
    categoria TEXT NOT NULL DEFAULT 'Generica',
    codice TEXT,
    descrizione TEXT,
    quantita INTEGER DEFAULT 1,
    unita_misura TEXT DEFAULT 'pz',
    attiva INTEGER DEFAULT 1,
    note TEXT,
    created_at TEXT,
    updated_at TEXT
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS prenotazioni_attrezzature (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prenotazione_id INTEGER NOT NULL,
    attrezzatura_id INTEGER NOT NULL,
    quantita REAL DEFAULT 1,
    note TEXT,
    created_at TEXT,
    updated_at TEXT,
    UNIQUE(prenotazione_id, attrezzatura_id)
  )
''');

    await _ensureColumns(db, 'prenotazioni_attrezzature', {
      'quantita': 'REAL DEFAULT 1',
      'note': 'TEXT',
    });

    await db.execute('''
      CREATE TABLE IF NOT EXISTS enti_attestati (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        denominazione TEXT NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'Ente',
        codice_accreditamento TEXT,
        referente TEXT,
        telefono TEXT,
        email TEXT,
        pec TEXT,
        indirizzo TEXT,
        comune TEXT,
        note TEXT,
        attivo INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS privacy_gdpr (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titolo TEXT NOT NULL,
    titolare_trattamento TEXT DEFAULT '',
    referente_privacy TEXT DEFAULT '',
    base_giuridica TEXT DEFAULT '',
    finalita_trattamento TEXT DEFAULT '',
    categorie_dati TEXT DEFAULT '',
    periodo_conservazione TEXT DEFAULT '',
    misure_sicurezza TEXT DEFAULT '',
    note TEXT DEFAULT '',
    attivo INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ruoli_utenti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        descrizione TEXT,
        attivo INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS utenti_app (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cognome TEXT NOT NULL,
        email TEXT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        ruolo_id INTEGER,
        attivo INTEGER NOT NULL DEFAULT 1,
        ultimo_accesso TEXT,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (ruolo_id) REFERENCES ruoli_utenti (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS log_accessi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utente_id INTEGER,
        username TEXT,
        esito TEXT NOT NULL,
        messaggio TEXT,
        data_ora TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        dispositivo TEXT,
        FOREIGN KEY (utente_id) REFERENCES utenti_app (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utente_id INTEGER,
        username TEXT,
        modulo TEXT NOT NULL,
        azione TEXT NOT NULL,
        descrizione TEXT,
        record_id INTEGER,
        data_ora TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (utente_id) REFERENCES utenti_app (id)
      )
    ''');
    await _creaTabellaRegistroTrattamenti(db);
    await _createRegistroDataBreachTable(db);
    await createConsensiPrivacyTable(db);
  }

  Future<void> _createRegistroDataBreachTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS registro_data_breach (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_evento TEXT NOT NULL DEFAULT '',
      data_rilevazione TEXT NOT NULL DEFAULT '',
      descrizione TEXT NOT NULL DEFAULT '',
      categorie_dati TEXT NOT NULL DEFAULT '',
      categorie_interessati TEXT NOT NULL DEFAULT '',
      numero_interessati TEXT NOT NULL DEFAULT '',
      conseguenze TEXT NOT NULL DEFAULT '',
      misure_adottate TEXT NOT NULL DEFAULT '',
      rischio TEXT NOT NULL DEFAULT 'Da valutare',
      notificato_garante INTEGER NOT NULL DEFAULT 0,
      data_notifica_garante TEXT NOT NULL DEFAULT '',
      comunicato_interessati INTEGER NOT NULL DEFAULT 0,
      data_comunicazione_interessati TEXT NOT NULL DEFAULT '',
      motivazione_mancata_notifica TEXT NOT NULL DEFAULT '',
      responsabile_interno TEXT NOT NULL DEFAULT '',
      stato TEXT NOT NULL DEFAULT 'Aperto',
      note TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL DEFAULT ''
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS data_breach_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_breach_id INTEGER,
      azione TEXT NOT NULL DEFAULT '',
      descrizione TEXT NOT NULL DEFAULT '',
      dati_prima TEXT,
      dati_dopo TEXT,
      utente TEXT,
      data_ora TEXT NOT NULL DEFAULT ''
    )
  ''');
  }

  Future<List<DataBreach>> getDataBreach({
    String? filtroStato,
    String? ricerca,
  }) async {
    final db = await database;

    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (filtroStato != null &&
        filtroStato.trim().isNotEmpty &&
        filtroStato != 'Tutti') {
      whereParts.add('stato = ?');
      whereArgs.add(filtroStato);
    }

    final testoRicerca = ricerca?.trim() ?? '';
    if (testoRicerca.isNotEmpty) {
      whereParts.add('''
      (
        descrizione LIKE ?
        OR categorie_dati LIKE ?
        OR categorie_interessati LIKE ?
        OR conseguenze LIKE ?
        OR misure_adottate LIKE ?
        OR rischio LIKE ?
        OR responsabile_interno LIKE ?
        OR stato LIKE ?
        OR note LIKE ?
      )
    ''');

      final like = '%$testoRicerca%';
      whereArgs.addAll([like, like, like, like, like, like, like, like, like]);
    }

    final maps = await db.query(
      'registro_data_breach',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    return maps.map(DataBreach.fromMap).toList();
  }

  Future<int> insertDataBreach(DataBreach dataBreach) async {
    final db = await database;
    final map = dataBreach.toMap();
    map.remove('id');

    return db.insert(
      'registro_data_breach',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDataBreach(DataBreach dataBreach) async {
    final db = await database;

    if (dataBreach.id == null) {
      throw Exception('ID data breach mancante per aggiornamento');
    }

    return db.update(
      'registro_data_breach',
      dataBreach.toMap(),
      where: 'id = ?',
      whereArgs: [dataBreach.id],
    );
  }

  Future<int> deleteDataBreach(int id) async {
    final db = await database;

    return db.delete('registro_data_breach', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDataBreachLog(DataBreachLog log) async {
    final db = await database;

    return db.insert('data_breach_log', log.toMap());
  }

  Future<List<DataBreachLog>> getDataBreachLog({int? dataBreachId}) async {
    final db = await database;

    final maps = await db.query(
      'data_breach_log',
      where: dataBreachId != null ? 'data_breach_id = ?' : null,
      whereArgs: dataBreachId != null ? [dataBreachId] : null,
      orderBy: 'data_ora DESC, id DESC',
    );

    return maps.map((map) => DataBreachLog.fromMap(map)).toList();
  }

  Future<void> registraLogDataBreach({
    int? dataBreachId,
    required String azione,
    required String descrizione,
    String? datiPrima,
    String? datiDopo,
    String? utente,
  }) async {
    await insertDataBreachLog(
      DataBreachLog(
        dataBreachId: dataBreachId,
        azione: azione,
        descrizione: descrizione,
        datiPrima: datiPrima,
        datiDopo: datiDopo,
        utente: utente,
        dataOra: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<List<RegistroTrattamento>> getRegistroTrattamenti({
    String ricerca = '',
    bool soloAttivi = false,
  }) async {
    final db = await database;

    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (soloAttivi) {
      whereParts.add('attivo = 1');
    }

    final testoRicerca = ricerca.trim();
    if (testoRicerca.isNotEmpty) {
      final like = '%$testoRicerca%';

      whereParts.add('''
        (
          nome_trattamento LIKE ? OR
          finalita LIKE ? OR
          base_giuridica LIKE ? OR
          categorie_interessati LIKE ? OR
          categorie_dati LIKE ? OR
          categorie_destinatari LIKE ? OR
          responsabile_interno LIKE ? OR
          note LIKE ?
        )
      ''');

      whereArgs.addAll([like, like, like, like, like, like, like, like]);
    }

    final maps = await db.query(
      'registro_trattamenti',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'attivo DESC, nome_trattamento COLLATE NOCASE ASC',
    );

    return maps.map(RegistroTrattamento.fromMap).toList();
  }

  Future<RegistroTrattamento?> getRegistroTrattamentoById(int id) async {
    final db = await database;

    final maps = await db.query(
      'registro_trattamenti',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return RegistroTrattamento.fromMap(maps.first);
  }

  Future<int> insertRegistroTrattamento(RegistroTrattamento trattamento) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = trattamento.copyWith(createdAt: now, updatedAt: now).toMap();

    data.remove('id');

    return db.insert(
      'registro_trattamenti',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateRegistroTrattamento(RegistroTrattamento trattamento) async {
    final db = await database;

    if (trattamento.id == null) {
      throw ArgumentError('Impossibile aggiornare un trattamento senza id.');
    }

    final data = trattamento
        .copyWith(updatedAt: DateTime.now().toIso8601String())
        .toMap();

    data.remove('id');

    return db.update(
      'registro_trattamenti',
      data,
      where: 'id = ?',
      whereArgs: [trattamento.id],
    );
  }

  Future<int> deleteRegistroTrattamento(int id) async {
    final db = await database;

    return db.delete('registro_trattamenti', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> cambiaStatoRegistroTrattamento({
    required int id,
    required bool attivo,
  }) async {
    final db = await database;

    return db.update(
      'registro_trattamenti',
      {
        'attivo': attivo ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertRegistroTrattamentoLog(RegistroTrattamentoLog log) async {
    final db = await database;

    return db.insert('registro_trattamenti_log', log.toMap());
  }

  Future<List<RegistroTrattamentoLog>> getRegistroTrattamentiLog({
    int? trattamentoId,
  }) async {
    final db = await database;

    final maps = await db.query(
      'registro_trattamenti_log',
      where: trattamentoId != null ? 'trattamento_id = ?' : null,
      whereArgs: trattamentoId != null ? [trattamentoId] : null,
      orderBy: 'data_ora DESC, id DESC',
    );

    return maps.map((map) => RegistroTrattamentoLog.fromMap(map)).toList();
  }

  Future<void> registraLogRegistroTrattamento({
    int? trattamentoId,
    required String azione,
    required String descrizione,
    String? datiPrima,
    String? datiDopo,
    String? utente,
  }) async {
    await insertRegistroTrattamentoLog(
      RegistroTrattamentoLog(
        trattamentoId: trattamentoId,
        azione: azione,
        descrizione: descrizione,
        datiPrima: datiPrima,
        datiDopo: datiDopo,
        utente: utente,
        dataOra: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _ensureAllColumns(Database db) async {
    await _ensureColumns(db, 'imprese', {
      'partita_iva': 'TEXT',
      'codice_fiscale': 'TEXT',
      'indirizzo': 'TEXT',
      'telefono': 'TEXT',
      'referente': 'TEXT',
      'informativa_privacy_impresa_firmata': 'INTEGER DEFAULT 0',
      'data_firma_informativa_privacy_impresa': 'TEXT',
      'documento_privacy_impresa_path': 'TEXT',
      'note_privacy_impresa': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'discenti', {
      'cognome': "TEXT DEFAULT ''",
      'luogo_nascita': 'TEXT',
      'data_nascita': 'TEXT',
      'codice_fiscale': 'TEXT',
      'impresa_id': 'INTEGER',
      'visita_medica_svolta': 'INTEGER DEFAULT 0',
      'data_visita_medica': 'TEXT',
      'scadenza_visita_medica': 'TEXT',
      'informativa_privacy_firmata': 'INTEGER DEFAULT 0',
      'data_firma_informativa_privacy': 'TEXT',
      'documento_privacy_discente_path': 'TEXT',
      'note_privacy_discente': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'corsi', {
      'durata_ore': 'INTEGER DEFAULT 0',
      'validita_anni': 'INTEGER DEFAULT 0',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'prenotazioni', {
      'discente_id': 'INTEGER',
      'impresa_id': 'INTEGER',
      'corso_id': 'INTEGER',
      'data': 'TEXT',
      'prot': 'TEXT',
      'aperto': 'INTEGER DEFAULT 1',
      'conferma': 'INTEGER DEFAULT 0',
      'ok': 'INTEGER DEFAULT 0',
      'registro': 'INTEGER DEFAULT 0',
      'seleziona': 'INTEGER DEFAULT 0',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
      'docente_id': 'INTEGER',
      'aula_sede_id': 'INTEGER',
      'ente_attestato_id': 'INTEGER',
    });

    await _ensureColumns(db, 'diario', {
      'prenotazione_id': 'INTEGER',
      'discente_id': 'INTEGER',
      'impresa_id': 'INTEGER',
      'corso_id': 'INTEGER',
      'data': 'TEXT',
      'prot': 'TEXT',
      'scadenza': 'TEXT',
      'da_fatturare': 'INTEGER DEFAULT 0',
      'fattura': 'TEXT',
      'invio': 'TEXT',
      'rinnovo': 'TEXT',
      'pdf_attestato': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'scadenze', {
      'diario_id': 'INTEGER',
      'discente_id': 'INTEGER',
      'impresa_id': 'INTEGER',
      'corso_id': 'INTEGER',
      'data_corso': 'TEXT',
      'data_scadenza': 'TEXT',
      'stato': 'TEXT',
      'note': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'pdf_documenti', {
      'diario_id': 'INTEGER',
      'tipo_documento': 'TEXT',
      'percorso_pdf': 'TEXT',
      'attivo': 'INTEGER DEFAULT 1',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'prezzario', {
      'impresa_id': 'INTEGER',
      'corso_id': 'INTEGER',
      'prezzo': 'REAL DEFAULT 0',
      'note': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'medici_strutture', {
      'tipo': "TEXT DEFAULT 'Medico'",
      'denominazione': 'TEXT',
      'referente': 'TEXT',
      'telefono': 'TEXT',
      'email': 'TEXT',
      'indirizzo': 'TEXT',
      'note': 'TEXT',
      'attivo': 'INTEGER DEFAULT 1',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'visite_mediche', {
      'discente_id': 'INTEGER NOT NULL DEFAULT 0',
      'medico_struttura_id': 'INTEGER',
      'data_visita': 'TEXT',
      'data_scadenza': 'TEXT',
      'esito': 'TEXT',
      'giudizio': 'TEXT',
      'note': 'TEXT',
      'documento_path': 'TEXT',
      'created_at': 'TEXT',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'dati_azienda', {
      'ragione_sociale': 'TEXT',
      'nome_commerciale': 'TEXT',
      'partita_iva': 'TEXT',
      'codice_fiscale': 'TEXT',
      'indirizzo': 'TEXT',
      'cap': 'TEXT',
      'comune': 'TEXT',
      'provincia': 'TEXT',
      'telefono': 'TEXT',
      'email': 'TEXT',
      'pec': 'TEXT',
      'sito_web': 'TEXT',
      'logo_path': 'TEXT',
      'note': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'aule_sedi', {
      'denominazione': "TEXT NOT NULL DEFAULT ''",
      'tipo': "TEXT NOT NULL DEFAULT 'Aula'",
      'indirizzo': "TEXT NOT NULL DEFAULT ''",
      'comune': "TEXT NOT NULL DEFAULT ''",
      'capienza': 'INTEGER',
      'note': "TEXT NOT NULL DEFAULT ''",
      'attiva': 'INTEGER NOT NULL DEFAULT 1',
      'created_at': 'TEXT',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'attrezzature', {
      'denominazione': "TEXT NOT NULL DEFAULT ''",
      'categoria': "TEXT NOT NULL DEFAULT 'Generica'",
      'codice': 'TEXT',
      'descrizione': 'TEXT',
      'quantita': 'INTEGER DEFAULT 1',
      'unita_misura': "TEXT DEFAULT 'pz'",
      'attiva': 'INTEGER DEFAULT 1',
      'note': 'TEXT',
      'created_at': 'TEXT',
      'updated_at': 'TEXT',
    });

    await db.execute('''
  CREATE TABLE IF NOT EXISTS prenotazioni_attrezzature (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prenotazione_id INTEGER NOT NULL,
    attrezzatura_id INTEGER NOT NULL,
    quantita REAL DEFAULT 1,
    note TEXT,
    created_at TEXT,
    updated_at TEXT
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS registri_presenze (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prenotazione_id INTEGER NOT NULL,
    discente_id INTEGER,
    data_lezione TEXT,
    ora_inizio TEXT,
    ora_fine TEXT,
    presente INTEGER DEFAULT 0,
    firma_discente_path TEXT,
    firma_docente_path TEXT,
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prenotazione_id) REFERENCES prenotazioni(id),
    FOREIGN KEY (discente_id) REFERENCES discenti(id)
  )
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_registri_presenze_prenotazione
  ON registri_presenze (prenotazione_id)
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_registri_presenze_discente
  ON registri_presenze (discente_id)
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_registri_presenze_data_lezione
  ON registri_presenze (data_lezione)
''');

    await _ensureColumns(db, 'registri_presenze', {
      'prenotazione_id': 'INTEGER NOT NULL DEFAULT 0',
      'discente_id': 'INTEGER',
      'data_lezione': 'TEXT',
      'ora_inizio': 'TEXT',
      'ora_fine': 'TEXT',
      'presente': 'INTEGER DEFAULT 0',
      'firma_discente_path': 'TEXT',
      'firma_docente_path': 'TEXT',
      'note': 'TEXT',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
    });

    await _ensureColumns(db, 'enti_attestati', {
      'denominazione': "TEXT NOT NULL DEFAULT ''",
      'tipo': "TEXT NOT NULL DEFAULT 'Ente'",
      'codice_accreditamento': 'TEXT',
      'referente': 'TEXT',
      'telefono': 'TEXT',
      'email': 'TEXT',
      'pec': 'TEXT',
      'indirizzo': 'TEXT',
      'comune': 'TEXT',
      'note': 'TEXT',
      'attivo': 'INTEGER DEFAULT 1',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT',
    });

    await _ensureColumns(db, 'privacy_gdpr', {
      'titolo': 'TEXT NOT NULL DEFAULT ""',
      'titolare_trattamento': 'TEXT DEFAULT ""',
      'referente_privacy': 'TEXT DEFAULT ""',
      'base_giuridica': 'TEXT DEFAULT ""',
      'finalita_trattamento': 'TEXT DEFAULT ""',
      'categorie_dati': 'TEXT DEFAULT ""',
      'periodo_conservazione': 'TEXT DEFAULT ""',
      'misure_sicurezza': 'TEXT DEFAULT ""',
      'note': 'TEXT DEFAULT ""',
      'attivo': 'INTEGER DEFAULT 1',
      'created_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
      'updated_at': 'TEXT DEFAULT CURRENT_TIMESTAMP',
    });

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ruoli_utenti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE,
        descrizione TEXT,
        attivo INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS utenti_app (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cognome TEXT NOT NULL,
        email TEXT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        ruolo_id INTEGER,
        attivo INTEGER NOT NULL DEFAULT 1,
        ultimo_accesso TEXT,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (ruolo_id) REFERENCES ruoli_utenti (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS log_accessi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utente_id INTEGER,
        username TEXT,
        esito TEXT NOT NULL,
        messaggio TEXT,
        data_ora TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        dispositivo TEXT,
        FOREIGN KEY (utente_id) REFERENCES utenti_app (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utente_id INTEGER,
        username TEXT,
        modulo TEXT NOT NULL,
        azione TEXT NOT NULL,
        descrizione TEXT,
        record_id INTEGER,
        data_ora TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (utente_id) REFERENCES utenti_app (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ruoli_utenti_nome ON ruoli_utenti(nome)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_utenti_app_username ON utenti_app(username)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_utenti_app_ruolo ON utenti_app(ruolo_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_utenti_app_attivo ON utenti_app(attivo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_log_accessi_utente ON log_accessi(utente_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_log_accessi_data ON log_accessi(data_ora)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_log_modulo ON audit_log(modulo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_log_data ON audit_log(data_ora)',
    );

    await db.insert('ruoli_utenti', {
      'nome': 'Amministratore',
      'descrizione': 'Accesso completo al gestionale',
      'attivo': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('ruoli_utenti', {
      'nome': 'Operatore',
      'descrizione': 'Accesso operativo alle funzioni principali',
      'attivo': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('ruoli_utenti', {
      'nome': 'Solo lettura',
      'descrizione': 'Accesso in sola consultazione',
      'attivo': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await _ensureColumns(db, 'registro_trattamenti', {
      'destinatari': 'TEXT',
      'trasferimento_extra_ue': 'TEXT',
      'tempi_conservazione': 'TEXT',
      'data_revisione': 'TEXT',
    });

    await db.execute('''
    CREATE TABLE IF NOT EXISTS registro_trattamenti_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trattamento_id INTEGER,
      azione TEXT NOT NULL,
      descrizione TEXT NOT NULL,
      dati_prima TEXT,
      dati_dopo TEXT,
      utente TEXT,
      data_ora TEXT NOT NULL
    )
  ''');

    await _ensureColumns(db, 'consensi_privacy', {
      'soggetto_minorenne': 'INTEGER NOT NULL DEFAULT 0',
      'consenso_prestato_da': "TEXT NOT NULL DEFAULT 'discente'",
      'genitore_tutore_nome': 'TEXT',
      'genitore_tutore_codice_fiscale': 'TEXT',
      'genitore_tutore_qualifica': 'TEXT',
      'data_fine_conservazione': 'TEXT',
      'motivo_retention': 'TEXT',
      'retention_bloccata': 'INTEGER NOT NULL DEFAULT 0',
      'note_retention': 'TEXT',
    });
  }

  Future<void> _creaTabellaRegistroTrattamenti(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS registro_trattamenti (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome_trattamento TEXT NOT NULL,
      finalita TEXT,
      base_giuridica TEXT,
      categorie_interessati TEXT,
      categorie_dati TEXT,
      categorie_destinatari TEXT,
      trasferimenti_extra_ue TEXT,
      termini_cancellazione TEXT,
      misure_sicurezza TEXT,
      responsabile_interno TEXT,
      note TEXT,
      attivo INTEGER NOT NULL DEFAULT 1,
      data_revisione TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS registro_trattamenti_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trattamento_id INTEGER,
      azione TEXT NOT NULL,
      descrizione TEXT NOT NULL,
      dati_prima TEXT,
      dati_dopo TEXT,
      utente TEXT,
      data_ora TEXT NOT NULL
    )
  ''');
  }

  Future<void> _ensureColumns(
    Database db,
    String tableName,
    Map<String, String> columns,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');

    final existingColumns = result
        .map((column) => column['name'].toString())
        .toSet();

    for (final entry in columns.entries) {
      if (!existingColumns.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_imprese_intestazione ON imprese(intestazione)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_discenti_nome ON discenti(nome)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_discenti_cognome ON discenti(cognome)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_discenti_codice_fiscale ON discenti(codice_fiscale)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_discenti_impresa ON discenti(impresa_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_corsi_denominazione ON corsi(denominazione)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_corsi_validita_anni ON corsi(validita_anni)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_discente ON prenotazioni(discente_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_impresa ON prenotazioni(impresa_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_corso ON prenotazioni(corso_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_data ON prenotazioni(data)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_prot ON prenotazioni(prot)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diario_prenotazione ON diario(prenotazione_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diario_discente ON diario(discente_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diario_impresa ON diario(impresa_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diario_corso ON diario(corso_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diario_scadenza ON diario(scadenza)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_scadenze_data ON scadenze(data_scadenza)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pdf_diario ON pdf_documenti(diario_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prezzario_impresa ON prezzario(impresa_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prezzario_corso ON prezzario(corso_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prezzario_impresa_corso ON prezzario(impresa_id, corso_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_medici_strutture_tipo ON medici_strutture(tipo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_medici_strutture_denominazione ON medici_strutture(denominazione)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_medici_strutture_attivo ON medici_strutture(attivo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visite_mediche_discente ON visite_mediche(discente_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visite_mediche_medico_struttura ON visite_mediche(medico_struttura_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visite_mediche_data_scadenza ON visite_mediche(data_scadenza)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_dati_azienda_ragione_sociale ON dati_azienda(ragione_sociale)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_dati_azienda_nome_commerciale ON dati_azienda(nome_commerciale)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_docenti_cognome ON docenti(cognome)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_docenti_nome ON docenti(nome)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_docenti_attivo ON docenti(attivo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_aule_sedi_tipo ON aule_sedi(tipo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_aule_sedi_denominazione ON aule_sedi(denominazione)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_aule_sedi_attiva ON aule_sedi(attiva)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attrezzature_denominazione ON attrezzature(denominazione)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attrezzature_categoria ON attrezzature(categoria)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attrezzature_attiva ON attrezzature(attiva)',
    );

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_prenotazioni_attrezzature_prenotazione
  ON prenotazioni_attrezzature(prenotazione_id)
''');

    await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_prenotazioni_attrezzature_attrezzatura
  ON prenotazioni_attrezzature(attrezzatura_id)
''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_docente '
      'ON prenotazioni(docente_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_aula_sede '
      'ON prenotazioni(aula_sede_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_ente_attestato '
      'ON prenotazioni(ente_attestato_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_attrezzature_prenotazione '
      'ON prenotazioni_attrezzature(prenotazione_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prenotazioni_attrezzature_attrezzatura '
      'ON prenotazioni_attrezzature(attrezzatura_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enti_attestati_denominazione ON enti_attestati(denominazione)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enti_attestati_tipo ON enti_attestati(tipo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enti_attestati_attivo ON enti_attestati(attivo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_privacy_gdpr_titolo ON privacy_gdpr(titolo)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_privacy_gdpr_attivo ON privacy_gdpr(attivo)',
    );
  }

  Future<List<Map<String, dynamic>>> getVisiteMediche() async {
    final db = await database;

    return db.rawQuery('''
      SELECT
        vm.*,
        dis.nome AS discente_nome,
        dis.cognome AS discente_cognome,
        ms.denominazione AS medico_struttura_denominazione,
        ms.tipo AS medico_struttura_tipo
      FROM visite_mediche vm
      LEFT JOIN discenti dis ON dis.id = vm.discente_id
      LEFT JOIN medici_strutture ms ON ms.id = vm.medico_struttura_id
      ORDER BY vm.data_scadenza ASC, vm.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getVisiteMedicheByDiscente(
    int discenteId,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT
        vm.*,
        ms.denominazione AS medico_struttura_denominazione,
        ms.tipo AS medico_struttura_tipo
      FROM visite_mediche vm
      LEFT JOIN medici_strutture ms ON ms.id = vm.medico_struttura_id
      WHERE vm.discente_id = ?
      ORDER BY vm.data_scadenza DESC, vm.id DESC
      ''',
      [discenteId],
    );
  }

  Future<List<Map<String, dynamic>>> getDiscentiPerVisiteMediche() async {
    final db = await database;

    return db.query('discenti', orderBy: 'cognome ASC, nome ASC');
  }

  Future<int> inserisciVisitaMedica({
    required int discenteId,
    int? medicoStrutturaId,
    String? dataVisita,
    String? dataScadenza,
    String? esito,
    String? giudizio,
    String? note,
    String? documentoPath,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('visite_mediche', {
      'discente_id': discenteId,
      'medico_struttura_id': medicoStrutturaId,
      'data_visita': dataVisita,
      'data_scadenza': dataScadenza,
      'esito': esito,
      'giudizio': giudizio,
      'note': note,
      'documento_path': documentoPath,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> aggiornaVisitaMedica({
    required int id,
    required int discenteId,
    int? medicoStrutturaId,
    String? dataVisita,
    String? dataScadenza,
    String? esito,
    String? giudizio,
    String? note,
    String? documentoPath,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'visite_mediche',
      {
        'discente_id': discenteId,
        'medico_struttura_id': medicoStrutturaId,
        'data_visita': dataVisita,
        'data_scadenza': dataScadenza,
        'esito': esito,
        'giudizio': giudizio,
        'note': note,
        'documento_path': documentoPath,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaVisitaMedica(int id) async {
    final db = await database;

    return db.delete('visite_mediche', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getDatiAzienda() async {
    final db = await database;

    final result = await db.query('dati_azienda', orderBy: 'id ASC', limit: 1);

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<int> salvaDatiAzienda({
    required String ragioneSociale,
    required String nomeCommerciale,
    String? partitaIva,
    String? codiceFiscale,
    String? indirizzo,
    String? cap,
    String? comune,
    String? provincia,
    String? telefono,
    String? email,
    String? pec,
    String? sitoWeb,
    String? logoPath,
    String? note,
  }) async {
    final db = await database;
    final datiEsistenti = await getDatiAzienda();

    final valori = {
      'ragione_sociale': ragioneSociale.trim(),
      'nome_commerciale': nomeCommerciale.trim(),
      'partita_iva': partitaIva?.trim(),
      'codice_fiscale': codiceFiscale?.trim(),
      'indirizzo': indirizzo?.trim(),
      'cap': cap?.trim(),
      'comune': comune?.trim(),
      'provincia': provincia?.trim(),
      'telefono': telefono?.trim(),
      'email': email?.trim(),
      'pec': pec?.trim(),
      'sito_web': sitoWeb?.trim(),
      'logo_path': logoPath?.trim(),
      'note': note?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (datiEsistenti == null) {
      return db.insert('dati_azienda', valori);
    }

    return db.update(
      'dati_azienda',
      valori,
      where: 'id = ?',
      whereArgs: [datiEsistenti['id']],
    );
  }

  Future<List<Map<String, dynamic>>> getMediciStrutture({
    String ricerca = '',
    bool soloAttivi = false,
  }) async {
    final db = await database;
    final filtri = <String>[];
    final argomenti = <Object?>[];

    if (soloAttivi) {
      filtri.add('attivo = ?');
      argomenti.add(1);
    }

    final ricercaPulita = ricerca.trim();

    if (ricercaPulita.isNotEmpty) {
      filtri.add('''
        (
          denominazione LIKE ?
          OR tipo LIKE ?
          OR referente LIKE ?
          OR telefono LIKE ?
          OR email LIKE ?
          OR indirizzo LIKE ?
          OR note LIKE ?
        )
      ''');

      final valoreRicerca = '%$ricercaPulita%';

      argomenti.addAll([
        valoreRicerca,
        valoreRicerca,
        valoreRicerca,
        valoreRicerca,
        valoreRicerca,
        valoreRicerca,
        valoreRicerca,
      ]);
    }

    final where = filtri.isEmpty ? '' : 'WHERE ${filtri.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        id,
        tipo,
        denominazione,
        referente,
        telefono,
        email,
        indirizzo,
        note,
        attivo,
        created_at,
        updated_at
      FROM medici_strutture
      $where
      ORDER BY attivo DESC, denominazione COLLATE NOCASE ASC
      ''', argomenti);
  }

  Future<int> inserisciMedicoStruttura({
    required String tipo,
    required String denominazione,
    String? referente,
    String? telefono,
    String? email,
    String? indirizzo,
    String? note,
    int attivo = 1,
  }) async {
    final db = await database;

    return db.insert('medici_strutture', {
      'tipo': tipo.trim().isEmpty ? 'Medico' : tipo.trim(),
      'denominazione': denominazione.trim(),
      'referente': referente?.trim(),
      'telefono': telefono?.trim(),
      'email': email?.trim(),
      'indirizzo': indirizzo?.trim(),
      'note': note?.trim(),
      'attivo': attivo,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> aggiornaMedicoStruttura({
    required int id,
    required String tipo,
    required String denominazione,
    String? referente,
    String? telefono,
    String? email,
    String? indirizzo,
    String? note,
    required int attivo,
  }) async {
    final db = await database;

    return db.update(
      'medici_strutture',
      {
        'tipo': tipo.trim().isEmpty ? 'Medico' : tipo.trim(),
        'denominazione': denominazione.trim(),
        'referente': referente?.trim(),
        'telefono': telefono?.trim(),
        'email': email?.trim(),
        'indirizzo': indirizzo?.trim(),
        'note': note?.trim(),
        'attivo': attivo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaMedicoStruttura(int id) async {
    final db = await database;

    return db.delete('medici_strutture', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDocenti() async {
    final db = await database;

    return db.query('docenti', orderBy: 'cognome ASC, nome ASC');
  }

  Future<int> inserisciDocente({
    required String nome,
    required String cognome,
    String? telefono,
    String? email,
    String? codiceFiscale,
    String? qualifica,
    String? note,
    int attivo = 1,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('docenti', {
      'nome': nome.trim(),
      'cognome': cognome.trim(),
      'telefono': telefono?.trim(),
      'email': email?.trim(),
      'codice_fiscale': codiceFiscale?.trim(),
      'qualifica': qualifica?.trim(),
      'note': note?.trim(),
      'attivo': attivo,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> aggiornaDocente({
    required int id,
    required String nome,
    required String cognome,
    String? telefono,
    String? email,
    String? codiceFiscale,
    String? qualifica,
    String? note,
    int attivo = 1,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'docenti',
      {
        'nome': nome.trim(),
        'cognome': cognome.trim(),
        'telefono': telefono?.trim(),
        'email': email?.trim(),
        'codice_fiscale': codiceFiscale?.trim(),
        'qualifica': qualifica?.trim(),
        'note': note?.trim(),
        'attivo': attivo,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaDocente(int id) async {
    final db = await database;

    return db.delete('docenti', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getDiscenteConImpresa(int idDiscente) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
  SELECT 
    d.id,
    d.nome,
    d.cognome,
    d.luogo_nascita,
    d.data_nascita,
    d.codice_fiscale,
    d.impresa_id,
    d.visita_medica_svolta,
    d.data_visita_medica,
    d.scadenza_visita_medica,
    d.informativa_privacy_firmata,
    d.data_firma_informativa_privacy,
    d.documento_privacy_discente_path,
    d.note_privacy_discente,
    i.intestazione AS nome_impresa
  FROM discenti d
  LEFT JOIN imprese i
    ON i.id = d.impresa_id
  WHERE d.id = ?
  LIMIT 1
''',
      [idDiscente],
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<Map<String, dynamic>?> getCorsoDettaglio(int idCorso) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        id,
        denominazione,
        durata_ore,
        validita_anni
      FROM corsi
      WHERE id = ?
      LIMIT 1
    ''',
      [idCorso],
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<List<AulaSede>> getAuleSedi() async {
    final db = await database;

    final rows = await db.query(
      'aule_sedi',
      orderBy: 'attiva DESC, denominazione ASC',
    );

    return rows.map((row) => AulaSede.fromMap(row)).toList();
  }

  Future<int> inserisciAulaSede(AulaSede aulaSede) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = aulaSede.toMap();
    data.remove('id');
    data['created_at'] = now;
    data['updated_at'] = now;

    return db.insert('aule_sedi', data);
  }

  Future<int> aggiornaAulaSede(AulaSede aulaSede) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = aulaSede.toMap();
    data.remove('id');
    data['updated_at'] = now;

    return db.update(
      'aule_sedi',
      data,
      where: 'id = ?',
      whereArgs: [aulaSede.id],
    );
  }

  Future<List<Attrezzatura>> getAttrezzature() async {
    final db = await database;

    final rows = await db.query(
      'attrezzature',
      orderBy: 'attiva DESC, denominazione ASC',
    );

    return rows.map((row) => Attrezzatura.fromMap(row)).toList();
  }

  Future<int> inserisciAttrezzatura({
    required String denominazione,
    required String categoria,
    String? codice,
    String? descrizione,
    int quantita = 1,
    String unitaMisura = 'pz',
    int attiva = 1,
    String? note,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('attrezzature', {
      'denominazione': denominazione.trim(),
      'categoria': categoria.trim().isEmpty ? 'Generica' : categoria.trim(),
      'codice': codice?.trim(),
      'descrizione': descrizione?.trim(),
      'quantita': quantita,
      'unita_misura': unitaMisura.trim().isEmpty ? 'pz' : unitaMisura.trim(),
      'attiva': attiva,
      'note': note?.trim(),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> aggiornaAttrezzatura({
    required int id,
    required String denominazione,
    required String categoria,
    String? codice,
    String? descrizione,
    int quantita = 1,
    String unitaMisura = 'pz',
    int attiva = 1,
    String? note,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'attrezzature',
      {
        'denominazione': denominazione.trim(),
        'categoria': categoria.trim().isEmpty ? 'Generica' : categoria.trim(),
        'codice': codice?.trim(),
        'descrizione': descrizione?.trim(),
        'quantita': quantita,
        'unita_misura': unitaMisura.trim().isEmpty ? 'pz' : unitaMisura.trim(),
        'attiva': attiva,
        'note': note?.trim(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaAttrezzatura(int id) async {
    final db = await database;

    return db.delete('attrezzature', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> aggiornaStatoAttrezzatura({
    required int id,
    required int attiva,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'attrezzature',
      {'attiva': attiva, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAttrezzatureByPrenotazione(
    int prenotazioneId,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
    SELECT 
      pa.id AS collegamento_id,
      pa.prenotazione_id,
      pa.attrezzatura_id,
      pa.quantita,
      pa.note,
      a.denominazione,
      a.categoria,
      a.codice,
      a.attiva
    FROM prenotazioni_attrezzature pa
    INNER JOIN attrezzature a ON a.id = pa.attrezzatura_id
    WHERE pa.prenotazione_id = ?
    ORDER BY a.denominazione COLLATE NOCASE
  ''',
      [prenotazioneId],
    );
  }

  Future<List<int>> getAttrezzatureIdsByPrenotazione(int prenotazioneId) async {
    final db = await database;

    final result = await db.query(
      'prenotazioni_attrezzature',
      columns: ['attrezzatura_id'],
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
    );

    return result.map((row) => row['attrezzatura_id'] as int).toList();
  }

  Future<void> salvaAttrezzaturePrenotazione({
    required int prenotazioneId,
    List<int>? attrezzatureIds,
    List<Map<String, dynamic>>? attrezzature,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final attrezzatureDaSalvare =
        attrezzature ??
        (attrezzatureIds ?? [])
            .map(
              (attrezzaturaId) => {
                'attrezzatura_id': attrezzaturaId,
                'quantita': 1,
                'note': null,
              },
            )
            .toList();

    await db.delete(
      'prenotazioni_attrezzature',
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
    );

    for (final attrezzatura in attrezzatureDaSalvare) {
      final attrezzaturaId = attrezzatura['attrezzatura_id'];

      if (attrezzaturaId == null) {
        continue;
      }

      await db.insert('prenotazioni_attrezzature', {
        'prenotazione_id': prenotazioneId,
        'attrezzatura_id': attrezzaturaId,
        'quantita': attrezzatura['quantita'] ?? 1,
        'note': attrezzatura['note'],
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<String> getSintesiAttrezzaturePrenotazione(int prenotazioneId) async {
    final attrezzature = await getAttrezzatureByPrenotazione(prenotazioneId);

    if (attrezzature.isEmpty) {
      return '';
    }

    return attrezzature
        .map((a) => (a['denominazione'] ?? '').toString())
        .where((nome) => nome.trim().isNotEmpty)
        .join(', ');
  }

  Future<int> aggiornaCollegamentiPrenotazione({
    required int prenotazioneId,
    int? docenteId,
    int? aulaSedeId,
    int? enteAttestatoId,
  }) async {
    final db = await database;

    return db.update(
      'prenotazioni',
      {
        'docente_id': docenteId,
        'aula_sede_id': aulaSedeId,
        'ente_attestato_id': enteAttestatoId,
      },
      where: 'id = ?',
      whereArgs: [prenotazioneId],
    );
  }

  Future<List<Map<String, dynamic>>> getAttrezzaturePrenotazione(
    int prenotazioneId,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT 
        pa.id,
        pa.prenotazione_id,
        pa.attrezzatura_id,
        pa.quantita,
        pa.note,
        pa.created_at,
        pa.updated_at,
        a.denominazione AS attrezzatura_denominazione,
        a.categoria AS attrezzatura_categoria,
        a.codice AS attrezzatura_codice,
        a.unita_misura AS attrezzatura_unita_misura,
        a.attiva AS attrezzatura_attiva
      FROM prenotazioni_attrezzature pa
      LEFT JOIN attrezzature a ON a.id = pa.attrezzatura_id
      WHERE pa.prenotazione_id = ?
      ORDER BY a.denominazione COLLATE NOCASE ASC
      ''',
      [prenotazioneId],
    );
  }

  Future<int> inserisciAttrezzaturaPrenotazione({
    required int prenotazioneId,
    required int attrezzaturaId,
    double quantita = 1,
    String? note,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('prenotazioni_attrezzature', {
      'prenotazione_id': prenotazioneId,
      'attrezzatura_id': attrezzaturaId,
      'quantita': quantita,
      'note': note,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> aggiornaAttrezzaturaPrenotazione({
    required int id,
    required double quantita,
    String? note,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'prenotazioni_attrezzature',
      {'quantita': quantita, 'note': note, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaAttrezzaturaPrenotazione(int id) async {
    final db = await database;

    return db.delete(
      'prenotazioni_attrezzature',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaAttrezzaturePrenotazione(int prenotazioneId) async {
    final db = await database;

    return db.delete(
      'prenotazioni_attrezzature',
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
    );
  }

  Future<List<EnteAttestato>> getEntiAttestati() async {
    final db = await database;

    final rows = await db.query(
      'enti_attestati',
      orderBy: 'attivo DESC, denominazione ASC',
    );

    return rows.map((row) => EnteAttestato.fromMap(row)).toList();
  }

  Future<int> inserisciEnteAttestato({
    required String denominazione,
    required String tipo,
    String? codiceAccreditamento,
    String? referente,
    String? telefono,
    String? email,
    String? pec,
    String? indirizzo,
    String? comune,
    String? note,
    int attivo = 1,
  }) async {
    final db = await database;

    return db.insert('enti_attestati', {
      'denominazione': denominazione.trim(),
      'tipo': tipo.trim().isEmpty ? 'Ente' : tipo.trim(),
      'codice_accreditamento': codiceAccreditamento?.trim(),
      'referente': referente?.trim(),
      'telefono': telefono?.trim(),
      'email': email?.trim(),
      'pec': pec?.trim(),
      'indirizzo': indirizzo?.trim(),
      'comune': comune?.trim(),
      'note': note?.trim(),
      'attivo': attivo,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> aggiornaEnteAttestato({
    required int id,
    required String denominazione,
    required String tipo,
    String? codiceAccreditamento,
    String? referente,
    String? telefono,
    String? email,
    String? pec,
    String? indirizzo,
    String? comune,
    String? note,
    required int attivo,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'enti_attestati',
      {
        'denominazione': denominazione.trim(),
        'tipo': tipo.trim().isEmpty ? 'Ente' : tipo.trim(),
        'codice_accreditamento': codiceAccreditamento?.trim(),
        'referente': referente?.trim(),
        'telefono': telefono?.trim(),
        'email': email?.trim(),
        'pec': pec?.trim(),
        'indirizzo': indirizzo?.trim(),
        'comune': comune?.trim(),
        'note': note?.trim(),
        'attivo': attivo,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminaEnteAttestato(int id) async {
    final db = await database;

    return db.delete('enti_attestati', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> aggiornaStatoEnteAttestato({
    required int id,
    required int attivo,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'enti_attestati',
      {'attivo': attivo, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // PRIVACY / GDPR 679/2016
  // ============================================================

  Future<List<Map<String, dynamic>>> getPrivacyGdpr({
    bool soloAttivi = false,
  }) async {
    final db = await database;

    return db.query(
      'privacy_gdpr',
      where: soloAttivi ? 'attivo = ?' : null,
      whereArgs: soloAttivi ? [1] : null,
      orderBy: 'titolo COLLATE NOCASE ASC',
    );
  }

  Future<Map<String, dynamic>?> getPrivacyGdprById(int id) async {
    final db = await database;

    final risultati = await db.query(
      'privacy_gdpr',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (risultati.isEmpty) {
      return null;
    }

    return risultati.first;
  }

  Future<int> insertPrivacyGdpr({
    required String titolo,
    String? titolareTrattamento,
    String? referentePrivacy,
    String? baseGiuridica,
    String? finalitaTrattamento,
    String? categorieDati,
    String? periodoConservazione,
    String? misureSicurezza,
    String? note,
    bool attivo = true,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('privacy_gdpr', {
      'titolo': titolo.trim(),
      'titolare_trattamento': titolareTrattamento?.trim(),
      'referente_privacy': referentePrivacy?.trim(),
      'base_giuridica': baseGiuridica?.trim(),
      'finalita_trattamento': finalitaTrattamento?.trim(),
      'categorie_dati': categorieDati?.trim(),
      'periodo_conservazione': periodoConservazione?.trim(),
      'misure_sicurezza': misureSicurezza?.trim(),
      'note': note?.trim(),
      'attivo': attivo ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> aggiornaPrivacyGdpr({
    required int id,
    required String titolo,
    String? titolareTrattamento,
    String? referentePrivacy,
    String? baseGiuridica,
    String? finalitaTrattamento,
    String? categorieDati,
    String? periodoConservazione,
    String? misureSicurezza,
    String? note,
    bool attivo = true,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'privacy_gdpr',
      {
        'titolo': titolo.trim(),
        'titolare_trattamento': titolareTrattamento?.trim(),
        'referente_privacy': referentePrivacy?.trim(),
        'base_giuridica': baseGiuridica?.trim(),
        'finalita_trattamento': finalitaTrattamento?.trim(),
        'categorie_dati': categorieDati?.trim(),
        'periodo_conservazione': periodoConservazione?.trim(),
        'misure_sicurezza': misureSicurezza?.trim(),
        'note': note?.trim(),
        'attivo': attivo ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> cambiaStatoPrivacyGdpr({
    required int id,
    required bool attivo,
  }) async {
    final db = await database;

    return db.update(
      'privacy_gdpr',
      {
        'attivo': attivo ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePrivacyGdpr(int id) async {
    final db = await database;

    return db.delete('privacy_gdpr', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> aggiornaPrivacyDiscente({
    required int discenteId,
    required bool informativaPrivacyFirmata,
    String? dataFirmaInformativaPrivacy,
    String? documentoPrivacyDiscentePath,
    String? notePrivacyDiscente,
  }) async {
    final db = await database;

    return db.update(
      'discenti',
      {
        'informativa_privacy_firmata': informativaPrivacyFirmata ? 1 : 0,
        'data_firma_informativa_privacy': dataFirmaInformativaPrivacy,
        'documento_privacy_discente_path': documentoPrivacyDiscentePath,
        'note_privacy_discente': notePrivacyDiscente,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [discenteId],
    );
  }

  // QUI SOTTO AGGIUNGI IL NUOVO METODO

  Future<int> aggiornaPrivacyImpresa({
    required int impresaId,
    required bool informativaPrivacyImpresaFirmata,
    String? dataFirmaInformativaPrivacyImpresa,
    String? notePrivacyImpresa,
  }) async {
    final db = await database;

    return db.update(
      'imprese',
      {
        'informativa_privacy_impresa_firmata': informativaPrivacyImpresaFirmata
            ? 1
            : 0,
        'data_firma_informativa_privacy_impresa':
            dataFirmaInformativaPrivacyImpresa,
        'note_privacy_impresa': notePrivacyImpresa,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [impresaId],
    );
  }

  Future<int> aggiornaDocumentoPrivacyImpresa({
    required int impresaId,
    required String? documentoPrivacyImpresaPath,
  }) async {
    final db = await database;

    return db.update(
      'imprese',
      {
        'documento_privacy_impresa_path': documentoPrivacyImpresaPath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [impresaId],
    );
  }

  Future<List<RegistroPresenza>> getRegistriPresenze({
    int? prenotazioneId,
    int? discenteId,
  }) async {
    final db = await database;

    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (prenotazioneId != null) {
      whereParts.add('prenotazione_id = ?');
      whereArgs.add(prenotazioneId);
    }

    if (discenteId != null) {
      whereParts.add('discente_id = ?');
      whereArgs.add(discenteId);
    }

    final rows = await db.query(
      'registri_presenze',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'data_lezione ASC, ora_inizio ASC, id ASC',
    );

    return rows.map(RegistroPresenza.fromMap).toList();
  }

  Future<int> inserisciRegistroPresenza(RegistroPresenza registro) async {
    final db = await database;

    final dati = registro.toMap()
      ..remove('id')
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return db.insert('registri_presenze', dati);
  }

  Future<int> aggiornaRegistroPresenza(RegistroPresenza registro) async {
    final db = await database;

    if (registro.id == null) {
      throw ArgumentError('ID registro presenza mancante');
    }

    final dati = registro.toMap()
      ..remove('id')
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return db.update(
      'registri_presenze',
      dati,
      where: 'id = ?',
      whereArgs: [registro.id],
    );
  }

  Future<int> eliminaRegistroPresenza(int id) async {
    final db = await database;

    return db.delete('registri_presenze', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> eliminaRegistriPresenzePrenotazione(int prenotazioneId) async {
    final db = await database;

    return db.delete(
      'registri_presenze',
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
    );
  }
  // ============================================================
  // UTENTI / RUOLI / LOG ACCESSI
  // ============================================================

  Future<List<RuoloUtente>> getRuoliUtenti({bool soloAttivi = true}) async {
    final db = await database;

    final where = soloAttivi ? 'attivo = ?' : null;
    final whereArgs = soloAttivi ? [1] : null;

    final maps = await db.query(
      'ruoli_utenti',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'nome ASC',
    );

    return maps.map((map) => RuoloUtente.fromMap(map)).toList();
  }

  Future<List<UtenteApp>> getUtentiApp({
    bool soloAttivi = true,
    String ricerca = '',
  }) async {
    final db = await database;

    final condizioni = <String>[];
    final args = <Object?>[];

    if (soloAttivi) {
      condizioni.add('attivo = ?');
      args.add(1);
    }

    final testoRicerca = ricerca.trim();
    if (testoRicerca.isNotEmpty) {
      condizioni.add('''
        (
          LOWER(nome) LIKE ?
          OR LOWER(cognome) LIKE ?
          OR LOWER(username) LIKE ?
          OR LOWER(email) LIKE ?
        )
      ''');

      final valore = '%${testoRicerca.toLowerCase()}%';
      args.addAll([valore, valore, valore, valore]);
    }

    final maps = await db.query(
      'utenti_app',
      where: condizioni.isEmpty ? null : condizioni.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'cognome ASC, nome ASC, username ASC',
    );

    return maps.map((map) => UtenteApp.fromMap(map)).toList();
  }

  Future<UtenteApp?> getUtenteAppByUsername(String username) async {
    final db = await database;

    final usernameNormalizzato = username.trim().toLowerCase();
    if (usernameNormalizzato.isEmpty) {
      return null;
    }

    final maps = await db.query(
      'utenti_app',
      where: 'LOWER(username) = ?',
      whereArgs: [usernameNormalizzato],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return UtenteApp.fromMap(maps.first);
  }

  Future<int> inserisciUtenteApp(UtenteApp utente) async {
    final db = await database;

    final dati = utente.toMap()
      ..remove('id')
      ..remove('created_at')
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String();

    return db.insert('utenti_app', dati);
  }

  Future<int> aggiornaUtenteApp(UtenteApp utente) async {
    final db = await database;

    if (utente.id == null) {
      throw ArgumentError('ID utente mancante per aggiornamento.');
    }

    final dati = utente.toMap()
      ..remove('id')
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return db.update(
      'utenti_app',
      dati,
      where: 'id = ?',
      whereArgs: [utente.id],
    );
  }

  Future<int> aggiornaStatoUtenteApp({
    required int id,
    required bool attivo,
  }) async {
    final db = await database;

    return db.update(
      'utenti_app',
      {
        'attivo': attivo ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> aggiornaUltimoAccessoUtenteApp(int id) async {
    final db = await database;

    return db.update(
      'utenti_app',
      {
        'ultimo_accesso': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> registraLogAccesso({
    int? utenteId,
    String? username,
    required String esito,
    String? messaggio,
    String? dispositivo,
  }) async {
    final db = await database;

    return db.insert('log_accessi', {
      'utente_id': utenteId,
      'username': username,
      'esito': esito,
      'messaggio': messaggio,
      'data_ora': DateTime.now().toIso8601String(),
      'dispositivo': dispositivo,
    });
  }

  Future<List<Map<String, dynamic>>> getLogAccessi({int limit = 100}) async {
    final db = await database;

    return db.query(
      'log_accessi',
      orderBy: 'data_ora DESC, id DESC',
      limit: limit,
    );
  }

  Future<int> registraAuditLog({
    int? utenteId,
    String? username,
    required String modulo,
    required String azione,
    String? descrizione,
    int? recordId,
  }) async {
    final db = await database;

    return db.insert('audit_log', {
      'utente_id': utenteId,
      'username': username,
      'modulo': modulo,
      'azione': azione,
      'descrizione': descrizione,
      'record_id': recordId,
      'data_ora': DateTime.now().toIso8601String(),
    });
  }
  // -----------------------------
  // GDPR031A - Registro consensi/privacy
  // -----------------------------

  Future<List<ConsensoPrivacy>> getConsensiPrivacy({
    String ricerca = '',
    String stato = 'Tutti',
    String tipoSoggetto = 'Tutti',
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <Object?>[];

    final ricercaPulita = ricerca.trim();

    if (ricercaPulita.isNotEmpty) {
      where.add('''
      (
        nominativo LIKE ?
        OR codice_fiscale LIKE ?
        OR email LIKE ?
        OR telefono LIKE ?
        OR finalita LIKE ?
        OR versione_informativa LIKE ?
        OR documento_riferimento LIKE ?
        OR note LIKE ?
      )
    ''');

      final valore = '%$ricercaPulita%';
      args.addAll([
        valore,
        valore,
        valore,
        valore,
        valore,
        valore,
        valore,
        valore,
      ]);
    }

    if (stato != 'Tutti') {
      where.add('stato = ?');
      args.add(stato);
    }

    if (tipoSoggetto != 'Tutti') {
      where.add('tipo_soggetto = ?');
      args.add(tipoSoggetto);
    }

    final maps = await db.query(
      'consensi_privacy',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'data_consenso DESC, id DESC',
    );

    return maps.map(ConsensoPrivacy.fromMap).toList();
  }

  Future<int> insertConsensoPrivacy(ConsensoPrivacy consenso) async {
    final db = await database;
    final map = consenso.toMap()..remove('id');

    return db.insert('consensi_privacy', map);
  }

  Future<int> updateConsensoPrivacy(ConsensoPrivacy consenso) async {
    final db = await database;

    if (consenso.id == null) {
      throw Exception('ID consenso mancante per aggiornamento');
    }

    final map = consenso.toMap()..remove('id');

    return db.update(
      'consensi_privacy',
      map,
      where: 'id = ?',
      whereArgs: [consenso.id],
    );
  }

  Future<int> deleteConsensoPrivacy(int id) async {
    final db = await database;

    return db.delete('consensi_privacy', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> revocaConsensoPrivacy(int id) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'consensi_privacy',
      {
        'stato': 'REVOCATO',
        'data_revoca': _formattaDataItalianaConsensoPrivacy(DateTime.now()),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  String _formattaDataItalianaConsensoPrivacy(DateTime data) {
    final giorno = data.day.toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final anno = data.year.toString();

    return '$giorno/$mese/$anno';
  }

  Future<int> insertConsensoPrivacyLog(ConsensoPrivacyLog log) async {
    final db = await database;
    return db.insert('consensi_privacy_log', log.toMap());
  }

  Future<List<ConsensoPrivacyLog>> getConsensiPrivacyLog({
    int? consensoPrivacyId,
  }) async {
    final db = await database;

    final maps = await db.query(
      'consensi_privacy_log',
      where: consensoPrivacyId != null ? 'consenso_privacy_id = ?' : null,
      whereArgs: consensoPrivacyId != null ? [consensoPrivacyId] : null,
      orderBy: 'data_ora DESC, id DESC',
    );

    return maps.map((map) => ConsensoPrivacyLog.fromMap(map)).toList();
  }

  Future<void> registraLogConsensoPrivacy({
    int? consensoPrivacyId,
    required String azione,
    required String descrizione,
    String? datiPrima,
    String? datiDopo,
    String utente = 'Sistema',
  }) async {
    await insertConsensoPrivacyLog(
      ConsensoPrivacyLog(
        consensoPrivacyId: consensoPrivacyId,
        azione: azione,
        descrizione: descrizione,
        datiPrima: datiPrima,
        datiDopo: datiDopo,
        utente: utente,
        dataOra: DateTime.now(),
      ),
    );
  }
}
