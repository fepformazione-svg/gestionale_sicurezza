import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEARCH002 HomePage usa il servizio di ricerca globale trasversale', () {
    final source = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      source,
      contains("../services/global_search_service.dart"),
      reason:
          'HomePage deve importare il servizio '
          'di ricerca globale.',
    );

    expect(
      source,
      contains('GlobalSearchService.standard()'),
      reason:
          'HomePage deve usare l orchestratore '
          'reale della ricerca globale.',
    );

    expect(
      source,
      contains('List<GlobalSearchModuleResult>'),
      reason:
          'HomePage deve conservare i risultati '
          'trasversali restituiti dal servizio.',
    );

    expect(
      source,
      contains('globalSearchLoading'),
      reason:
          'La UI deve distinguere la fase '
          'di caricamento della ricerca.',
    );

    expect(
      RegExp(
        r'_globalSearchService'
        r'\.search\(',
      ).hasMatch(source),
      isTrue,
      reason:
          'La modifica della topbar deve avviare '
          'la ricerca trasversale.',
    );

    expect(
      source,
      contains('globalSearchResults'),
      reason:
          'I risultati della ricerca devono essere '
          'conservati nello stato di HomePage.',
    );
  });

  test('SEARCH002 HomePage mostra risultati cliccabili per modulo', () {
    final source = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      source,
      contains('Risultati ricerca globale'),
      reason:
          'La HomePage deve rendere riconoscibile '
          'il pannello dei risultati trasversali.',
    );

    expect(
      source,
      contains('result.moduleName'),
      reason:
          'Ogni risultato deve mostrare '
          'il modulo di provenienza.',
    );

    expect(
      source,
      contains('result.count'),
      reason:
          'Ogni risultato deve mostrare '
          'quante corrispondenze sono presenti.',
    );

    expect(
      source,
      contains('result.pageIndex'),
      reason:
          'Il risultato deve conoscere '
          'la pagina di destinazione.',
    );

    expect(
      RegExp(
        r'selectedIndex\s*=\s*'
        r'result\.pageIndex',
      ).hasMatch(source),
      isTrue,
      reason:
          'Il click sul risultato deve aprire '
          'il modulo corrispondente.',
    );
  });

  test('SEARCH002 ricerca vuota pulisce i risultati globali', () {
    final source = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      RegExp(
        r'globalSearchResults\s*=\s*'
        r'(?:const\s*)?<GlobalSearchModuleResult>\[\]',
      ).hasMatch(source),
      isTrue,
      reason:
          'Azzerando la topbar non devono restare '
          'risultati globali precedenti.',
    );
  });
}
