import 'package:sqflite/sqflite.dart';

import 'package:flutter/foundation.dart';
import '../models/discente.dart';
import '../models/impresa.dart';
import '../models/corso.dart';
import '../models/prezzario.dart';
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
        d.visita_medica_svolta,
        d.data_visita_medica,
        d.scadenza_visita_medica,
        i.intestazione AS nome_impresa
      FROM discenti d
      LEFT JOIN imprese i ON i.id = d.impresa_id
      ORDER BY d.cognome ASC, d.nome ASC
    ''');

    return rows.map((e) => Discente.fromMap(e)).toList();
  }

  Future<Discente?> getDiscenteById(int id) async {
    final db = await _db;

    final rows = await db.rawQuery(
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
    LEFT JOIN imprese i ON i.id = d.impresa_id
    WHERE d.id = ?
    LIMIT 1
    ''',
      [id],
    );

    if (rows.isEmpty) return null;

    return Discente.fromMap(rows.first);
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

  Future<List<Discente>> getDiscentiByImpresaId(int impresaId) async {
    final db = await _db;

    final rows = await db.rawQuery(
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
      LEFT JOIN imprese i ON i.id = d.impresa_id
      WHERE d.impresa_id = ?
      ORDER BY d.cognome ASC, d.nome ASC
    ''',
      [impresaId],
    );

    return rows.map((e) => Discente.fromMap(e)).toList();
  }

  Future<bool> discenteHaCollegamenti(int id) async {
    final db = await _db;

    final diario =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM diario WHERE discente_id = ?',
            [id],
          ),
        ) ??
        0;

    final prenotazioni =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM prenotazioni WHERE discente_id = ?',
            [id],
          ),
        ) ??
        0;

    final scadenze =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM scadenze WHERE discente_id = ?',
            [id],
          ),
        ) ??
        0;

    return diario > 0 || prenotazioni > 0 || scadenze > 0;
  }

  Future<bool> discenteHaStorico(int id) async {
    final db = await _db;

    final diario = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM diario
        WHERE discente_id = ?
        ''',
        [id],
      ),
    );

    return (diario ?? 0) > 0;
  }

  Future<void> deleteDiscente(int id) async {
    final db = await _db;

    await db.delete('discenti', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStoriciByIds(List<int> ids) async {
    final db = await _db;

    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('scadenze', where: 'diario_id = ?', whereArgs: [id]);

        await txn.delete('diario', where: 'id = ?', whereArgs: [id]);
      }
    });
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

    final rows = await db.query('imprese', orderBy: 'intestazione ASC');

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

  Future<void> updateImpresa(Impresa impresa) async {
    final db = await _db;

    await db.update(
      'imprese',
      impresa.toMap(),
      where: 'id = ?',
      whereArgs: [impresa.id],
    );
  }

  Future<List<Map<String, dynamic>>> getImpreseLookup() async {
    final db = await _db;

    return await db.query('imprese', orderBy: 'intestazione ASC');
  }

  Future<bool> impresaHaCollegamenti(int idImpresa) async {
    final db = await _db;

    final discenti =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM discenti WHERE impresa_id = ?',
            [idImpresa],
          ),
        ) ??
        0;

    final prenotazioni =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM prenotazioni WHERE impresa_id = ?',
            [idImpresa],
          ),
        ) ??
        0;

    final diario =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM diario WHERE impresa_id = ?',
            [idImpresa],
          ),
        ) ??
        0;

    return discenti > 0 || prenotazioni > 0 || diario > 0;
  }

  Future<void> deleteImpresa(int id) async {
    final db = await _db;

    await db.delete('imprese', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // CORSI
  // =========================

  Future<List<Corso>> getCorsi() async {
    final db = await _db;

    final rows = await db.query('corsi', orderBy: 'denominazione ASC');

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

  Future<void> updateCorso(Corso corso) async {
    final db = await _db;

    if (corso.id == null) return;

    await db.update(
      'corsi',
      corso.toMap(),
      where: 'id = ?',
      whereArgs: [corso.id],
    );
  }

  Future<List<Map<String, dynamic>>> getCorsiLookup() async {
    final db = await _db;

    return await db.query('corsi', orderBy: 'denominazione ASC');
  }

  Future<List<Map<String, dynamic>>> getDocentiLookup() async {
    final db = await _db;

    return await db.rawQuery('''
    SELECT
      id,
      nome,
      cognome,
      attivo
    FROM docenti
    WHERE attivo = 1
    ORDER BY cognome ASC, nome ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getAuleSediLookup() async {
    final db = await _db;

    return await db.rawQuery('''
    SELECT
      id,
      denominazione,
      tipo,
      indirizzo,
      comune,
      attiva
    FROM aule_sedi
    WHERE attiva = 1
    ORDER BY denominazione ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getEntiAttestatiLookup() async {
    final db = await _db;

    return await db.rawQuery('''
    SELECT
      id,
      denominazione,
      tipo,
      codice_accreditamento,
      attivo
    FROM enti_attestati
    WHERE attivo = 1
    ORDER BY denominazione ASC
  ''');
  }

  // =========================
  // PREZZARIO
  // ======

  Future<List<Prezzario>> getPrezzario() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT
        p.id,
        p.impresa_id,
        p.corso_id,
        p.prezzo,
        p.note,
        p.created_at,
        p.updated_at,
        i.intestazione AS impresa,
        c.denominazione AS corso
      FROM prezzario p
      LEFT JOIN imprese i ON i.id = p.impresa_id
      LEFT JOIN corsi c ON c.id = p.corso_id
      ORDER BY i.intestazione COLLATE NOCASE ASC,
               c.denominazione COLLATE NOCASE ASC
    ''');

    return result.map((map) => Prezzario.fromMap(map)).toList();
  }

  Future<Prezzario?> getPrezzarioByImpresaCorso({
    required int impresaId,
    required int corsoId,
  }) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.impresa_id,
        p.corso_id,
        p.prezzo,
        p.note,
        p.created_at,
        p.updated_at,
        i.intestazione AS impresa,
        c.denominazione AS corso
      FROM prezzario p
      LEFT JOIN imprese i ON i.id = p.impresa_id
      LEFT JOIN corsi c ON c.id = p.corso_id
      WHERE p.impresa_id = ?
        AND p.corso_id = ?
      LIMIT 1
      ''',
      [impresaId, corsoId],
    );

    if (result.isEmpty) {
      return null;
    }

    return Prezzario.fromMap(result.first);
  }

  Future<int> insertPrezzario(Prezzario prezzario) async {
    final db = await _db;

    return db.insert('prezzario', prezzario.toInsertMap());
  }

  Future<int> updatePrezzario(Prezzario prezzario) async {
    final db = await _db;

    if (prezzario.id == null) {
      throw ArgumentError('ID prezzario mancante per aggiornamento');
    }

    return db.update(
      'prezzario',
      prezzario.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [prezzario.id],
    );
  }

  Future<int> deletePrezzario(int id) async {
    final db = await _db;

    return db.delete('prezzario', where: 'id = ?', whereArgs: [id]);
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

  Future<List<Map<String, dynamic>>> getPrenotazioniPaged({
    required int limit,
    required int offset,
  }) async {
    final db = await _db;

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM prenotazioni'),
    );

    debugPrint('PRENOTAZIONI DB: $count');

    return await db.rawQuery(
      '''
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
      p.docente_id,
      p.aula_sede_id,
      p.ente_attestato_id,

      d.nome AS discente_nome,
      d.cognome AS discente_cognome,
      i.intestazione AS impresa_nome,
      c.denominazione AS corso_nome,

      doc.nome AS docente_nome,
      doc.cognome AS docente_cognome,
      doc.qualifica AS docente_qualifica,

      aula.denominazione AS aula_sede_denominazione,
      aula.comune AS aula_sede_comune,

      ente.denominazione AS ente_attestato_denominazione,
ente.tipo AS ente_attestato_tipo,

(
  SELECT GROUP_CONCAT(a.denominazione, ', ')
  FROM prenotazioni_attrezzature pa
  INNER JOIN attrezzature a ON a.id = pa.attrezzatura_id
  WHERE pa.prenotazione_id = p.id
) AS attrezzature_sintesi

FROM prenotazioni p
    LEFT JOIN discenti d ON d.id = p.discente_id
    LEFT JOIN imprese i ON i.id = p.impresa_id
    LEFT JOIN corsi c ON c.id = p.corso_id
    LEFT JOIN docenti doc ON doc.id = p.docente_id
    LEFT JOIN aule_sedi aula ON aula.id = p.aula_sede_id
    LEFT JOIN enti_attestati ente ON ente.id = p.ente_attestato_id

    ORDER BY p.id DESC

    LIMIT ? OFFSET ?
  ''',
      [limit, offset],
    );
  }

  Future<int> chiudiPrenotazioniSelezionate(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await _db;

    final placeholders = List.filled(ids.length, '?').join(',');

    return await db.rawUpdate('''
    UPDATE prenotazioni
    SET
      conferma = 1,
      aperto = 0,
      registro = 0
    WHERE id IN ($placeholders)
  ''', ids);
  }

  Future<int> apriPrenotazioniSelezionate(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await _db;

    final placeholders = List.filled(ids.length, '?').join(',');

    return await db.rawUpdate('''
    UPDATE prenotazioni
    SET
      conferma = 0,
      aperto = 1,
      registro = 0
    WHERE id IN ($placeholders)
  ''', ids);
  }

  Future<int> insertPrenotazione(Map<String, dynamic> dati) async {
    final db = await _db;

    final id = await db.insert('prenotazioni', {
      'discente_id': dati['discente_id'],
      'impresa_id': dati['impresa_id'],
      'corso_id': dati['corso_id'],
      'data': dati['data'],
      'prot': dati['prot'],
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

  Future<void> updatePrenotazione(int id, Map<String, dynamic> dati) async {
    final db = await _db;

    await db.update(
      'prenotazioni',
      {
        'discente_id': dati['discente_id'],
        'impresa_id': dati['impresa_id'],
        'corso_id': dati['corso_id'],
        'docente_id': dati['docente_id'],
        'aula_sede_id': dati['aula_sede_id'],
        'ente_attestato_id': dati['ente_attestato_id'],
        'data': dati['data'],
        'prot': dati['prot'],
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

    await db.delete('diario', where: 'prenotazione_id = ?', whereArgs: [id]);

    await db.delete('prenotazioni', where: 'id = ?', whereArgs: [id]);

    await aggiornaScadenzeDaDiario();
  }

  Future<void> deleteDiario(int id) async {
    final db = await _db;

    await db.delete('scadenze', where: 'diario_id = ?', whereArgs: [id]);

    await db.delete('diario', where: 'id = ?', whereArgs: [id]);

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

  Future<void> annullaConfermaPrenotazioneWorkflow(int prenotazioneId) async {
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

  Future<List<Map<String, dynamic>>> caricaDiario({String ricerca = ''}) async {
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

    return await db.rawQuery(
      '''
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
    ''',
      [q, q, q, q, q, q],
    );
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

  Future<void> aggiornaInvioDiario({
    required int idDiario,
    required int invio,
  }) async {
    final db = await _db;

    await db.update(
      'diario',
      {'invio': invio},
      where: 'id = ?',
      whereArgs: [idDiario],
    );
  }

  Future<void> aggiornaFatturaDiario({
    required int idDiario,
    required String fattura,
  }) async {
    final db = await _db;

    await db.update(
      'diario',
      {'fattura': fattura.trim()},
      where: 'id = ?',
      whereArgs: [idDiario],
    );
  }

  // =========================
  // SCADENZE
  // =========================

  Future<void> aggiornaScadenzeDaDiario() async {
    final db = await _db;

    await db.delete(
      'scadenze',
      where: '''
    discente_id IS NULL
    OR discente_id NOT IN (SELECT id FROM discenti)
    OR diario_id IS NULL
    OR diario_id NOT IN (SELECT id FROM diario)
  ''',
    );

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

  Future<List<Map<String, dynamic>>> getStoricoDiscente(int discenteId) async {
    final db = await _db;

    return await db.rawQuery(
      '''
    SELECT
      d.id,
      d.data,
      d.prot,
      s.data_scadenza AS scadenza,
      c.denominazione AS corso,
      c.durata_ore,
      c.validita_anni

    FROM diario d

    LEFT JOIN corsi c
      ON c.id = d.corso_id

    LEFT JOIN scadenze s
      ON s.diario_id = d.id

    WHERE d.discente_id = ?

    ORDER BY d.data DESC
  ''',
      [discenteId],
    );
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
      'corsi': await count('SELECT COUNT(*) FROM corsi'),
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

    final scadenza = DateTime(data.year + validitaAnni, data.month, data.day);

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

  Future<void> aggiornaStatoPrenotazione({
    required int id,
    required int aperto,
    required int registro,
    required int conferma,
  }) async {
    final db = await _db;

    await db.update(
      'prenotazioni',
      {'aperto': aperto, 'registro': registro, 'conferma': conferma},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
