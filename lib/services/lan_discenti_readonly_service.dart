import 'package:gestionale_sicurezza/services/lan_readonly_database_service.dart';

Future<List<Map<String, dynamic>>> loadLanDiscentiReadOnly(
  String databasePath,
) async {
  final database = await openLanReadOnlyDatabase(databasePath);

  try {
    final rows = await database.rawQuery('''
      SELECT
        d.id,
        d.nome,
        d.cognome,
        d.impresa_id,
        i.intestazione AS nome_impresa
      FROM discenti d
      LEFT JOIN imprese i
        ON i.id = d.impresa_id
      ORDER BY
        d.cognome COLLATE NOCASE ASC,
        d.nome COLLATE NOCASE ASC,
        d.id ASC
      ''');

    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  } finally {
    await database.close();
  }
}
