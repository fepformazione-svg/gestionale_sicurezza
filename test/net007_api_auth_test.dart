import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET007 protegge API discenti con Bearer token', () async {
    const apiToken = 'token-net007-test';

    final server = LanServerService(
      apiToken: apiToken,
      discentiProvider: () async {
        return [
          {
            'id': 1,
            'nome': 'Mario',
            'cognome': 'Rossi',
            'impresa_id': null,
            'nome_impresa': null,
          },
        ];
      },
    );

    await server.start(address: InternetAddress.loopbackIPv4, port: 0);

    final client = HttpClient();

    try {
      Future<(int, dynamic)> getJson(String path, {String? token}) async {
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:${server.port}$path'),
        );

        if (token != null) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }

        final response = await request.close();

        final body = await utf8.decoder.bind(response).join();

        return (response.statusCode, jsonDecode(body));
      }

      final health = await getJson('/health');

      expect(health.$1, HttpStatus.ok);

      expect(health.$2['status'], 'ok');

      final withoutToken = await getJson('/api/discenti');

      expect(withoutToken.$1, HttpStatus.unauthorized);

      expect(withoutToken.$2['error'], 'unauthorized');

      final wrongToken = await getJson('/api/discenti', token: 'token-errato');

      expect(wrongToken.$1, HttpStatus.unauthorized);

      expect(wrongToken.$2['error'], 'unauthorized');

      final correctToken = await getJson('/api/discenti', token: apiToken);

      expect(correctToken.$1, HttpStatus.ok);

      expect(correctToken.$2['sola_lettura'], true);

      expect(correctToken.$2['count'], 1);
    } finally {
      client.close(force: true);

      await server.stop();
    }
  });
}
