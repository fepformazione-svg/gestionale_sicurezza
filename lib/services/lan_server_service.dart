import 'dart:convert';
import 'dart:io';

typedef DiscentiProvider = Future<List<Map<String, dynamic>>> Function();

class LanServerService {
  LanServerService({DiscentiProvider? discentiProvider, String? apiToken})
    : this._(discentiProvider, apiToken);

  LanServerService._(this._discentiProvider, this._apiToken);

  final DiscentiProvider? _discentiProvider;
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
