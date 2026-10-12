import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

Future<Map<String, dynamic>> readJson(HttpClientResponse response) async {
  final body = await response.transform(utf8.decoder).join();

  return jsonDecode(body) as Map<String, dynamic>;
}

void main() {
  test(
    'NET013 - /api/imprese richiede token e restituisce solo dati consentiti',
    () async {
      const token = 'token-net013-test';

      final server = LanServerService(
        apiToken: token,
        impreseProvider: () async {
          return <Map<String, dynamic>>[
            {
              'id': 1,
              'intestazione': 'Alfa S.r.l.',
              'partita_iva': '11111111111',
              'codice_fiscale': 'CFALFA',
              'indirizzo': 'Via Alfa 1',
              'telefono': '0200000001',
              'referente': 'Luigi Bianchi',
            },
          ];
        },
      );

      await server.start(address: InternetAddress.loopbackIPv4, port: 0);

      final client = HttpClient();

      try {
        final host = InternetAddress.loopbackIPv4.address;

        // /health deve restare pubblico.
        final healthRequest = await client.get(host, server.port, '/health');

        final healthResponse = await healthRequest.close();

        final healthJson = await readJson(healthResponse);

        expect(healthResponse.statusCode, HttpStatus.ok);

        expect(healthJson['status'], 'ok');

        // Senza token -> 401.
        final noTokenRequest = await client.get(
          host,
          server.port,
          '/api/imprese',
        );

        final noTokenResponse = await noTokenRequest.close();

        final noTokenJson = await readJson(noTokenResponse);

        expect(noTokenResponse.statusCode, HttpStatus.unauthorized);

        expect(noTokenJson['error'], 'unauthorized');

        // Token errato -> 401.
        final wrongTokenRequest = await client.get(
          host,
          server.port,
          '/api/imprese',
        );

        wrongTokenRequest.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer token-errato',
        );

        final wrongTokenResponse = await wrongTokenRequest.close();

        final wrongTokenJson = await readJson(wrongTokenResponse);

        expect(wrongTokenResponse.statusCode, HttpStatus.unauthorized);

        expect(wrongTokenJson['error'], 'unauthorized');

        // Token corretto -> 200.
        final okRequest = await client.get(host, server.port, '/api/imprese');

        okRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

        final okResponse = await okRequest.close();

        final okJson = await readJson(okResponse);

        expect(okResponse.statusCode, HttpStatus.ok);

        expect(okJson['sola_lettura'], isTrue);

        expect(okJson['count'], 1);

        final items = okJson['items'] as List<dynamic>;

        expect(items, hasLength(1));

        final item = Map<String, dynamic>.from(items.first as Map);

        expect(item.keys.toSet(), <String>{
          'id',
          'intestazione',
          'partita_iva',
          'codice_fiscale',
          'indirizzo',
          'telefono',
          'referente',
        });

        expect(
          item.containsKey('informativa_privacy_impresa_firmata'),
          isFalse,
        );

        expect(item.containsKey('documento_privacy_impresa_path'), isFalse);

        expect(item.containsKey('note_privacy_impresa'), isFalse);
      } finally {
        client.close(force: true);
        await server.stop();
      }
    },
  );
}
