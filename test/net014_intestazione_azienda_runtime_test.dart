import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET014K-15 runtime LAN collega intestazione aziendale', () async {
    final expectedIntestazione = <String, String>{
      'titolo': 'F&P Formazione e Privacy',
      'sottotitolo': 'F&P S.r.l.s. - P.IVA 01234567890',
      'dettaglio': 'Roma - Tel. 0600000000',
    };

    var closeCount = 0;

    final runtime = LanClientRuntime.fromConfiguration(
      const LanClientConfiguration(
        baseUrl: 'http://127.0.0.1:8765',
        apiToken: 'token-test-net014',
      ),
      bindingsFactory: (configuration) {
        expect(configuration.apiToken, 'token-test-net014');

        return LanClientBindings(
          loadDiscenti: () async => [],
          loadIntestazioneAzienda: () async => expectedIntestazione,
          close: () async {
            closeCount++;
          },
        );
      },
    );

    expect(runtime.enabled, true);
    expect(runtime.intestazioneAziendaProvider, isNotNull);

    final intestazione = await runtime.intestazioneAziendaProvider!();

    expect(intestazione, expectedIntestazione);

    await runtime.close();
    await runtime.close();

    expect(closeCount, 1);
  });

  test('NET014K-15 senza LAN intestazione aziendale assente', () async {
    final runtime = LanClientRuntime.fromConfiguration(null);

    expect(runtime.enabled, false);
    expect(runtime.intestazioneAziendaProvider, isNull);

    await runtime.close();
  });
}
