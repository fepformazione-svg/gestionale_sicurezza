class LanClientConfiguration {
  const LanClientConfiguration({
    required this.baseUrl,
    required this.apiToken,
    this.caCertificatePath,
  });

  static const String urlEnvironmentVariable = 'GESTIONALE_SICUREZZA_LAN_URL';

  static const String tokenEnvironmentVariable =
      'GESTIONALE_SICUREZZA_LAN_TOKEN';

  static const String caCertificateEnvironmentVariable =
      'GESTIONALE_SICUREZZA_LAN_CA_CERT';

  final String baseUrl;
  final String apiToken;
  final String? caCertificatePath;

  static LanClientConfiguration? fromEnvironment(
    Map<String, String> environment,
  ) {
    final rawUrl = environment[urlEnvironmentVariable];

    final rawToken = environment[tokenEnvironmentVariable];

    final rawCaCertificatePath = environment[caCertificateEnvironmentVariable];

    if (rawUrl == null || rawToken == null) {
      if (rawCaCertificatePath != null) {
        throw ArgumentError('Configurazione CA LAN incompleta.');
      }
      return null;
    }

    final baseUrl = rawUrl.trim();

    final apiToken = rawToken.trim();

    if (baseUrl.isEmpty || apiToken.isEmpty) {
      if (rawCaCertificatePath != null) {
        throw ArgumentError('Configurazione CA LAN incompleta.');
      }
      return null;
    }

    final uri = Uri.tryParse(baseUrl);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (rawCaCertificatePath != null) {
        throw ArgumentError('URL LAN non valido per la CA configurata.');
      }
      return null;
    }

    final caCertificatePath = rawCaCertificatePath?.trim();

    if (rawCaCertificatePath != null) {
      if (caCertificatePath == null || caCertificatePath.isEmpty) {
        throw ArgumentError('Percorso certificato CA LAN vuoto.');
      }

      if (uri.scheme != 'https') {
        throw ArgumentError('Il certificato CA LAN richiede HTTPS.');
      }
    }

    return LanClientConfiguration(
      baseUrl: uri.toString(),
      apiToken: apiToken,
      caCertificatePath: caCertificatePath,
    );
  }
}
