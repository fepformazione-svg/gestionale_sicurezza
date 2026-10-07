import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_app_bootstrap.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  group('NET012 bootstrap applicazione LAN', () {
    test('environment vuoto mantiene applicazione locale', () {
      var factoryChiamata = false;

      final runtime = LanAppBootstrap.fromEnvironment(
        const {},
        bindingsFactory: (_) {
          factoryChiamata = true;

          return LanClientBindings(
            loadDiscenti: () async => const [],
            close: () async {},
          );
        },
      );

      expect(runtime, isNull);

      expect(factoryChiamata, isFalse);
    });

    test('configurazione incompleta mantiene applicazione locale', () {
      var factoryChiamata = false;

      final runtime = LanAppBootstrap.fromEnvironment(
        const {'GESTIONALE_SICUREZZA_LAN_URL': 'http://192.168.0.104:8765'},
        bindingsFactory: (_) {
          factoryChiamata = true;

          return LanClientBindings(
            loadDiscenti: () async => const [],
            close: () async {},
          );
        },
      );

      expect(runtime, isNull);

      expect(factoryChiamata, isFalse);
    });

    test('URL e token validi creano runtime LAN', () async {
      var factoryChiamata = false;
      var closeCount = 0;

      final runtime = LanAppBootstrap.fromEnvironment(
        const {
          'GESTIONALE_SICUREZZA_LAN_URL': 'http://192.168.0.104:8765',
          'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
        },
        bindingsFactory: (configuration) {
          factoryChiamata = true;

          expect(configuration.baseUrl, 'http://192.168.0.104:8765');

          expect(configuration.apiToken, 'token-test');

          return LanClientBindings(
            loadDiscenti: () async => const [
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

      expect(runtime, isNotNull);

      expect(runtime!.enabled, isTrue);

      final items = await runtime.discentiProvider!();

      expect(items, hasLength(1));

      expect(items.single['cognome'], 'Rossi');

      await runtime.close();
      await runtime.close();

      expect(closeCount, 1);
    });
  });
}
