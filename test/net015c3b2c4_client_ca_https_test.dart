import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  group('NET015C3B2C4 configurazione CA client HTTPS', () {
    test('carica URL HTTPS e percorso CA ripulito dagli spazi', () {
      final configuration = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': 'https://FEP:8766',
        'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
        'GESTIONALE_SICUREZZA_LAN_CA_CERT': '  C:/TLS/ca_cert.pem  ',
      });

      expect(configuration, isNotNull);
      expect(Uri.parse(configuration!.baseUrl).host.toLowerCase(), 'fep');
      expect(configuration.caCertificatePath, 'C:/TLS/ca_cert.pem');
    });

    test('HTTP preesistente resta disponibile senza CA', () {
      final configuration = LanClientConfiguration.fromEnvironment(const {
        'GESTIONALE_SICUREZZA_LAN_URL': 'http://192.168.0.104:8765',
        'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
      });

      expect(configuration, isNotNull);
      expect(configuration!.caCertificatePath, isNull);
    });

    test('CA configurata con HTTP e rifiutata', () {
      expect(
        () => LanClientConfiguration.fromEnvironment(const {
          'GESTIONALE_SICUREZZA_LAN_URL': 'http://FEP:8765',
          'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
          'GESTIONALE_SICUREZZA_LAN_CA_CERT': 'C:/TLS/ca_cert.pem',
        }),
        throwsArgumentError,
      );
    });

    test('CA vuota non provoca fallback silenzioso', () {
      expect(
        () => LanClientConfiguration.fromEnvironment(const {
          'GESTIONALE_SICUREZZA_LAN_URL': 'https://FEP:8766',
          'GESTIONALE_SICUREZZA_LAN_TOKEN': 'token-test',
          'GESTIONALE_SICUREZZA_LAN_CA_CERT': '   ',
        }),
        throwsArgumentError,
      );
    });

    test('CA senza URL o token non provoca fallback silenzioso', () {
      expect(
        () => LanClientConfiguration.fromEnvironment(const {
          'GESTIONALE_SICUREZZA_LAN_CA_CERT': 'C:/TLS/ca_cert.pem',
        }),
        throwsArgumentError,
      );
    });

    test('HTTPS con CA privata verificata legge Discenti', () async {
      final certificatePath = File(
        'test/fixtures/net015c3b2c1_test_certificate.pem',
      ).absolute.path;
      final privateKeyPath = File(
        'test/fixtures/net015c3b2c1_test_private_key.pem',
      ).absolute.path;
      final serverContext = SecurityContext()
        ..useCertificateChain(certificatePath)
        ..usePrivateKey(privateKeyPath);
      final server = LanServerService(
        apiToken: 'token-test',
        discentiProvider: () async => [
          {'id': 1, 'nome': 'Mario', 'cognome': 'Rossi'},
        ],
      );
      await server.start(
        address: InternetAddress.loopbackIPv4,
        port: 0,
        securityContext: serverContext,
      );
      LanClientRuntime? runtime;

      try {
        runtime = LanClientRuntime.fromConfiguration(
          LanClientConfiguration(
            baseUrl: 'https://127.0.0.1:${server.port}',
            apiToken: 'token-test',
            caCertificatePath: certificatePath,
          ),
        );
        final items = await runtime.discentiProvider!();
        expect(items, hasLength(1));
        expect(items.single['cognome'], 'Rossi');
      } finally {
        await runtime?.close();
        await server.stop();
      }
    });

    test('HTTPS senza CA rifiuta il certificato privato del server', () async {
      final certificatePath = File(
        'test/fixtures/net015c3b2c1_test_certificate.pem',
      ).absolute.path;
      final privateKeyPath = File(
        'test/fixtures/net015c3b2c1_test_private_key.pem',
      ).absolute.path;
      final serverContext = SecurityContext()
        ..useCertificateChain(certificatePath)
        ..usePrivateKey(privateKeyPath);
      final server = LanServerService(
        apiToken: 'token-test',
        discentiProvider: () async => const [],
      );
      await server.start(
        address: InternetAddress.loopbackIPv4,
        port: 0,
        securityContext: serverContext,
      );
      final runtime = LanClientRuntime.fromConfiguration(
        LanClientConfiguration(
          baseUrl: 'https://127.0.0.1:${server.port}',
          apiToken: 'token-test',
        ),
      );

      try {
        await expectLater(
          runtime.discentiProvider!(),
          throwsA(isA<HandshakeException>()),
        );
      } finally {
        await runtime.close();
        await server.stop();
      }
    });

    test('CA inesistente blocca creazione del runtime HTTPS', () {
      expect(
        () => LanClientRuntime.fromConfiguration(
          const LanClientConfiguration(
            baseUrl: 'https://FEP:8766',
            apiToken: 'token-test',
            caCertificatePath: 'certificato-ca-inesistente.pem',
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
