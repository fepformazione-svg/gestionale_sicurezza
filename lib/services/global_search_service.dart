import 'app_database.dart';
import 'database_service.dart';
import 'enterprise_lookup_repository.dart';
import 'sqlite_search_service.dart';

typedef GlobalSearchCountQuery = Future<int> Function(String query);

class GlobalSearchModuleResult {
  final String moduleName;
  final int pageIndex;
  final int count;

  const GlobalSearchModuleResult({
    required this.moduleName,
    required this.pageIndex,
    required this.count,
  });
}

class GlobalSearchService {
  final GlobalSearchCountQuery _prenotazioniCount;
  final GlobalSearchCountQuery _diarioCount;
  final GlobalSearchCountQuery _scadenzeCount;
  final GlobalSearchCountQuery _discentiCount;
  final GlobalSearchCountQuery _impreseCount;
  final GlobalSearchCountQuery _corsiCount;

  GlobalSearchService({
    required DatabaseService databaseService,
    required EnterpriseLookupRepository lookupRepository,
  }) : _prenotazioniCount = ((query) async {
         final conteggi = await databaseService
             .contaPrenotazioniFiltratePerStato(ricerca: query);

         return conteggi['tutte'] ?? 0;
       }),
       _diarioCount = ((query) {
         return databaseService.contaDiario(
           ricerca: query,
           soloDaFatturare: false,
         );
       }),
       _scadenzeCount = ((query) {
         return databaseService.contaScadenzeFiltrate(
           ricerca: query,
           filtroStato: 'Tutte',
         );
       }),
       _discentiCount = ((query) {
         return databaseService.contaDiscenti(ricerca: query);
       }),
       _impreseCount = ((query) async {
         final risultati = await lookupRepository.searchImprese(query);

         return risultati.length;
       }),
       _corsiCount = ((query) async {
         final risultati = await lookupRepository.searchCorsi(query);

         return risultati.length;
       });

  GlobalSearchService._(
    this._prenotazioniCount,
    this._diarioCount,
    this._scadenzeCount,
    this._discentiCount,
    this._impreseCount,
    this._corsiCount,
  );

  factory GlobalSearchService.withQueries({
    required GlobalSearchCountQuery prenotazioniCount,
    required GlobalSearchCountQuery diarioCount,
    required GlobalSearchCountQuery scadenzeCount,
    required GlobalSearchCountQuery discentiCount,
    required GlobalSearchCountQuery impreseCount,
    required GlobalSearchCountQuery corsiCount,
  }) {
    return GlobalSearchService._(
      prenotazioniCount,
      diarioCount,
      scadenzeCount,
      discentiCount,
      impreseCount,
      corsiCount,
    );
  }

  factory GlobalSearchService.standard() {
    return GlobalSearchService(
      databaseService: DatabaseService.instance,
      lookupRepository: EnterpriseLookupRepository(
        searchService: SqliteSearchService(
          databaseProvider: () => AppDatabase.instance.database,
        ),
      ),
    );
  }

  Future<List<GlobalSearchModuleResult>> search(String value) async {
    final query = value.trim();

    if (query.isEmpty) {
      return const [];
    }

    final results = <GlobalSearchModuleResult>[];

    await _addResult(
      results,
      moduleName: 'Prenotazioni',
      pageIndex: 1,
      countQuery: _prenotazioniCount,
      query: query,
    );

    await _addResult(
      results,
      moduleName: 'Diario',
      pageIndex: 2,
      countQuery: _diarioCount,
      query: query,
    );

    await _addResult(
      results,
      moduleName: 'Scadenze',
      pageIndex: 3,
      countQuery: _scadenzeCount,
      query: query,
    );

    await _addResult(
      results,
      moduleName: 'Discenti',
      pageIndex: 4,
      countQuery: _discentiCount,
      query: query,
    );

    await _addResult(
      results,
      moduleName: 'Imprese',
      pageIndex: 5,
      countQuery: _impreseCount,
      query: query,
    );

    await _addResult(
      results,
      moduleName: 'Corsi',
      pageIndex: 6,
      countQuery: _corsiCount,
      query: query,
    );

    return results;
  }

  Future<void> _addResult(
    List<GlobalSearchModuleResult> results, {
    required String moduleName,
    required int pageIndex,
    required GlobalSearchCountQuery countQuery,
    required String query,
  }) async {
    final count = await countQuery(query);

    if (count <= 0) {
      return;
    }

    results.add(
      GlobalSearchModuleResult(
        moduleName: moduleName,
        pageIndex: pageIndex,
        count: count,
      ),
    );
  }
}
