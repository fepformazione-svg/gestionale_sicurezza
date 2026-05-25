import 'package:sqflite/sqflite.dart';

import '../services/app_database.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance =
      DatabaseService._();

  Future<Database> get _db async =>
      await AppDatabase.instance.database;

  Future<List<Map<String, dynamic>>> caricaScadenze() async {
    final db = await _db;

    return await db.rawQuery('''
      SELECT
        diario.id,

        diario.id_discente,
        diario.id_impresa,
        diario.id_corso,

        discenti.nome || ' ' || discenti.cognome
          AS discente,

        imprese.intestazione
          AS impresa,

        corsi.denominazione
          AS corso,

        diario.data
          AS data_corso,

        diario.scadenza
          AS scadenza

      FROM diario

      LEFT JOIN discenti
        ON discenti.id = diario.id_discente

      LEFT JOIN imprese
        ON imprese.id = diario.id_impresa

      LEFT JOIN corsi
        ON corsi.id = diario.id_corso

      ORDER BY diario.scadenza ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> caricaDiario({
    String ricerca = '',
  }) async {
    final db = await _db;

    final q = '%${ricerca.trim()}%';

    return await db.rawQuery('''
      SELECT
        diario.id,

        diario.id_discente,
        diario.id_impresa,
        diario.id_corso,

        diario.data,
        diario.scadenza,

        discenti.nome,
        discenti.cognome,

        imprese.intestazione
          AS impresa,

        corsi.denominazione
          AS corso

      FROM diario

      LEFT JOIN discenti
        ON discenti.id = diario.id_discente

      LEFT JOIN imprese
        ON imprese.id = diario.id_impresa

      LEFT JOIN corsi
        ON corsi.id = diario.id_corso

      WHERE
        discenti.nome LIKE ?
        OR discenti.cognome LIKE ?
        OR imprese.intestazione LIKE ?
        OR corsi.denominazione LIKE ?

      ORDER BY diario.id DESC
    ''', [q, q, q, q]);
  }

  Future<void> rinnovaCorso({
    required int idDiscente,
    required int idImpresa,
    required int idCorso,
  }) async {
    final dbClient = await _db;

    final corso = await dbClient.query(
      'corsi',
      where: 'id = ?',
      whereArgs: [idCorso],
      limit: 1,
    );

    int validita = 0;

    if (corso.isNotEmpty) {
      validita =
          corso.first['validita_anni'] as int? ??
              0;
    }

    final dataCorso = DateTime.now();

    String? scadenza;

    if (validita > 0) {
      final dataScadenza = DateTime(
        dataCorso.year + validita,
        dataCorso.month,
        dataCorso.day,
      );

      scadenza = dataScadenza
          .toIso8601String()
          .substring(0, 10);
    }

    await dbClient.insert(
      'diario',
      {
        'id_discente': idDiscente,
        'id_impresa': idImpresa,
        'id_corso': idCorso,

        'data': dataCorso
            .toIso8601String()
            .substring(0, 10),

        'scadenza': scadenza,
      },
    );
  }
}