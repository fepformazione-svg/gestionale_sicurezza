import 'package:gestionale_sicurezza/services/lan_readonly_database_service.dart';

Future<List<Map<String, dynamic>>> loadLanCorsiReadOnly(
  String databasePath,
) async {
  final database = await openLanReadOnlyDatabase(databasePath);

  try {
    final rows = await database.rawQuery('''
      SELECT
        id,
        denominazione,
        durata_ore,
        validita_anni
      FROM corsi
      ORDER BY
        denominazione COLLATE NOCASE ASC,
        id ASC
    ''');

    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  } finally {
    await database.close();
  }
}
