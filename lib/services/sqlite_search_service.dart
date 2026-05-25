import 'package:sqflite/sqflite.dart';

class SearchItem {
  final int id;
  final String text;
  final Map<String, Object?> raw;

  const SearchItem({
    required this.id,
    required this.text,
    required this.raw,
  });

  @override
  String toString() => text;
}

class SqliteSearchService {
  final Future<Database> Function() databaseProvider;

  SqliteSearchService({
    required this.databaseProvider,
  });

  Future<List<SearchItem>> search({
    required String table,
    required String idColumn,
    required String textColumn,
    required String query,
    int limit = 20,
  }) async {
    final db = await databaseProvider();

    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return [];
    }

    _validateSqlName(table);
    _validateSqlName(idColumn);
    _validateSqlName(textColumn);

    final likeQuery = '%${_escapeLike(cleanQuery)}%';
    final prefixQuery = '${_escapeLike(cleanQuery)}%';

    final rows = await db.rawQuery(
      '''
      SELECT *
      FROM $table
      WHERE $textColumn LIKE ? ESCAPE '\\' COLLATE NOCASE
      ORDER BY
        CASE
          WHEN $textColumn LIKE ? ESCAPE '\\' COLLATE NOCASE THEN 0
          ELSE 1
        END,
        $textColumn ASC
      LIMIT ?
      ''',
      [
        likeQuery,
        prefixQuery,
        limit,
      ],
    );

    return rows.map((row) {
      return SearchItem(
        id: row[idColumn] as int,
        text: (row[textColumn] ?? '').toString(),
        raw: row,
      );
    }).toList();
  }

  String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  void _validateSqlName(String value) {
    final valid = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);

    if (!valid) {
      throw ArgumentError('Nome SQL non valido: $value');
    }
  }
}