import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/pages/home_page.dart';
import 'package:gestionale_sicurezza/pages/prenotazioni_lan_page.dart';
import 'package:gestionale_sicurezza/pages/prenotazioni_page.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  const configurazione = LanClientConfiguration(
    baseUrl: 'http://127.0.0.1:8765',
    apiToken: 'token-test-net015b2b',
  );

  test(
    'NET015B2B Home LAN collega provider Prenotazioni sola lettura',
    () async {
      final runtime = LanClientRuntime.fromConfiguration(
        configurazione,
        bindingsFactory: (_) => LanClientBindings(
          loadDiscenti: () async => <Map<String, dynamic>>[],
          loadPrenotazioni:
              ({
                required int limit,
                required int offset,
                required String ricerca,
                required String filtro,
              }) async => <String, dynamic>{
                'items': <Map<String, dynamic>>[],
                'conteggi': <String, int>{'tutte': 0},
              },
          close: () async {},
        ),
      );

      try {
        final pagina = HomePage(
          lanRuntime: runtime,
        ).buildPrenotazioniPage(globalSearch: 'rossi', filtro: 'aperte');

        expect(pagina, isA<PrenotazioniLanPage>());
        final paginaLan = pagina as PrenotazioniLanPage;
        expect(paginaLan.globalSearch, 'rossi');
        expect(paginaLan.filtro, 'aperte');
        expect(paginaLan.prenotazioniProvider, isNotNull);
      } finally {
        await runtime.close();
      }
    },
  );

  test('NET015B2B LAN senza provider non apre Prenotazioni locali', () async {
    final runtime = LanClientRuntime.fromConfiguration(
      configurazione,
      bindingsFactory: (_) => LanClientBindings(
        loadDiscenti: () async => <Map<String, dynamic>>[],
        close: () async {},
      ),
    );

    try {
      final pagina = HomePage(
        lanRuntime: runtime,
      ).buildPrenotazioniPage(globalSearch: '', filtro: 'tutte');

      expect(pagina, isA<PrenotazioniLanPage>());
      expect((pagina as PrenotazioniLanPage).prenotazioniProvider, isNull);
    } finally {
      await runtime.close();
    }
  });

  test('NET015B2B Home locale mantiene Prenotazioni operative', () {
    final pagina = const HomePage().buildPrenotazioniPage(
      globalSearch: '',
      filtro: 'tutte',
    );

    expect(pagina, isA<PrenotazioniPage>());
  });
}
