import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/main.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET012 MyApp passa runtime LAN a HomePage', () {
    const configuration = LanClientConfiguration(
      baseUrl: 'http://192.168.0.104:8765',
      apiToken: 'token-test',
    );

    final runtime = LanClientRuntime.fromConfiguration(
      configuration,
      bindingsFactory: (_) {
        return LanClientBindings(
          loadDiscenti: () async => const [],
          close: () async {},
        );
      },
    );

    final app = MyApp(lanRuntime: runtime);

    final home = app.buildHomePage();

    expect(home.lanRuntime, same(runtime));
  });

  test('NET012 MyApp senza runtime mantiene HomePage locale', () {
    const app = MyApp();

    final home = app.buildHomePage();

    expect(home.lanRuntime, isNull);
  });
}
