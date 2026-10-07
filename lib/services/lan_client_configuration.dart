class LanClientConfiguration {
  const LanClientConfiguration({required this.baseUrl, required this.apiToken});

  static const String urlEnvironmentVariable = 'GESTIONALE_SICUREZZA_LAN_URL';

  static const String tokenEnvironmentVariable =
      'GESTIONALE_SICUREZZA_LAN_TOKEN';

  final String baseUrl;
  final String apiToken;

  static LanClientConfiguration? fromEnvironment(
    Map<String, String> environment,
  ) {
    final rawUrl = environment[urlEnvironmentVariable];

    final rawToken = environment[tokenEnvironmentVariable];

    if (rawUrl == null || rawToken == null) {
      return null;
    }

    final baseUrl = rawUrl.trim();

    final apiToken = rawToken.trim();

    if (baseUrl.isEmpty || apiToken.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(baseUrl);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    return LanClientConfiguration(baseUrl: uri.toString(), apiToken: apiToken);
  }
}
