import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET003 GET /api/discenti espone dati in sola lettura', () async {
    final server = LanServerService(
      discentiProvider: () async {
        return [
          {
            'id': 7,
            'nome': 'Mario',
            'cognome': 'Rossi',
            'codice_fiscale': 'RSSMRA80A01H501U',
            'nome_impresa': 'Impresa Demo',
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
        '/api/discenti',
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

      final primo = items.first as Map<String, dynamic>;

      expect(primo['id'], 7);

      expect(primo['nome'], 'Mario');

      expect(primo['cognome'], 'Rossi');

      expect(primo['nome_impresa'], 'Impresa Demo');
    } finally {
      client.close(force: true);

      await server.stop();
    }
  });
}
