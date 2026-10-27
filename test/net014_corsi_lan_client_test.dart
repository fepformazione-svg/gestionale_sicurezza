import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_api_client.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET014F client LAN carica corsi autenticati', () async {
    final server = LanServerService(
      apiToken: 'token-test-net014',
      corsiProvider: () async {
        return [
          {
            'id': 7,
            'denominazione': 'PONTEGGI - 28 ORE',
            'durata_ore': 28,
            'validita_anni': 4,
          },
        ];
      },
    );

    await server.start(address: InternetAddress.loopbackIPv4, port: 0);

    final client = LanApiClient(
      baseUrl: 'http://${InternetAddress.loopbackIPv4.address}:${server.port}',
      apiToken: 'token-test-net014',
    );

    try {
      final corsi = await client.loadCorsi();

      expect(corsi.length, 1);

      expect(corsi.single, {
        'id': 7,
        'denominazione': 'PONTEGGI - 28 ORE',
        'durata_ore': 28,
        'validita_anni': 4,
      });
    } finally {
      await client.close();
      await server.stop();
    }
  });
}
