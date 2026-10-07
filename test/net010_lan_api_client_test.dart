import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_api_client.dart';

void main() {
  test('NET010 client LAN legge discenti con Bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    final receivedAuthorization = <String?>[];

    server.listen((request) async {
      receivedAuthorization.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );

      if (request.uri.path != '/api/discenti') {
        request.response.statusCode = HttpStatus.notFound;

        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.ok;

      request.response.headers.contentType = ContentType.json;

      request.response.write(
        jsonEncode({
          'sola_lettura': true,
          'count': 1,
          'items': [
            {
              'id': 7,
              'nome': 'Mario',
              'cognome': 'Rossi',
              'impresa_id': 3,
              'nome_impresa': 'Impresa Test',
            },
          ],
        }),
      );

      await request.response.close();
    });

    final client = LanApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiToken: 'token-net010-test',
    );

    try {
      final items = await client.loadDiscenti();

      expect(items.length, 1);

      expect(items.first['id'], 7);

      expect(items.first['nome'], 'Mario');

      expect(items.first['cognome'], 'Rossi');

      expect(items.first['impresa_id'], 3);

      expect(items.first['nome_impresa'], 'Impresa Test');

      expect(receivedAuthorization, ['Bearer token-net010-test']);
    } finally {
      await client.close();

      await server.close(force: true);
    }
  });
}
