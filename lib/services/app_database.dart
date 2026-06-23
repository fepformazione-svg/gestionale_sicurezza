import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/aula_sede.dart';
import '../models/attrezzatura.dart';
import '../models/ente_attestato.dart';

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
    required List<int> attrezzatureIds,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'prenotazioni_attrezzature',
        where: 'prenotazione_id = ?',
        whereArgs: [prenotazioneId],
      );

      for (final attrezzaturaId in attrezzatureIds) {
        await txn.insert('prenotazioni_attrezzature', {
          'prenotazione_id': prenotazioneId,
          'attrezzatura_id': attrezzaturaId,
          'quantita': 1,
          'note': '',
          'created_at': now,
          'updated_at': now,
        });
      }
    });
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
}
