import 'dart:convert';
import 'dart:io';

typedef DiscentiProvider = Future<List<Map<String, dynamic>>> Function();

class LanServerService {
  LanServerService({DiscentiProvider? discentiProvider})
    : this._(discentiProvider);

  LanServerService._(this._discentiProvider);

  final DiscentiProvider? _discentiProvider;

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
      throw StateError('Server LAN giÃ  avviato.');
    }

    final server = await HttpServer.bind(address, port);

    _server = server;

    server.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method == 'GET' && request.uri.path == '/health') {
      await _writeJson(request, HttpStatus.ok, {
        'status': 'ok',
        'service': 'gestionale_sicurezza',
      });

      return;
    }

    if (request.method == 'GET' && request.uri.path == '/api/discenti') {
      final provider = _discentiProvider;

      if (provider == null) {
        await _writeJson(request, HttpStatus.serviceUnavailable, {
          'error': 'discenti_provider_not_configured',
        });

        return;
      }

      try {
        final items = await provider();

        await _writeJson(request, HttpStatus.ok, {
          'sola_lettura': true,
          'count': items.length,
          'items': items,
        });
      } catch (_) {
        await _writeJson(request, HttpStatus.internalServerError, {
          'error': 'discenti_read_failed',
        });
      }

      return;
    }

    await _writeJson(request, HttpStatus.notFound, {'error': 'not_found'});
  }

  Future<void> _writeJson(
    HttpRequest request,
    int statusCode,
    Map<String, dynamic> body,
  ) async {
    request.response.statusCode = statusCode;

    request.response.headers.contentType = ContentType.json;

    request.response.write(jsonEncode(body));

    await request.response.close();
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
