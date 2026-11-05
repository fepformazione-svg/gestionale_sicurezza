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

    final codici = await database.rawQuery('''
      SELECT
        id,
        corso_id,
        piattaforma,
        codice,
        note,
        attivo
      FROM corso_piattaforme
      WHERE attivo = 1
      ORDER BY
        corso_id ASC,
        piattaforma COLLATE NOCASE ASC,
        codice COLLATE NOCASE ASC,
        id ASC
    ''');

    final raggruppati = <int, List<Map<String, dynamic>>>{};
    for (final codice in codici) {
      final corsoId = codice['corso_id'];
      if (corsoId is! int) continue;
      raggruppati
          .putIfAbsent(corsoId, () => <Map<String, dynamic>>[])
          .add(Map<String, dynamic>.from(codice));
    }

    return rows
        .map((corso) {
          final id = corso['id'];
          return <String, dynamic>{
            ...corso,
            'piattaforme': id is int
                ? (raggruppati[id] ?? const <Map<String, dynamic>>[])
                : const <Map<String, dynamic>>[],
          };
        })
        .toList(growable: false);
  } finally {
    await database.close();
  }
}
