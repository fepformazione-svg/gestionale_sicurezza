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

  Future<Map<String, dynamic>> loadPrenotazioni({
    required int limit,
    required int offset,
    required String ricerca,
    required String filtro,
  }) async {
    _ensureOpen();

    if (limit < 1 || limit > 100 || offset < 0 || ricerca.trim().length > 160) {
      throw ArgumentError('Parametri di paginazione o ricerca non validi.');
    }

    final uri = _baseUri.replace(
      path: '${_normalizedBasePath(_baseUri.path)}/api/prenotazioni',
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        'ricerca': ricerca,
        'filtro': filtro,
      },
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
    if (decoded is! Map<String, dynamic> || decoded['sola_lettura'] != true) {
      throw const FormatException('Risposta Prenotazioni API LAN non valida.');
    }

    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw const FormatException('Elenco Prenotazioni API LAN non valido.');
    }
    final items = <Map<String, dynamic>>[];
    for (final item in rawItems) {
      if (item is! Map) {
        throw const FormatException('Prenotazione API LAN non valida.');
      }
      items.add(Map<String, dynamic>.from(item));
    }

    if (decoded['count'] is! int ||
        decoded['count'] != items.length ||
        decoded['limit'] != limit ||
        decoded['offset'] != offset) {
      throw const FormatException('Paginazione Prenotazioni API non coerente.');
    }

    final rawConteggi = decoded['conteggi'];
    if (rawConteggi is! Map) {
      throw const FormatException('Conteggi Prenotazioni API LAN non validi.');
    }
    final conteggi = <String, int>{};
    for (final voce in rawConteggi.entries) {
      if (voce.key is! String || voce.value is! int) {
        throw const FormatException('Valore conteggi Prenotazioni non valido.');
      }
      conteggi[voce.key as String] = voce.value as int;
    }

    return <String, dynamic>{
      'items': List<Map<String, dynamic>>.unmodifiable(items),
      'conteggi': Map<String, int>.unmodifiable(conteggi),
      'limit': limit,
      'offset': offset,
    };
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
