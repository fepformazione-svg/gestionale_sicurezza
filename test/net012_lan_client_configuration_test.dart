import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';

void main() {
  group('NET012 configurazione client LAN', () {
    test('nessuna variabile ambiente mantiene modalita locale', () {
      final config = LanClientConfiguration.fromEnvironment(const {});

      expect(config, isNull);
    });

    test('solo URL mantiene modalita locale', () {
      final config = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': 'http://192.168.0.104:8765',
      });

      expect(config, isNull);
    });

    test('solo token mantiene modalita locale', () {
      final config = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
      });

      expect(config, isNull);
    });

    test('URL non valido non attiva LAN', () {
      final config = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': 'indirizzo-non-valido',
        'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
      });

      expect(config, isNull);
    });

    test('URL e token validi attivano configurazione LAN', () {
      final config = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': '  http://192.168.0.104:8765/  ',
        'GESTIONALE_SICUREZZA_LAN_TOKEN': '  token-test  ',
      });

      expect(config, isNotNull);

      expect(config!.baseUrl, 'http://192.168.0.104:8765/');

      expect(config.apiToken, 'token-test');
    });

    test('HTTPS e consentito', () {
      final config = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': 'https://server-lan.local:8765',
        'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
      });

      expect(config, isNotNull);

      expect(config!.baseUrl, 'https://server-lan.local:8765');
    });

    test('token vuoto non attiva LAN', () {
      final config = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': 'http://192.168.0.104:8765',
        'GESTIONALE_SICUREZZA_LAN_TOKEN': '   ',
      });

      expect(config, isNull);
    });
  });
}
