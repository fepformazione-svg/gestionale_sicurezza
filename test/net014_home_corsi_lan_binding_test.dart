import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/home_page.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET014H HomePage collega Corsi al runtime LAN', () async {
    Future<List<Map<String, dynamic>>> corsiProvider() async {
      return const [
        {
          'id': 7,
          'denominazione': 'PONTEGGI - 28 ORE',
          'durata_ore': 28,
          'validita_anni': 4,
        },
      ];
    }

    const configuration = LanClientConfiguration(
      baseUrl: 'http://127.0.0.1:8765',
      apiToken: 'token-net014-test',
    );

    final runtime = LanClientRuntime.fromConfiguration(
      configuration,
      bindingsFactory: (_) {
        return LanClientBindings(
          loadDiscenti: () async => const [],
          loadCorsi: corsiProvider,
          close: () async {},
        );
      },
    );

    final home = HomePage(lanRuntime: runtime);

    final page = home.buildCorsiPage(globalSearch: 'ponteggi');

    expect(page.globalSearch, 'ponteggi');
    expect(page.lanCorsiProvider, same(runtime.corsiProvider));

    final items = await page.lanCorsiProvider!();

    expect(items, hasLength(1));
    expect(items.single['denominazione'], 'PONTEGGI - 28 ORE');

    await runtime.close();
  });

  test('NET014H HomePage senza LAN mantiene Corsi locale', () {
    const home = HomePage();

    final page = home.buildCorsiPage(globalSearch: '');

    expect(page.lanCorsiProvider, isNull);
  });
}
