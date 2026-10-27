import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/home_page.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET014K-16G HomePage collega intestazione aziendale a Corsi', () async {
    final expectedIntestazione = <String, String>{
      'titolo': 'F&P Formazione e Privacy',
      'sottotitolo': 'F&P S.r.l.s. - P.IVA 01234567890',
      'dettaglio': 'Roma - Tel. 0600000000',
    };

    final runtime = LanClientRuntime.fromConfiguration(
      const LanClientConfiguration(
        baseUrl: 'http://127.0.0.1:8765',
        apiToken: 'token-net014-test',
      ),
      bindingsFactory: (_) {
        return LanClientBindings(
          loadDiscenti: () async => [],
          loadCorsi: () async => [],
          loadIntestazioneAzienda: () async => expectedIntestazione,
          close: () async {},
        );
      },
    );

    try {
      final home = HomePage(lanRuntime: runtime);

      final page = home.buildCorsiPage(globalSearch: 'ponteggi');

      expect(page.modalitaLanSolaLettura, isTrue);

      expect(
        page.lanIntestazioneAziendaProvider,
        same(runtime.intestazioneAziendaProvider),
      );

      final intestazione = await page.lanIntestazioneAziendaProvider!();

      expect(intestazione, expectedIntestazione);
    } finally {
      await runtime.close();
    }
  });

  test('NET014K-16G HomePage locale non collega intestazione LAN', () {
    const home = HomePage();

    final page = home.buildCorsiPage(globalSearch: '');

    expect(page.modalitaLanSolaLettura, isFalse);
    expect(page.lanIntestazioneAziendaProvider, isNull);
  });
}
