import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET014B GET /api/corsi espone corsi in sola lettura', () async {
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

    final client = HttpClient();

    try {
      final request = await client.get(
        InternetAddress.loopbackIPv4.address,
        server.port,
        '/api/corsi',
      );

      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer token-test-net014',
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/json');

      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['sola_lettura'], true);
      expect(json['count'], 1);

      final items = json['items'] as List<dynamic>;

      expect(items.length, 1);

      final corso = items.first as Map<String, dynamic>;

      expect(corso['id'], 7);
      expect(corso['denominazione'], 'PONTEGGI - 28 ORE');
      expect(corso['durata_ore'], 28);
      expect(corso['validita_anni'], 4);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
