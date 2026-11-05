import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/pages/prenotazioni_lan_page.dart';

void main() {
  testWidgets('NET015B2A vista LAN espone solo consultazione e filtri', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final richieste = <Map<String, Object>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PrenotazioniLanPage(
          prenotazioniProvider:
              ({
                required int limit,
                required int offset,
                required String ricerca,
                required String filtro,
              }) async {
                richieste.add({
                  'limit': limit,
                  'offset': offset,
                  'ricerca': ricerca,
                  'filtro': filtro,
                });
                return <String, dynamic>{
                  'items': <Map<String, dynamic>>[
                    {
                      'id': 19,
                      'discente_nome': 'Mario',
                      'discente_cognome': 'Rossi',
                      'impresa_nome': 'Impresa Test',
                      'corso_nome': 'PONTEGGI - 28 ORE',
                      'data': '2026-11-05',
                      'prot': 'P-019',
                      'aperto': 1,
                      'conferma': 0,
                      'registro': 0,
                      'attrezzature_sintesi': 'Imbracatura x2',
                    },
                  ],
                  'conteggi': <String, int>{'tutte': 1, 'aperte': 1},
                };
              },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('LAN - SOLA LETTURA'), findsOneWidget);
    expect(find.text('Rossi Mario'), findsOneWidget);
    expect(find.text('PONTEGGI - 28 ORE'), findsOneWidget);
    expect(find.text('Imbracatura x2'), findsOneWidget);
    expect(find.text('APERTO'), findsOneWidget);
    expect(find.text('Nuova prenotazione'), findsNothing);
    expect(find.text('Elimina'), findsNothing);
    expect(richieste.single, {
      'limit': 50,
      'offset': 0,
      'ricerca': '',
      'filtro': 'tutte',
    });

    await tester.tap(find.text('Aperte (1)'));
    await tester.pumpAndSettle();
    expect(richieste.last['filtro'], 'aperte');
  });

  testWidgets('NET015B2A provider mancante non usa database locale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: PrenotazioniLanPage(prenotazioniProvider: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('LAN - SOLA LETTURA'), findsOneWidget);
    expect(
      find.text('Servizio Prenotazioni LAN non disponibile.'),
      findsOneWidget,
    );
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Nuova prenotazione'), findsNothing);
  });
}
