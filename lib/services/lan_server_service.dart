import 'dart:convert';
import 'dart:io';

typedef DiscentiProvider = Future<List<Map<String, dynamic>>> Function();
typedef ImpreseProvider = Future<List<Map<String, dynamic>>> Function();
typedef CorsiProvider = Future<List<Map<String, dynamic>>> Function();
typedef IntestazioneAziendaProvider = Future<Map<String, dynamic>?> Function();
typedef PrenotazioniProvider =
    Future<Map<String, dynamic>> Function({
      required int limit,
      required int offset,
      required String ricerca,
      required String filtro,
    });

const _validPrenotazioniFilters = <String>{
  'tutte',
  'aperte',
  'registro',
  'chiuse',
  'da_fare',
  'senza_discente',
  'aziendali_senza_discente',
  'senza_docente',
  'recenti_da_sistemare',
};

class LanServerService {
  LanServerService({
    DiscentiProvider? discentiProvider,
    ImpreseProvider? impreseProvider,
    CorsiProvider? corsiProvider,
    IntestazioneAziendaProvider? intestazioneAziendaProvider,
    PrenotazioniProvider? prenotazioniProvider,
    String? apiToken,
  }) : this._(
         discentiProvider,
         impreseProvider,
         corsiProvider,
         intestazioneAziendaProvider,
         prenotazioniProvider,
         apiToken,
       );

  LanServerService._(
    this._discentiProvider,
    this._impreseProvider,
    this._corsiProvider,
    this._intestazioneAziendaProvider,
    this._prenotazioniProvider,
    this._apiToken,
  );

  final DiscentiProvider? _discentiProvider;
  final ImpreseProvider? _impreseProvider;
  final CorsiProvider? _corsiProvider;
  final IntestazioneAziendaProvider? _intestazioneAziendaProvider;
  final PrenotazioniProvider? _prenotazioniProvider;
  final String? _apiToken;

  HttpServer? _server;

  int get port {
    final server = _server;

    if (server == null) {
      throw StateError('Server LAN non avviato.');
    }

    return server.port;
  }

  bool get isRunning => _server != null;

