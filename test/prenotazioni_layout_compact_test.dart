import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PREN012 evita la duplicazione dei filtri principali sopra la tabella',
    () {
      final source = File(
        'lib/pages/prenotazioni_page.dart',
      ).readAsStringSync();

      const startMarker = 'if (MediaQuery.of(context).size.height >= 760) ...[';

      const endMarker = 'riquadroOperativoFiltroQualitaPrenotazioni(),';

      final start = source.indexOf(startMarker);
      expect(
        start,
        greaterThanOrEqualTo(0),
        reason: 'Blocco KPI Prenotazioni non trovato.',
      );

      final end = source.indexOf(endMarker, start);
      expect(
        end,
        greaterThan(start),
        reason: 'Fine del blocco filtri Prenotazioni non trovata.',
      );

      final layoutSource = source.substring(start, end);

      const filtriPrincipali = <String>[
        "filtro: 'tutte'",
        "filtro: 'aperte'",
        "filtro: 'registro'",
        "filtro: 'chiuse'",
        "filtro: 'da_fare'",
      ];

      for (final filtro in filtriPrincipali) {
        expect(
          filtro.allMatches(layoutSource).length,
          1,
          reason:
              'Ogni filtro principale deve comparire una sola volta '
              'nel blocco superiore: nei KPI cliccabili, senza chip duplicato.',
        );
      }

      const filtriQualita = <String>[
        "filtro: 'senza_discente'",
        "filtro: 'aziendali_senza_discente'",
        "filtro: 'senza_docente'",
        "filtro: 'recenti_da_sistemare'",
      ];

      for (final filtro in filtriQualita) {
        expect(
          filtro.allMatches(layoutSource).length,
          1,
          reason:
              'I filtri qualita devono rimanere disponibili '
              'sopra la tabella.',
        );
      }
    },
  );
}
