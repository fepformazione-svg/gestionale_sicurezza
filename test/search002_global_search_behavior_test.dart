import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/global_search_service.dart';

void main() {
  test('SEARCH002 restituisce solo i moduli con corrispondenze', () async {
    final queryRicevute = <String>[];

    Future<int> risposta(String query, int count) async {
      queryRicevute.add(query);
      return count;
    }

    final service = GlobalSearchService.withQueries(
      prenotazioniCount: (query) => risposta(query, 2),
      diarioCount: (query) => risposta(query, 0),
      scadenzeCount: (query) => risposta(query, 4),
      discentiCount: (query) => risposta(query, 1),
      impreseCount: (query) => risposta(query, 0),
      corsiCount: (query) => risposta(query, 3),
    );

    final risultati = await service.search('  rossi  ');

    expect(risultati.map((item) => item.moduleName).toList(), [
      'Prenotazioni',
      'Scadenze',
      'Discenti',
      'Corsi',
    ]);

    expect(risultati.map((item) => item.pageIndex).toList(), [1, 3, 4, 6]);

    expect(risultati.map((item) => item.count).toList(), [2, 4, 1, 3]);

    expect(
      queryRicevute,
      List<String>.filled(6, 'rossi'),
      reason:
          'Tutte le ricerche devono ricevere '
          'la query gia pulita.',
    );
  });

  test('SEARCH002 ricerca vuota non interroga nessun modulo', () async {
    var chiamate = 0;

    Future<int> conta(String query) async {
      chiamate++;
      return 1;
    }

    final service = GlobalSearchService.withQueries(
      prenotazioniCount: conta,
      diarioCount: conta,
      scadenzeCount: conta,
      discentiCount: conta,
      impreseCount: conta,
      corsiCount: conta,
    );

    final risultati = await service.search('   ');

    expect(risultati, isEmpty);
    expect(
      chiamate,
      0,
      reason:
          'Una ricerca vuota deve terminare '
          'senza interrogare il database.',
    );
  });
}
