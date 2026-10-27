import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/corsi_page.dart';
import 'package:gestionale_sicurezza/widgets/app_action_button.dart';

void main() {
  testWidgets('NET014J Corsi LAN disabilita le modifiche', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<List<Map<String, dynamic>>> provider() async {
      return const [
        {
          'id': 7,
          'denominazione': 'PONTEGGI - 28 ORE',
          'durata_ore': 28,
          'validita_anni': 4,
        },
      ];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1600,
            height: 900,
            child: CorsiPage(lanCorsiProvider: provider),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PONTEGGI - 28 ORE'), findsWidgets);

    expect(find.text('Modalit\u00E0 LAN sola lettura'), findsOneWidget);

    final nuovoButton = tester.widget<AppActionButton>(
      find.widgetWithText(AppActionButton, 'Nuovo corso'),
    );

    expect(nuovoButton.onPressed, isNull);

    final modificaRiga = find.ancestor(
      of: find.text('PONTEGGI - 28 ORE'),
      matching: find.byType(InkWell),
    );

    expect(modificaRiga, findsWidgets);

    final inkWell = tester.widget<InkWell>(modificaRiga.first);

    expect(inkWell.onDoubleTap, isNull);

    for (final icona in [
      Icons.hub_outlined,
      Icons.description_outlined,
      Icons.edit_rounded,
      Icons.delete_outline,
    ]) {
      final pulsante = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, icona),
      );

      expect(pulsante.onPressed, isNull);
    }

    final excelButton = tester.widget<AppActionButton>(
      find.widgetWithText(AppActionButton, 'Excel (1)'),
    );

    expect(excelButton.onPressed, isNotNull);
  });
}
