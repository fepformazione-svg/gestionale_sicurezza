import 'dart:io';

/// Configura TLS solo quando certificato e chiave sono presenti insieme.
///
/// I percorsi devono puntare a file esterni al repository; non utilizzare
/// mai le credenziali PEM contenute nelle fixture dei test in produzione.
class LanTlsServerConfiguration {
  LanTlsServerConfiguration._();

  static SecurityContext? fromFiles({
    String? certificatePath,
    String? privateKeyPath,
  }) {
    final certificate = certificatePath?.trim();
    final privateKey = privateKeyPath?.trim();

    if (certificate == null && privateKey == null) {
      return null;
    }

    if (certificate == null ||
        certificate.isEmpty ||
        privateKey == null ||
        privateKey.isEmpty) {
      throw ArgumentError(
        'Certificato TLS e chiave privata devono essere indicati insieme.',
      );
    }

    if (!File(certificate).existsSync() || !File(privateKey).existsSync()) {
      throw ArgumentError('Certificato TLS o chiave privata non trovati.');
    }

    return SecurityContext()
      ..useCertificateChain(certificate)
      ..usePrivateKey(privateKey);
  }
}
