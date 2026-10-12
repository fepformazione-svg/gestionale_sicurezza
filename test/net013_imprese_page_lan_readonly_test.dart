import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/imprese_page.dart';
import 'package:gestionale_sicurezza/widgets/app_action_button.dart';

void main() {
  testWidgets('NET013 Imprese LAN usa provider e resta sola lettura', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<List<Map<String, dynamic>>> provider() async {
      return const [
        {
          'id': 11,
          'intestazione': 'Alfa S.r.l.',
          'partita_iva': '11111111111',
          'codice_fiscale': 'CFALFA',
          'indirizzo': 'Via Alfa 1',
          'telefono': '0200000001',
          'referente': 'Luigi Bianchi',
        },
      ];
    }

    final page = ImpresePage(lanImpreseProvider: provider);

    expect(page.lanImpreseProvider, same(provider));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 1600, height: 900, child: page)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alfa S.r.l.'), findsOneWidget);

    expect(find.text('Modalit\u00E0 LAN sola lettura'), findsOneWidget);

    final nuovoFinder = find.widgetWithText(AppActionButton, 'Nuova impresa');

    expect(nuovoFinder, findsOneWidget);

    final nuovoButton = tester.widget<AppActionButton>(nuovoFinder);

    expect(nuovoButton.onPressed, isNull);

    // Export e stampa devono restare disponibili.
    final excelButton = tester.widget<AppActionButton>(
      find.widgetWithText(AppActionButton, 'Excel (1)'),
    );

    final pdfButton = tester.widget<AppActionButton>(
      find.widgetWithText(AppActionButton, 'PDF (1)'),
    );

    final stampaButton = tester.widget<AppActionButton>(
      find.widgetWithText(AppActionButton, 'Stampa (1)'),
    );

    expect(excelButton.onPressed, isNotNull);

    expect(pdfButton.onPressed, isNotNull);

    expect(stampaButton.onPressed, isNotNull);

    // La riga impresa non deve aprire la scheda in LAN.
    final inkWellFinder = find.ancestor(
      of: find.text('Alfa S.r.l.'),
      matching: find.byType(InkWell),
    );

    expect(inkWellFinder, findsWidgets);

    final inkWell = tester.widget<InkWell>(inkWellFinder.first);

    expect(inkWell.onDoubleTap, isNull);
  });
}
