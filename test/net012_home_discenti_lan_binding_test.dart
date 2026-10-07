import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/home_page.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET012 HomePage usa il runtime LAN per Discenti', () async {
    Future<List<Map<String, dynamic>>> provider() async {
      return const [
        {
          'id': 1,
          'nome': 'Mario',
          'cognome': 'Rossi',
          'impresa_id': null,
          'nome_impresa': null,
        },
      ];
    }

    var closeCount = 0;

    const configuration = LanClientConfiguration(
      baseUrl: 'http://192.168.0.104:8765',
      apiToken: 'token-test',
    );

    final runtime = LanClientRuntime.fromConfiguration(
      configuration,
      bindingsFactory: (_) {
        return LanClientBindings(
          loadDiscenti: provider,
          close: () async {
            closeCount++;
          },
        );
      },
    );

    final home = HomePage(lanRuntime: runtime);

    final page = home.buildDiscentiPage(globalSearch: 'rossi');

    expect(page.globalSearch, 'rossi');

    expect(page.lanDiscentiProvider, same(runtime.discentiProvider));

    final items = await page.lanDiscentiProvider!();

    expect(items.single['cognome'], 'Rossi');

    await runtime.close();

    expect(closeCount, 1);
  });

  test('NET012 HomePage senza runtime mantiene Discenti locale', () {
    const home = HomePage();

    final page = home.buildDiscentiPage(globalSearch: '');

    expect(page.lanDiscentiProvider, isNull);
  });
}
