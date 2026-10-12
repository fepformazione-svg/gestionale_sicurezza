import 'package:gestionale_sicurezza/services/lan_readonly_database_service.dart';

Future<List<Map<String, dynamic>>> loadLanImpreseReadOnly(
  String databasePath,
) async {
  final database = await openLanReadOnlyDatabase(databasePath);

  try {
    final rows = await database.rawQuery('''
      SELECT
        id,
        intestazione,
        partita_iva,
        codice_fiscale,
        indirizzo,
        telefono,
        referente
      FROM imprese
      ORDER BY
        intestazione COLLATE NOCASE ASC,
        id ASC
      ''');

    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  } finally {
    await database.close();
  }
}
