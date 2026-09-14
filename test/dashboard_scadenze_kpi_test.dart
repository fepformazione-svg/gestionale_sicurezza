import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DASH001 espone il KPI delle scadenze in scadenza', () {
    final source = File(
      'lib/services/database_service.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("'in_scadenza': await count("),
      reason:
          'Il riepilogo Dashboard deve esporre '
          'il KPI in_scadenza.',
    );

    expect(
      source,
      contains(
        "SELECT COUNT(*) FROM scadenze "
        "WHERE stato = 'IN SCADENZA'",
      ),
      reason:
          'Il KPI in_scadenza deve contare solo '
          'le scadenze con stato IN SCADENZA.',
    );
  });

  test('DASH001 mostra In scadenza e apre il filtro corretto', () {
    final source = File('lib/pages/home_page.dart').readAsStringSync();

    const diarioTitle = "title: 'Diario corsi'";
    const scadutiTitle = "title: 'Scaduti'";

    final diarioIndex = source.indexOf(diarioTitle);
    expect(
      diarioIndex,
      greaterThanOrEqualTo(0),
      reason: 'Badge Diario corsi non trovato.',
    );

    final scadutiIndex = source.indexOf(scadutiTitle, diarioIndex);
    expect(
      scadutiIndex,
      greaterThan(diarioIndex),
      reason: 'Badge Scaduti non trovato dopo Diario corsi.',
    );

    final blocco = source.substring(diarioIndex, scadutiIndex);

    expect(
      blocco,
      contains("title: 'In scadenza'"),
      reason:
          'Il badge tra Diario corsi e Scaduti '
          'deve chiamarsi In scadenza.',
    );

    expect(
      blocco,
      contains("value: kpi['in_scadenza'].toString()"),
      reason:
          'Il badge In scadenza deve usare '
          "kpi['in_scadenza'].",
    );

    expect(
      blocco,
      contains("homeState.filtroScadenze = 'in_scadenza';"),
      reason:
          'Il click sul badge In scadenza deve aprire '
          'Scadenze con filtro in_scadenza.',
    );

    expect(
      blocco,
      isNot(contains("value: kpi['scadenze'].toString()")),
      reason:
          'Il vecchio totale Scadenze non deve più '
          'essere usato in questo badge.',
    );
  });
}
