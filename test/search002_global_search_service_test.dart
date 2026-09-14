import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SEARCH002 introduce orchestratore per la ricerca globale trasversale',
    () {
      final serviceFile = File('lib/services/global_search_service.dart');

      expect(
        serviceFile.existsSync(),
        isTrue,
        reason:
            'SEARCH002 deve introdurre un servizio dedicato '
            'alla ricerca globale trasversale.',
      );

      final source = serviceFile.readAsStringSync();

      expect(
        source,
        contains('class GlobalSearchModuleResult'),
        reason:
            'Il servizio deve esporre un risultato '
            'che identifichi il modulo trovato.',
      );

      expect(
        source,
        contains('class GlobalSearchService'),
        reason:
            'Deve esistere un orchestratore dedicato '
            'alla ricerca globale.',
      );

      expect(
        source,
        contains('DatabaseService'),
        reason:
            'Il servizio deve riutilizzare DatabaseService '
            'invece di duplicare le query esistenti.',
      );

      expect(
        source,
        contains('EnterpriseLookupRepository'),
        reason:
            'Imprese e Corsi devono riutilizzare '
            'il repository di lookup esistente.',
      );

      expect(
        source,
        contains('contaDiscenti'),
        reason:
            'La ricerca globale deve interrogare '
            'la ricerca esistente dei Discenti.',
      );

      expect(
        source,
        contains('contaPrenotazioniFiltratePerStato'),
        reason:
            'La ricerca globale deve riutilizzare '
            'il conteggio filtrato delle Prenotazioni.',
      );

      expect(
        source,
        contains('contaDiario'),
        reason:
            'La ricerca globale deve riutilizzare '
            'la ricerca del Diario.',
      );

      expect(
        source,
        contains('contaScadenzeFiltrate'),
        reason:
            'La ricerca globale deve riutilizzare '
            'la ricerca delle Scadenze.',
      );

      expect(
        source,
        contains('searchImprese'),
        reason:
            'La ricerca globale deve interrogare '
            'il lookup Imprese.',
      );

      expect(
        source,
        contains('searchCorsi'),
        reason:
            'La ricerca globale deve interrogare '
            'il lookup Corsi.',
      );

      for (final pageIndex in [1, 2, 3, 4, 5, 6]) {
        expect(
          RegExp('pageIndex\\s*:\\s*$pageIndex').hasMatch(source),
          isTrue,
          reason:
              'Deve essere presente la destinazione '
              'di navigazione $pageIndex.',
        );
      }
    },
  );
}
