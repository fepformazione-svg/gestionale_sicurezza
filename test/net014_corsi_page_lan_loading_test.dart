import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/corsi_page.dart';

void main() {
  testWidgets('NET014I Corsi LAN carica i dati dal provider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    var providerCalls = 0;

    Future<List<Map<String, dynamic>>> provider() async {
      providerCalls++;

      return const [
        {
          'id': 7,
          'denominazione': 'PONTEGGI - 28 ORE',
          'durata_ore': 28,
          'validita_anni': 4,
        },
      ];
    }

    final page = CorsiPage(
      globalSearch: 'ponteggi',
      lanCorsiProvider: provider,
    );

    expect(page.modalitaLanSolaLettura, true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 1600, height: 900, child: page)),
      ),
    );

    await tester.pumpAndSettle();

    expect(providerCalls, 1);

    expect(find.text('PONTEGGI - 28 ORE'), findsWidgets);
  });

  test('NET014I senza provider Corsi mantiene modalita locale', () {
    const page = CorsiPage();

    expect(page.modalitaLanSolaLettura, false);
    expect(page.lanCorsiProvider, isNull);
  });
}
