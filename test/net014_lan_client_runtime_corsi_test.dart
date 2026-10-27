import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET014G runtime LAN collega il provider Corsi', () async {
    final expectedCorsi = <Map<String, dynamic>>[
      {
        'id': 7,
        'denominazione': 'PONTEGGI - 28 ORE',
        'durata_ore': 28,
        'validita_anni': 4,
      },
    ];

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
          loadCorsi: () async => expectedCorsi,
          close: () async {
            closeCount++;
          },
        );
      },
    );

    expect(runtime.enabled, true);
    expect(runtime.corsiProvider, isNotNull);

    final corsi = await runtime.corsiProvider!();

    expect(corsi, expectedCorsi);

    await runtime.close();
    await runtime.close();

    expect(closeCount, 1);
  });

  test('NET014G senza LAN il provider Corsi e assente', () async {
    final runtime = LanClientRuntime.fromConfiguration(null);

    expect(runtime.enabled, false);
    expect(runtime.corsiProvider, isNull);

    await runtime.close();
  });
}
