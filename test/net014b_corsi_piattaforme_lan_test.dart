import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/pages/corsi_page.dart';

void main() {
  testWidgets('NET014B cerca corsi LAN tramite codice piattaforma', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final page = CorsiPage(
      globalSearch: 'PON-28',
      lanCorsiProvider: () async => [
        {
          'id': 7,
          'denominazione': 'PONTEGGI - 28 ORE',
          'durata_ore': 28,
          'validita_anni': 4,
          'piattaforme': [
            {
              'id': 11,
              'corso_id': 7,
              'piattaforma': 'OPN',
              'codice': 'PON-28',
              'note': 'Codice attivo',
              'attivo': 1,
            },
          ],
        },
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 1600, height: 900, child: page)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PONTEGGI - 28 ORE'), findsWidgets);
    expect(find.textContaining('PON-28'), findsWidgets);
  });
}
