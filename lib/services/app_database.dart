import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );

    return _database!;
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
  }

  Future<void> _ensureAllColumns(Database db) async {
    await _ensureColumns(db, 'imprese', {
      'partita_iva': 'TEXT',
      'codice_fiscale': 'TEXT',
      'indirizzo': 'TEXT',
      'telefono': 'TEXT',
      'referente': 'TEXT',
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
}
