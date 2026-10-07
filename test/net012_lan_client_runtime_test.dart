import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  group('NET012 runtime client LAN', () {
    test('configurazione assente non crea il client', () async {
      var factoryChiamata = false;

      final runtime = LanClientRuntime.fromConfiguration(
        null,
        bindingsFactory: (configuration) {
          factoryChiamata = true;

          return LanClientBindings(
            loadDiscenti: () async => const [],
            close: () async {},
          );
        },
      );

      expect(factoryChiamata, isFalse);

      expect(runtime.enabled, isFalse);

      expect(runtime.discentiProvider, isNull);

      await runtime.close();

      expect(factoryChiamata, isFalse);
    });

    test('configurazione presente collega provider e lifecycle', () async {
      var factoryChiamata = false;
      var closeCount = 0;

      final configuration = LanClientConfiguration(
        baseUrl: 'http://192.168.0.104:8765',
        apiToken: 'token-test',
      );

      final runtime = LanClientRuntime.fromConfiguration(
        configuration,
        bindingsFactory: (receivedConfiguration) {
          factoryChiamata = true;

          expect(receivedConfiguration.baseUrl, configuration.baseUrl);

          expect(receivedConfiguration.apiToken, configuration.apiToken);

          return LanClientBindings(
            loadDiscenti: () async => [
              {
                'id': 1,
                'nome': 'Mario',
                'cognome': 'Rossi',
                'impresa_id': null,
                'nome_impresa': null,
              },
            ],
            close: () async {
              closeCount++;
            },
          );
        },
      );

      expect(factoryChiamata, isTrue);

      expect(runtime.enabled, isTrue);

      expect(runtime.discentiProvider, isNotNull);

      final items = await runtime.discentiProvider!();

      expect(items, hasLength(1));

      expect(items.single['cognome'], 'Rossi');

      await runtime.close();
      await runtime.close();

      expect(closeCount, 1);
    });
  });
}
