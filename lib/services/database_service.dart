import 'package:sqflite/sqflite.dart';

import '../models/discente.dart';
import '../models/impresa.dart';
import '../models/corso.dart';
import 'app_database.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Future<Database> get _db async => await AppDatabase.instance.database;

  // =========================
  // DISCENTI
  // =========================

  Future<List<Discente>> getDiscenti() async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT
        d.id,
        d.nome,
        d.cognome,
        d.luogo_nascita,
        d.data_nascita,
        d.codice_fiscale,
        d.impresa_id,
        i.intestazione AS nome_impresa
      FROM discenti d
      LEFT JOIN imprese i ON i.id = d.impresa_id
      ORDER BY d.cognome ASC, d.nome ASC
    ''');

    return rows.map((e) => Discente.fromMap(e)).toList();
  }

  Future<void> insertDiscente(Discente discente) async {
    final db = await _db;

    await db.insert(
      'discenti',
      discente.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDiscente(Discente discente) async {
    final db = await _db;

    await db.update(
      'discenti',
      discente.toMap(),
      where: 'id = ?',
      whereArgs: [discente.id],
    );
  }

  Future<void> deleteDiscente(int id) async {
    final db = await _db;

    await db.delete(
      'discenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDiscentiLookup() async {
    final db = await _db;

    return await db.rawQuery('''
      SELECT
        d.id,
        d.nome,
        d.cognome,
        d.impresa_id,
        i.intestazione AS nome_impresa
      FROM discenti d
      LEFT JOIN imprese i ON i.id = d.impresa_id
      ORDER BY d.cognome ASC, d.nome ASC
    ''');
  }

  // =========================
  // IMPRESE
  // =========================

  Future<List<Impresa>> getImprese() async {
    final db = await _db;

    final rows = await db.query(
      'imprese',
      orderBy: 'intestazione ASC',
    );

    return rows.map((e) => Impresa.fromMap(e)).toList();
  }

  Future<void> insertImpresa(Impresa impresa) async {
    final db = await _db;

    await db.insert(
      'imprese',
      impresa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getImpreseLookup() async {
    final db = await _db;

    return await db.query(
      'imprese',
      orderBy: 'intestazione ASC',
    );
  }

  // =========================
  // CORSI
  // =========================

  Future<List<Corso>> getCorsi() async {
    final db = await _db;

    final rows = await db.query(
      'corsi',
      orderBy: 'denominazione ASC',
    );

    return rows.map((e) => Corso.fromMap(e)).toList();
  }

  Future<void> insertCorso(Corso corso) async {
    final db = await _db;

    await db.insert(
      'corsi',
      corso.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCorsiLookup() async {
    final db = await _db;

    return await db.query(
      'corsi',
      orderBy: 'denominazione ASC',
    );
  }

  // =========================
  // PRENOTAZIONI
  // =========================

  Future<List<Map<String, dynamic>>> getPrenotazioni() async {
    final db = await _db;

    return await db.rawQuery('''
      SELECT
        p.id,
        p.discente_id,
        p.impresa_id,
        p.corso_id,
        p.data,
        p.prot,
        p.aperto,
        p.conferma,
        p.ok,
        p.registro,
        p.seleziona,
        p.note,

        d.nome AS discente_nome,
        d.cognome AS discente_cognome,
        i.intestazione AS impresa_nome,
        c.denominazione AS corso_nome

      FROM prenotazioni p
      LEFT JOIN discenti d ON d.id = p.discente_id
      LEFT JOIN imprese i ON i.id = p.impresa_id
      LEFT JOIN corsi c ON c.id = p.corso_id
      ORDER BY p.id DESC
    ''');
  }

  Future<int> insertPrenotazione(Map<String, dynamic> dati) async {
    final db = await _db;

    final id = await db.insert('prenotazioni', {
      'discente_id': dati['discente_id'],
      'impresa_id': dati['impresa_id'],
      'corso_id': dati['corso_id'],
      'data': dati['data'],
      'prot': dati['prot'],
      'note': dati['note'],
      'aperto': dati['aperto'] ?? 1,
      'conferma': dati['conferma'] ?? 0,
      'registro': dati['registro'] ?? 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    if ((dati['conferma'] ?? 0) == 1) {
      await confermaPrenotazioneWorkflow(id);
    }

    return id;
  }

  Future<void> updatePrenotazione(
    int id,
    Map<String, dynamic> dati,
  ) async {
    final db = await _db;

    await db.update(
      'prenotazioni',
      {
        'discente_id': dati['discente_id'],
        'impresa_id': dati['impresa_id'],
        'corso_id': dati['corso_id'],
        'data': dati['data'],
        'prot': dati['prot'],
        'note': dati['note'],
        'aperto': dati['aperto'] ?? 1,
        'conferma': dati['conferma'] ?? 0,
        'registro': dati['registro'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if ((dati['conferma'] ?? 0) == 1) {
      await confermaPrenotazioneWorkflow(id);
    } else {
      await annullaConfermaPrenotazioneWorkflow(id);
    }
  }

  Future<void> deletePrenotazione(int id) async {
    final db = await _db;

    await db.delete(
      'diario',
      where: 'prenotazione_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'prenotazioni',
      where: 'id = ?',
      whereArgs: [id],
    );

    await aggiornaScadenzeDaDiario();
  }

  Future<void> confermaPrenotazioneWorkflow(int prenotazioneId) async {
    final db = await _db;

    final prenotazioni = await db.query(
      'prenotazioni',
      where: 'id = ?',
      whereArgs: [prenotazioneId],
      limit: 1,
    );

    if (prenotazioni.isEmpty) return;

    final p = prenotazioni.first;

    final esiste = await db.query(
      'diario',
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
      limit: 1,
    );

    final dataCorso = p['data']?.toString();
    final corsoId = p['corso_id'];

    String? scadenza;

    if (dataCorso != null && dataCorso.isNotEmpty && corsoId != null) {
      final corso = await db.query(
        'corsi',
        where: 'id = ?',
        whereArgs: [corsoId],
        limit: 1,
      );

      final validita = corso.isNotEmpty
          ? corso.first['validita_anni'] as int? ?? 0
          : 0;

      scadenza = _calcolaScadenza(dataCorso, validita);
    }

    final datiDiario = {
      'prenotazione_id': prenotazioneId,
      'discente_id': p['discente_id'],
      'impresa_id': p['impresa_id'],
      'corso_id': p['corso_id'],
      'data': p['data'],
      'prot': p['prot'],
      'scadenza': scadenza,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (esiste.isEmpty) {
      await db.insert('diario', {
        ...datiDiario,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'diario',
        datiDiario,
        where: 'prenotazione_id = ?',
        whereArgs: [prenotazioneId],
      );
    }

    await aggiornaScadenzeDaDiario();
  }

  Future<void> annullaConfermaPrenotazioneWorkflow(
    int prenotazioneId,
  ) async {
    final db = await _db;

    await db.delete(
      'diario',
      where: 'prenotazione_id = ?',
      whereArgs: [prenotazioneId],
    );

    await aggiornaScadenzeDaDiario();
  }

  // =========================
  // DIARIO
  // =========================

  Future<List<Map<String, dynamic>>> caricaDiario({
    String ricerca = '',
  }) async {
    final db = await _db;
    final q = '%${ricerca.trim()}%';

    if (ricerca.trim().isEmpty) {
      return await db.rawQuery('''
        SELECT
          d.id,
          d.prenotazione_id,
          d.discente_id,
          d.impresa_id,
          d.corso_id,
          d.data,
          d.prot,
          s.data_scadenza AS scadenza,
          d.da_fatturare,
          d.fattura,
          d.invio,
          d.rinnovo,
          d.pdf_attestato,

          dis.nome,
          dis.cognome,
          imp.intestazione AS impresa,
          c.denominazione AS corso

        FROM diario d
        LEFT JOIN discenti dis ON dis.id = d.discente_id
        LEFT JOIN imprese imp ON imp.id = d.impresa_id
        LEFT JOIN corsi c ON c.id = d.corso_id
        LEFT JOIN scadenze s ON s.diario_id = d.id
        ORDER BY d.id DESC
      ''');
    }

    return await db.rawQuery('''
      SELECT
        d.id,
        d.prenotazione_id,
        d.discente_id,
        d.impresa_id,
        d.corso_id,
        d.data,
        d.prot,
        s.data_scadenza AS scadenza,
        d.da_fatturare,
        d.fattura,
        d.invio,
        d.rinnovo,
        d.pdf_attestato,

        dis.nome,
        dis.cognome,
        imp.intestazione AS impresa,
        c.denominazione AS corso

      FROM diario d
      LEFT JOIN discenti dis ON dis.id = d.discente_id
      LEFT JOIN imprese imp ON imp.id = d.impresa_id
      LEFT JOIN corsi c ON c.id = d.corso_id
      LEFT JOIN scadenze s ON s.diario_id = d.id

      WHERE
        dis.nome LIKE ?
        OR dis.cognome LIKE ?
        OR imp.intestazione LIKE ?
        OR c.denominazione LIKE ?
        OR d.prot LIKE ?
        OR d.data LIKE ?

      ORDER BY d.id DESC
    ''', [q, q, q, q, q, q]);
  }

Future<void> aggiornaDaFatturareDiario({
  required int id,
  required bool valore,
}) async {
  final db = await _db;

  await db.update(
    'diario',
    {
      'da_fatturare': valore ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

  // =========================
  // SCADENZE
  // =========================

  Future<void> aggiornaScadenzeDaDiario() async {
    final db = await _db;

    final diario = await db.rawQuery('''
      SELECT
        d.id,
        d.discente_id,
        d.impresa_id,
        d.corso_id,
        d.data,
        c.validita_anni
      FROM diario d
      LEFT JOIN corsi c ON c.id = d.corso_id
    ''');

    for (final riga in diario) {
      final dataCorso = riga['data']?.toString();
      final validitaAnni =
    int.tryParse(riga['validita_anni']?.toString() ?? '0') ?? 0;

      final dataScadenza = _calcolaScadenza(dataCorso, validitaAnni);
      final stato = _statoScadenza(dataScadenza);

      final dati = {
        'diario_id': riga['id'],
        'discente_id': riga['discente_id'],
        'impresa_id': riga['impresa_id'],
        'corso_id': riga['corso_id'],
        'data_corso': dataCorso,
        'data_scadenza': dataScadenza,
        'stato': stato,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final esiste = await db.query(
        'scadenze',
        where: 'diario_id = ?',
        whereArgs: [riga['id']],
      );

      if (esiste.isEmpty) {
        await db.insert('scadenze', dati);
      } else {
        await db.update(
          'scadenze',
          dati,
          where: 'diario_id = ?',
          whereArgs: [riga['id']],
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> caricaScadenze() async {
  final db = await _db;

  await aggiornaScadenzeDaDiario();

  return await db.rawQuery('''
    SELECT
      s.id,
      s.diario_id,
      s.discente_id,
      s.impresa_id,
      s.corso_id,
      s.discente_id AS id_discente,
      s.impresa_id AS id_impresa,
      s.corso_id AS id_corso,
      s.data_corso,
      s.data_scadenza,
      s.stato,
      s.note,
      d.nome,
      d.cognome,
      d.nome || ' ' || d.cognome AS discente,
      i.intestazione AS impresa,
      c.denominazione AS corso,
      s.data_corso AS data,
      s.data_scadenza AS scadenza
    FROM scadenze s
    LEFT JOIN discenti d ON d.id = s.discente_id
    LEFT JOIN imprese i ON i.id = s.impresa_id
    LEFT JOIN corsi c ON c.id = s.corso_id
    ORDER BY
      CASE s.stato
        WHEN 'SCADUTO' THEN 1
        WHEN 'IN SCADENZA' THEN 2
        ELSE 3
      END,
      s.data_scadenza ASC
  ''');
}
  Future<int> contaScaduti() async {
    final db = await _db;
    await aggiornaScadenzeDaDiario();

    final result = await db.rawQuery(
      "SELECT COUNT(*) AS totale FROM scadenze WHERE stato = 'SCADUTO'",
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> contaInScadenza() async {
    final db = await _db;
    await aggiornaScadenzeDaDiario();

    final result = await db.rawQuery(
      "SELECT COUNT(*) AS totale FROM scadenze WHERE stato = 'IN SCADENZA'",
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> contaValidi() async {
    final db = await _db;
    await aggiornaScadenzeDaDiario();

    final result = await db.rawQuery(
      "SELECT COUNT(*) AS totale FROM scadenze WHERE stato = 'VALIDO'",
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> rinnovaCorso({
  required int idDiscente,
  required int idImpresa,
  required int idCorso,
}) async {
  final db = await _db;

  final oggi = DateTime.now();
  final data = oggi.toIso8601String().substring(0, 10);

  final duplicato = await db.query(
    'diario',
    where: '''
      discente_id = ?
      AND impresa_id = ?
      AND corso_id = ?
      AND data = ?
    ''',
    whereArgs: [idDiscente, idImpresa, idCorso, data],
    limit: 1,
  );

  if (duplicato.isNotEmpty) {
    return;
  }

  final corso = await db.query(
    'corsi',
    where: 'id = ?',
    whereArgs: [idCorso],
    limit: 1,
  );

  final validita = corso.isNotEmpty
      ? corso.first['validita_anni'] as int? ?? 0
      : 0;

  final scadenza = validita > 0
      ? DateTime(
          oggi.year + validita,
          oggi.month,
          oggi.day,
        ).toIso8601String().substring(0, 10)
      : null;

  await db.insert('diario', {
    'discente_id': idDiscente,
    'impresa_id': idImpresa,
    'corso_id': idCorso,
    'data': data,
    'scadenza': scadenza,
    'da_fatturare': 0,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  });

  await aggiornaScadenzeDaDiario();
}

// =========================
// DASHBOARD KPI
// =========================

Future<Map<String, int>> caricaKpiDashboard() async {
  final db = await _db;

  await aggiornaScadenzeDaDiario();

  Future<int> count(String sql) async {
    final result = await db.rawQuery(sql);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  return {
    'prenotazioni': await count('SELECT COUNT(*) FROM prenotazioni'),
    'diario': await count('SELECT COUNT(*) FROM diario'),
    'scadenze': await count('SELECT COUNT(*) FROM scadenze'),
    'scaduti': await count(
      "SELECT COUNT(*) FROM scadenze WHERE stato = 'SCADUTO'",
    ),
    'discenti': await count('SELECT COUNT(*) FROM discenti'),
    'imprese': await count('SELECT COUNT(*) FROM imprese'),
    'da_fatturare': await count(
      'SELECT COUNT(*) FROM diario WHERE da_fatturare = 1',
    ),
  };
}

  // =========================
  // HELPERS
  // =========================

  String? _calcolaScadenza(String? dataCorso, int? validitaAnni) {
    if (dataCorso == null || dataCorso.trim().isEmpty) return null;
    if (validitaAnni == null || validitaAnni <= 0) return null;

    DateTime? data;

    if (dataCorso.contains('/')) {
      final parti = dataCorso.split('/');
      if (parti.length == 3) {
        data = DateTime(
          int.parse(parti[2]),
          int.parse(parti[1]),
          int.parse(parti[0]),
        );
      }
    } else {
      data = DateTime.tryParse(dataCorso);
    }

    if (data == null) return null;

    final scadenza = DateTime(
      data.year + validitaAnni,
      data.month,
      data.day,
    );

    return scadenza.toIso8601String().substring(0, 10);
  }

  String _statoScadenza(String? scadenza) {
    if (scadenza == null || scadenza.trim().isEmpty) return 'VALIDO';

    final dataScadenza = DateTime.tryParse(scadenza);
    if (dataScadenza == null) return 'VALIDO';

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(
      dataScadenza.year,
      dataScadenza.month,
      dataScadenza.day,
    );

    final giorni = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorni < 0) return 'SCADUTO';
    if (giorni <= 90) return 'IN SCADENZA';
    return 'VALIDO';
  }
 // =========================
  // KPI PRENOTAZIONI
  // =========================

  Future<int> contaPrenotazioniAperte() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS totale
      FROM prenotazioni
      WHERE conferma = 0 OR conferma IS NULL
    ''');

    return result.first['totale'] as int? ?? 0;
  }

  Future<int> contaPrenotazioniChiuse() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS totale
      FROM prenotazioni
      WHERE conferma = 1
    ''');

    return result.first['totale'] as int? ?? 0;
  }

  Future<int> contaPrenotazioniTotali() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS totale
      FROM prenotazioni
    ''');

    return result.first['totale'] as int? ?? 0;
  }
}