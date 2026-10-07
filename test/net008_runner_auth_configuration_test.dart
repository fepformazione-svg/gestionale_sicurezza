import 'package:flutter_test/flutter_test.dart';

import '../bin/lan_server.dart' as runner;

void main() {
  test('NET008 runner vieta database configurato senza token', () {
    expect(
      () => runner.validateLanServerConfiguration(
        databasePath: r'C:\dati\gestionale_sicurezza.db',
        apiToken: null,
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(
      () => runner.validateLanServerConfiguration(
        databasePath: r'C:\dati\gestionale_sicurezza.db',
        apiToken: '',
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(
      () => runner.validateLanServerConfiguration(
        databasePath: r'C:\dati\gestionale_sicurezza.db',
        apiToken: '   ',
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(
      () => runner.validateLanServerConfiguration(
        databasePath: r'C:\dati\gestionale_sicurezza.db',
        apiToken: 'token-valido-net008',
      ),
      returnsNormally,
    );

    expect(
      () => runner.validateLanServerConfiguration(
        databasePath: null,
        apiToken: null,
      ),
      returnsNormally,
    );
  });
}
