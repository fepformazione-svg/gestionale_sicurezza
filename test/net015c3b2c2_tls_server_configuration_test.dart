import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_tls_server_configuration.dart';

void main() {
  test('NET015C3B2C2 senza parametri mantiene HTTP', () {
    expect(LanTlsServerConfiguration.fromFiles(), isNull);
  });

  test('NET015C3B2C2 certificato senza chiave non è ammesso', () {
    expect(
      () => LanTlsServerConfiguration.fromFiles(
        certificatePath: 'certificato.pem',
      ),
      throwsArgumentError,
    );
  });

  test('NET015C3B2C2 chiave senza certificato non è ammessa', () {
    expect(
      () => LanTlsServerConfiguration.fromFiles(privateKeyPath: 'chiave.pem'),
      throwsArgumentError,
    );
  });

  test('NET015C3B2C2 percorsi vuoti non sono ammessi', () {
    expect(
      () => LanTlsServerConfiguration.fromFiles(
        certificatePath: '  ',
        privateKeyPath: '  ',
      ),
      throwsArgumentError,
    );
  });

  test('NET015C3B2C2 file TLS assenti vengono rifiutati', () {
    expect(
      () => LanTlsServerConfiguration.fromFiles(
        certificatePath: 'test/percorso_inesistente/net015_cert.pem',
        privateKeyPath: 'test/percorso_inesistente/net015_key.pem',
      ),
      throwsArgumentError,
    );
  });

  test('NET015C3B2C2 carica la coppia PEM di test', () {
    final certificatePath = File(
      'test/fixtures/net015c3b2c1_test_certificate.pem',
    ).absolute.path;
    final privateKeyPath = File(
      'test/fixtures/net015c3b2c1_test_private_key.pem',
    ).absolute.path;

    expect(
      LanTlsServerConfiguration.fromFiles(
        certificatePath: certificatePath,
        privateKeyPath: privateKeyPath,
      ),
      isA<SecurityContext>(),
    );
  });
}
