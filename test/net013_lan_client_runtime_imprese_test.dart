import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET013 runtime LAN collega provider imprese', () async {
    final configuration = LanClientConfiguration(
      baseUrl: 'http://192.168.0.104:8765',
      apiToken: 'token-net013-test',
    );

    final runtime = LanClientRuntime.fromConfiguration(
      configuration,
      bindingsFactory: (receivedConfiguration) {
        expect(receivedConfiguration.baseUrl, configuration.baseUrl);

        expect(receivedConfiguration.apiToken, configuration.apiToken);

        return LanClientBindings(
          loadDiscenti: () async => const [],
          loadImprese: () async => [
            {
              'id': 11,
              'intestazione': 'Alfa S.r.l.',
              'partita_iva': '11111111111',
              'codice_fiscale': 'CFALFA',
              'indirizzo': 'Via Alfa 1',
              'telefono': '0200000001',
              'referente': 'Luigi Bianchi',
            },
          ],
          close: () async {},
        );
      },
    );

    expect(runtime.enabled, isTrue);

    expect(runtime.impreseProvider, isNotNull);

    final items = await runtime.impreseProvider!();

    expect(items, hasLength(1));

    expect(items.single['id'], 11);

    expect(items.single['intestazione'], 'Alfa S.r.l.');

    expect(items.single.keys.toSet(), <String>{
      'id',
      'intestazione',
      'partita_iva',
      'codice_fiscale',
      'indirizzo',
      'telefono',
      'referente',
    });

    await runtime.close();
  });

  test('NET013 runtime disabilitato non espone provider imprese', () async {
    final runtime = LanClientRuntime.fromConfiguration(null);

    expect(runtime.enabled, isFalse);

    expect(runtime.impreseProvider, isNull);

    await runtime.close();
  });
}
