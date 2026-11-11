import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test('NET015C3B2C1 HTTP rimane disponibile senza contesto TLS', () async {
    final server = LanServerService();
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri(
          scheme: 'http',
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          path: '/health',
        ),
      );
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(
        jsonDecode(body) as Map<String, dynamic>,
        containsPair('status', 'ok'),
      );
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C3B2C1 HTTPS usa un certificato attendibile di test', () async {
    // Certificato e chiave sono pubblici, esclusivamente per test su loopback.
    // Non impiegarli mai per il server operativo.
    final certificatePath = File(
      'test/fixtures/net015c3b2c1_test_certificate.pem',
    ).absolute.path;
    final privateKeyPath = File(
      'test/fixtures/net015c3b2c1_test_private_key.pem',
    ).absolute.path;

    final serverContext = SecurityContext()
      ..useCertificateChain(certificatePath)
      ..usePrivateKey(privateKeyPath);

    final clientContext = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificates(certificatePath);

    final server = LanServerService();
    await server.start(
      address: InternetAddress.loopbackIPv4,
      port: 0,
      securityContext: serverContext,
    );
    final client = HttpClient(context: clientContext);

    try {
      final request = await client.getUrl(
        Uri(
          scheme: 'https',
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          path: '/health',
        ),
      );
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(
        jsonDecode(body) as Map<String, dynamic>,
        containsPair('status', 'ok'),
      );
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
