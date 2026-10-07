import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/discenti_page.dart';
import 'package:gestionale_sicurezza/widgets/app_action_button.dart';

void main() {
  testWidgets(
    'NET011 DiscentiPage usa provider LAN e blocca azioni di scrittura',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1800, 1000);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var chiamateProvider = 0;

      Future<List<Map<String, dynamic>>> provider() async {
        chiamateProvider++;

        return [
          {
            'id': 7,
            'nome': 'Mario',
            'cognome': 'Rossi',
            'impresa_id': 3,
            'nome_impresa': 'Impresa Test',
          },
          {
            'id': 8,
            'nome': 'Luigi',
            'cognome': 'Bianchi',
            'impresa_id': null,
            'nome_impresa': null,
          },
        ];
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1800,
              height: 1000,
              child: DiscentiPage(lanDiscentiProvider: provider),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(chiamateProvider, 1);

      expect(find.text('Mario'), findsOneWidget);

      expect(find.text('Rossi'), findsOneWidget);

      expect(find.text('Impresa Test'), findsOneWidget);

      expect(find.text('Luigi'), findsOneWidget);

      expect(find.text('Modalità LAN sola lettura'), findsOneWidget);

      final nuovoButton = tester.widget<AppActionButton>(
        find.widgetWithText(AppActionButton, 'Nuovo discente'),
      );

      expect(nuovoButton.onPressed, isNull);

      final rows = tester
          .widgetList<DiscenteRow>(find.byType(DiscenteRow))
          .toList();

      expect(rows.length, 2);

      for (final row in rows) {
        expect(row.onModifica, isNull);

        expect(row.onElimina, isNull);

        expect(row.onDoppioClick, isNull);
      }

      final excelButton = tester.widget<AppActionButton>(
        find.widgetWithText(AppActionButton, 'Excel (2)'),
      );

      final pdfButton = tester.widget<AppActionButton>(
        find.widgetWithText(AppActionButton, 'PDF (2)'),
      );

      final stampaButton = tester.widget<AppActionButton>(
        find.widgetWithText(AppActionButton, 'Stampa (2)'),
      );

      expect(excelButton.onPressed, isNull);

      expect(pdfButton.onPressed, isNull);

      expect(stampaButton.onPressed, isNull);
    },
  );
}
