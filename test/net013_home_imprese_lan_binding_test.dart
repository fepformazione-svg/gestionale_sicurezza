import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/pages/home_page.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';

void main() {
  test('NET013 HomePage usa il runtime LAN per Imprese', () async {
    Future<List<Map<String, dynamic>>> impreseProvider() async {
      return const [
        {
          'id': 11,
          'intestazione': 'Alfa S.r.l.',
          'partita_iva': '11111111111',
          'codice_fiscale': 'CFALFA',
          'indirizzo': 'Via Alfa 1',
          'telefono': '0200000001',
          'referente': 'Luigi Bianchi',
        },
      ];
    }

    const configuration = LanClientConfiguration(
      baseUrl: 'http://192.168.0.104:8765',
      apiToken: 'token-net013-test',
    );

    final runtime = LanClientRuntime.fromConfiguration(
      configuration,
      bindingsFactory: (_) {
        return LanClientBindings(
          loadDiscenti: () async => const [],
          loadImprese: impreseProvider,
          close: () async {},
        );
      },
    );

    final home = HomePage(lanRuntime: runtime);

    final page = home.buildImpresePage(globalSearch: 'alfa');

    expect(page.globalSearch, 'alfa');

    expect(page.lanImpreseProvider, same(runtime.impreseProvider));

    final items = await page.lanImpreseProvider!();

    expect(items, hasLength(1));

    expect(items.single['intestazione'], 'Alfa S.r.l.');

    await runtime.close();
  });

  test('NET013 HomePage senza runtime mantiene Imprese locale', () {
    const home = HomePage();

    final page = home.buildImpresePage(globalSearch: '');

    expect(page.lanImpreseProvider, isNull);
  });
}