  Future<void> start({
    required InternetAddress address,
    required int port,
  }) async {
    if (_server != null) {
      throw StateError('Server LAN già avviato.');
    }

    final server = await HttpServer.bind(address, port);

    _server = server;

    server.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method == 'GET' && request.uri.path == '/health') {
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'ok',
        'service': 'gestionale_sicurezza',
      });

      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/discenti') {
      if (!_isAuthorized(request)) {
        await _writeJson(request.response, HttpStatus.unauthorized, {
          'error': 'unauthorized',
        });

        return;
      }

      final provider = _discentiProvider;

      if (provider == null) {
        await _writeJson(request.response, HttpStatus.serviceUnavailable, {
          'error': 'discenti_provider_not_configured',
        });

        return;
      }

      try {
        final items = await provider();

        await _writeJson(request.response, HttpStatus.ok, {
          'sola_lettura': true,
          'count': items.length,
          'items': items,
        });
      } catch (_) {
        await _writeJson(request.response, HttpStatus.internalServerError, {
          'error': 'discenti_read_failed',
        });
      }

      return;
    }

    if (request.method == 'GET' &&
        request.uri.path == '/api/intestazione-azienda') {
      if (!_isAuthorized(request)) {
        await _writeJson(request.response, HttpStatus.unauthorized, {
          'error': 'unauthorized',
        });
        return;
      }

      final provider = _intestazioneAziendaProvider;

      if (provider == null) {
        await _writeJson(request.response, HttpStatus.serviceUnavailable, {
          'error': 'intestazione_azienda_provider_not_configured',
        });
        return;
      }

      try {
        final dati = await provider();

        final intestazione = <String, String>{
          'titolo': dati?['titolo']?.toString() ?? '',
          'sottotitolo': dati?['sottotitolo']?.toString() ?? '',
          'dettaglio': dati?['dettaglio']?.toString() ?? '',
        };

        await _writeJson(request.response, HttpStatus.ok, {
          'sola_lettura': true,
          'intestazione': intestazione,
        });
      } catch (_) {
        await _writeJson(request.response, HttpStatus.internalServerError, {
          'error': 'intestazione_azienda_unavailable',
        });
      }

      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/corsi') {
      if (!_isAuthorized(request)) {
        await _writeJson(request.response, HttpStatus.unauthorized, {
          'error': 'unauthorized',
        });

        return;
      }

      final provider = _corsiProvider;

      if (provider == null) {
        await _writeJson(request.response, HttpStatus.serviceUnavailable, {
          'error': 'corsi_provider_not_configured',
        });

        return;
      }

      try {
        final items = await provider();

        await _writeJson(request.response, HttpStatus.ok, {
          'sola_lettura': true,
          'count': items.length,
          'items': items,
        });
      } catch (_) {
        await _writeJson(request.response, HttpStatus.internalServerError, {
          'error': 'corsi_read_failed',
        });
      }

      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/prenotazioni') {
      if (!_isAuthorized(request)) {
        await _writeJson(request.response, HttpStatus.unauthorized, {
          'error': 'unauthorized',
        });
        return;
      }

      final provider = _prenotazioniProvider;
      if (provider == null) {
        await _writeJson(request.response, HttpStatus.serviceUnavailable, {
          'error': 'prenotazioni_provider_not_configured',
        });
        return;
      }

      final query = request.uri.queryParameters;
      final limit = int.tryParse(query['limit'] ?? '50');
      final offset = int.tryParse(query['offset'] ?? '0');
      final ricerca = query['ricerca'] ?? '';
      final filtro = query['filtro'] ?? 'tutte';

      if (limit == null ||
          limit < 1 ||
          limit > 100 ||
          offset == null ||
          offset < 0 ||
          ricerca.trim().length > 160 ||
          !_validPrenotazioniFilters.contains(filtro)) {
        await _writeJson(request.response, HttpStatus.badRequest, {
          'error': 'invalid_prenotazioni_parameters',
        });
        return;
      }

      try {
        final data = await provider(
          limit: limit,
          offset: offset,
          ricerca: ricerca,
          filtro: filtro,
        );
        final items = data['items'];
        final conteggi = data['conteggi'];

        if (items is! List || conteggi is! Map) {
          throw const FormatException(
            'Risposta provider Prenotazioni non valida.',
          );
        }

        await _writeJson(request.response, HttpStatus.ok, {
          'sola_lettura': true,
          'count': items.length,
          'limit': limit,
          'offset': offset,
          'items': items,
          'conteggi': conteggi,
        });
      } catch (_) {
        await _writeJson(request.response, HttpStatus.internalServerError, {
          'error': 'prenotazioni_read_failed',
        });
      }
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/imprese') {
      if (!_isAuthorized(request)) {
        await _writeJson(request.response, HttpStatus.unauthorized, {
          'error': 'unauthorized',
        });

        return;
      }

      final provider = _impreseProvider;

      if (provider == null) {
        await _writeJson(request.response, HttpStatus.serviceUnavailable, {
          'error': 'imprese_provider_not_configured',
        });

        return;
      }

      try {
        final items = await provider();

        await _writeJson(request.response, HttpStatus.ok, {
          'sola_lettura': true,
          'count': items.length,
          'items': items,
        });
      } catch (_) {
        await _writeJson(request.response, HttpStatus.internalServerError, {
          'error': 'imprese_read_failed',
        });
      }

      return;
    }

    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'not_found',
    });
  }

  bool _isAuthorized(HttpRequest request) {
    final apiToken = _apiToken;

    if (apiToken == null) {
      return true;
    }

    final authorization = request.headers.value(
      HttpHeaders.authorizationHeader,
    );

    return authorization == 'Bearer $apiToken';
  }

  Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, dynamic> body,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;

    response.write(jsonEncode(body));

    await response.close();
  }

  Future<void> stop() async {
    final server = _server;

    if (server == null) {
      return;
    }

    _server = null;

    await server.close(force: true);
  }
}
