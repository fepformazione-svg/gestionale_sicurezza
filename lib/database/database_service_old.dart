import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Future<Database> get _db async => await AppDatabase.instance.database;

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
      final validitaAnni = riga['validita_anni'] as int?;

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

      -- ALIAS PER RINNOVA
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

    LEFT JOIN discenti d 
      ON d.id = s.discente_id

    LEFT JOIN imprese i 
      ON i.id = s.impresa_id

    LEFT JOIN corsi c 
      ON c.id = s.corso_id

    ORDER BY
      CASE s.stato
        WHEN 'SCADUTO' THEN 1
        WHEN 'IN SCADENZA' THEN 2
        ELSE 3
      END,
      s.data_scadenza ASC
  ''');
}

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
          d.scadenza,
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
        d.scadenza,
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

  Future<int> insertPrenotazione(Map<String, dynamic> dati) async {
    final db = await _db;

    return await db.insert('prenotazioni', {
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
        'aperto': dati['aperto'] ?? 1,
        'conferma': dati['conferma'] ?? 0,
        'registro': dati['registro'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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

    if (esiste.isEmpty) {
      await db.insert('diario', {
        'prenotazione_id': prenotazioneId,
        'discente_id': p['discente_id'],
        'impresa_id': p['impresa_id'],
        'corso_id': p['corso_id'],
        'data': p['data'],
        'prot': p['prot'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'diario',
        {
          'discente_id': p['discente_id'],
          'impresa_id': p['impresa_id'],
          'corso_id': p['corso_id'],
          'data': p['data'],
          'prot': p['prot'],
          'updated_at': DateTime.now().toIso8601String(),
        },
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
  final dbClient = await _db;

  // DATA CORSO = OGGI
  final dataCorso = DateTime.now();

  // RECUPERO VALIDITA
  final corso = await dbClient.query(
    'corsi',
    where: 'id = ?',
    whereArgs: [idCorso],
    limit: 1,
  );

  int validita = 0;

  if (corso.isNotEmpty) {
    validita = corso.first['validita_anni'] as int? ?? 0;
  }

  // CALCOLO SCADENZA
  String? scadenza;

  if (validita > 0) {
    final dataScadenza = DateTime(
      dataCorso.year + validita,
      dataCorso.month,
      dataCorso.day,
    );

    scadenza = dataScadenza.toIso8601String().substring(0, 10);
  }

  // INSERIMENTO NUOVO RECORD DIARIO
  await dbClient.insert(
    'diario',
    {
      'discente_id': idDiscente,
      'impresa_id': idImpresa,
      'corso_id': idCorso,

      'data': dataCorso.toIso8601String().substring(0, 10),

      'scadenza': scadenza,

      'da_fatturare': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
  );

  // AGGIORNA SCADENZE
  await aggiornaScadenzeDaDiario();
}
}