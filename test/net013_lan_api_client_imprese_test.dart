import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/lan_api_client.dart';

void main() {
  test('NET013 client LAN legge imprese con Bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    final receivedAuthorization = <String?>[];
    final receivedPaths = <String>[];

    server.listen((request) async {
      receivedAuthorization.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );

      receivedPaths.add(request.uri.path);

      if (request.uri.path != '/api/imprese') {
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
              'id': 11,
              'intestazione': 'Alfa S.r.l.',
              'partita_iva': '11111111111',
              'codice_fiscale': 'CFALFA',
              'indirizzo': 'Via Alfa 1',
              'telefono': '0200000001',
              'referente': 'Luigi Bianchi',
            },
          ],
        }),
      );

      await request.response.close();
    });

    final client = LanApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiToken: 'token-net013-test',
    );

    try {
      final items = await client.loadImprese();

      expect(items, hasLength(1));

      expect(receivedPaths, <String>['/api/imprese']);

      expect(receivedAuthorization, <String>['Bearer token-net013-test']);

      expect(items.first, <String, dynamic>{
        'id': 11,
        'intestazione': 'Alfa S.r.l.',
        'partita_iva': '11111111111',
        'codice_fiscale': 'CFALFA',
        'indirizzo': 'Via Alfa 1',
        'telefono': '0200000001',
        'referente': 'Luigi Bianchi',
      });

      expect(() => items.add(<String, dynamic>{}), throwsUnsupportedError);
    } finally {
      await client.close();
      await server.close(force: true);
    }
  });
}
