import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET001D health endpoint risponde OK in JSON', () async {
    final server = LanServerService();

    await server.start(
      address: InternetAddress.loopbackIPv4,
      port: 0,
    );

    final client = HttpClient();

    try {
      final request = await client.get(
        InternetAddress.loopbackIPv4.address,
        server.port,
        '/health',
      );

      final response = await request.close();

      final body = await response
          .transform(utf8.decoder)
          .join();

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers.contentType?.mimeType,
        'application/json',
      );

      final json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(json['status'], 'ok');
      expect(
        json['service'],
        'gestionale_sicurezza',
      );
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
