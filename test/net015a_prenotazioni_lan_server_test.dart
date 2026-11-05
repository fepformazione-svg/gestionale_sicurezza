import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET015A2 endpoint Prenotazioni autenticato e paginato', () async {
    final richieste = <Map<String, Object>>[];
    final server = LanServerService(
      apiToken: 'token-test-net015a',
      prenotazioniProvider:
          ({
            required int limit,
            required int offset,
            required String ricerca,
            required String filtro,
          }) async {
            richieste.add({
              'limit': limit,
              'offset': offset,
              'ricerca': ricerca,
              'filtro': filtro,
            });
            return <String, dynamic>{
              'items': <Map<String, dynamic>>[
                {
                  'id': 12,
                  'discente_nome': 'Mario',
                  'discente_cognome': 'Rossi',
                  'attrezzature_sintesi': 'Imbracatura x2',
                },
              ],
              'conteggi': <String, int>{'tutte': 2, 'aperte': 1},
            };
          },
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();
    final host = InternetAddress.loopbackIPv4.address;

    try {
      final denied = await client.get(host, server.port, '/api/prenotazioni');
      final deniedResponse = await denied.close();
      expect(deniedResponse.statusCode, HttpStatus.unauthorized);
      await deniedResponse.transform(utf8.decoder).join();

      final invalid = await client.get(
        host,
        server.port,
        '/api/prenotazioni?limit=101',
      );
      invalid.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer token-test-net015a',
      );
      final invalidResponse = await invalid.close();
      expect(invalidResponse.statusCode, HttpStatus.badRequest);
      await invalidResponse.transform(utf8.decoder).join();
      expect(richieste, isEmpty);

      final request = await client.get(
        host,
        server.port,
        '/api/prenotazioni?limit=2&offset=5&ricerca=Rossi&filtro=aperte',
      );
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer token-test-net015a',
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      expect(response.statusCode, HttpStatus.ok);
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded['sola_lettura'], true);
      expect(decoded['count'], 1);
      expect(decoded['limit'], 2);
      expect(decoded['offset'], 5);
      expect(decoded['conteggi'], {'tutte': 2, 'aperte': 1});
      expect((decoded['items'] as List<dynamic>).single['id'], 12);
      expect(richieste, [
        {'limit': 2, 'offset': 5, 'ricerca': 'Rossi', 'filtro': 'aperte'},
      ]);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015A2 endpoint senza provider restituisce 503', () async {
    final server = LanServerService(apiToken: 'token-test-net015a');
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();
    try {
      final request = await client.get(
        InternetAddress.loopbackIPv4.address,
        server.port,
        '/api/prenotazioni',
      );
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer token-test-net015a',
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.serviceUnavailable);
      await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
