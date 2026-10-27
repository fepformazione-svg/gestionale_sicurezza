import 'dart:convert';
import 'dart:io';

class LanApiClient {
  LanApiClient({
    required String baseUrl,
    required String apiToken,
    HttpClient? httpClient,
  }) : _baseUri = _parseBaseUri(baseUrl),
       _apiToken = _validateApiToken(apiToken),
       _httpClient = httpClient ?? HttpClient(),
       _ownsHttpClient = httpClient == null;

  final Uri _baseUri;
  final String _apiToken;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;

  bool _closed = false;

  Future<List<Map<String, dynamic>>> loadDiscenti() async {
    _ensureOpen();

    final uri = _baseUri.replace(
      path: '${_normalizedBasePath(_baseUri.path)}/api/discenti',
      query: null,
      fragment: null,
    );

    final request = await _httpClient.getUrl(uri);

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiToken');

    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    final response = await request.close();

    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Richiesta LAN fallita: HTTP ${response.statusCode}.',
        uri: uri,
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Risposta API LAN non valida.');
    }

    if (decoded['sola_lettura'] != true) {
      throw const FormatException(
        'Risposta API LAN non marcata come sola lettura.',
      );
    }

    final rawItems = decoded['items'];

    if (rawItems is! List) {
      throw const FormatException('Elenco discenti API LAN non valido.');
    }

    final items = <Map<String, dynamic>>[];

    for (final item in rawItems) {
      if (item is! Map) {
        throw const FormatException('Elemento discenti API LAN non valido.');
      }

      items.add(Map<String, dynamic>.from(item));
    }

    final count = decoded['count'];

    if (count is! int || count != items.length) {
      throw const FormatException('Conteggio discenti API LAN non coerente.');
    }

    return List<Map<String, dynamic>>.unmodifiable(items);
  }

  Future<List<Map<String, dynamic>>> loadImprese() async {
    _ensureOpen();

    final uri = _baseUri.replace(
      path: '${_normalizedBasePath(_baseUri.path)}/api/imprese',
      query: null,
      fragment: null,
    );

    final request = await _httpClient.getUrl(uri);

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiToken');

    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    final response = await request.close();

    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Richiesta LAN fallita: HTTP ${response.statusCode}.',
        uri: uri,
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Risposta API LAN non valida.');
    }

    if (decoded['sola_lettura'] != true) {
      throw const FormatException(
        'Risposta API LAN non marcata come sola lettura.',
      );
    }

    final rawItems = decoded['items'];

    if (rawItems is! List) {
      throw const FormatException('Elenco imprese API LAN non valido.');
    }

    final items = <Map<String, dynamic>>[];

    for (final item in rawItems) {
      if (item is! Map) {
        throw const FormatException('Elemento imprese API LAN non valido.');
      }

      items.add(Map<String, dynamic>.from(item));
    }

    final count = decoded['count'];

    if (count is! int || count != items.length) {
      throw const FormatException('Conteggio imprese API LAN non coerente.');
    }

    return List<Map<String, dynamic>>.unmodifiable(items);
  }

  Future<List<Map<String, dynamic>>> loadCorsi() async {
    _ensureOpen();

    final uri = _baseUri.replace(
      path: '${_normalizedBasePath(_baseUri.path)}/api/corsi',
      query: null,
      fragment: null,
    );

    final request = await _httpClient.getUrl(uri);

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiToken');

    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    final response = await request.close();

    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Richiesta LAN fallita: HTTP ${response.statusCode}.',
        uri: uri,
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Risposta API LAN non valida.');
    }

    if (decoded['sola_lettura'] != true) {
      throw const FormatException(
        'Risposta API LAN non marcata come sola lettura.',
      );
    }

    final rawItems = decoded['items'];

    if (rawItems is! List) {
      throw const FormatException('Elenco corsi API LAN non valido.');
    }

    final items = <Map<String, dynamic>>[];

    for (final item in rawItems) {
      if (item is! Map) {
        throw const FormatException('Elemento corsi API LAN non valido.');
      }

      items.add(Map<String, dynamic>.from(item));
    }

    final count = decoded['count'];

    if (count is! int || count != items.length) {
      throw const FormatException('Conteggio corsi API LAN non coerente.');
    }

    return List<Map<String, dynamic>>.unmodifiable(items);
  }

  Future<Map<String, String>> loadIntestazioneAzienda() async {
    _ensureOpen();

    final uri = _baseUri.replace(
      path: '${_normalizedBasePath(_baseUri.path)}/api/intestazione-azienda',
      query: null,
      fragment: null,
    );

    final request = await _httpClient.getUrl(uri);

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiToken');

    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Richiesta LAN fallita: HTTP ${response.statusCode}.',
        uri: uri,
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Risposta API LAN non valida.');
    }

    if (decoded['sola_lettura'] != true) {
      throw const FormatException(
        'Risposta API LAN non marcata come sola lettura.',
      );
    }

    final rawIntestazione = decoded['intestazione'];

    if (rawIntestazione is! Map<String, dynamic>) {
      throw const FormatException('Intestazione aziendale API LAN non valida.');
    }

    const expectedKeys = {'titolo', 'sottotitolo', 'dettaglio'};

    if (rawIntestazione.length != expectedKeys.length ||
        !rawIntestazione.keys.toSet().containsAll(expectedKeys)) {
      throw const FormatException(
        'Campi intestazione aziendale API LAN non validi.',
      );
    }

    final intestazione = <String, String>{};

    for (final key in expectedKeys) {
      final value = rawIntestazione[key];

      if (value is! String) {
        throw const FormatException(
          'Valore intestazione aziendale API LAN non valido.',
        );
      }

      intestazione[key] = value;
    }

    return Map<String, String>.unmodifiable(intestazione);
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;

    if (_ownsHttpClient) {
      _httpClient.close(force: true);
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('Client LAN giÃ  chiuso.');
    }
  }

  static Uri _parseBaseUri(String baseUrl) {
    final trimmed = baseUrl.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'URL base LAN obbligatorio.',
      );
    }

    final uri = Uri.tryParse(trimmed);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'URL base LAN non valido.');
    }

    return uri;
  }

  static String _validateApiToken(String apiToken) {
    final trimmed = apiToken.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        apiToken,
        'apiToken',
        'Token API LAN obbligatorio.',
      );
    }

    return trimmed;
  }

  static String _normalizedBasePath(String path) {
    if (path.isEmpty || path == '/') {
      return '';
    }

    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }
}
