import 'sqlite_search_service.dart';

class EnterpriseLookupRepository {
  final SqliteSearchService searchService;

  EnterpriseLookupRepository({
    required this.searchService,
  });

  // =========================
  // DISCENTI
  // =========================

  Future<List<SearchItem>> searchDiscenti(String query) {
    return searchService.search(
      table: 'discenti',
      idColumn: 'id',
      textColumn: 'nome',
      query: query,
      limit: 20,
    );
  }

  // =========================
  // IMPRESE
  // =========================

  Future<List<SearchItem>> searchImprese(String query) {
    return searchService.search(
      table: 'imprese',
      idColumn: 'id',
      textColumn: 'nome',
      query: query,
      limit: 20,
    );
  }

  // =========================
  // CORSI
  // =========================

  Future<List<SearchItem>> searchCorsi(String query) {
    return searchService.search(
      table: 'corsi',
      idColumn: 'id',
      textColumn: 'nome',
      query: query,
      limit: 20,
    );
  }
}