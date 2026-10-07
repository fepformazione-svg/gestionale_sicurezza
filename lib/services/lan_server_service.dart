import 'dart:convert';
import 'dart:io';

class LanServerService {
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

    final server = await HttpServer.bind(
      address,
      port,
    );

    _server = server;

    server.listen(_handleRequest);
  }

  Future<void> _handleRequest(
    HttpRequest request,
  ) async {
    if (
        request.method == 'GET' &&
        request.uri.path == '/health'
    ) {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType =
          ContentType.json;

      request.response.write(
        jsonEncode({
          'status': 'ok',
          'service': 'gestionale_sicurezza',
        }),
      );

      await request.response.close();
      return;
    }

    request.response.statusCode =
        HttpStatus.notFound;

    request.response.headers.contentType =
        ContentType.json;

    request.response.write(
      jsonEncode({
        'error': 'not_found',
      }),
    );

    await request.response.close();
  }

  Future<void> stop() async {
    final server = _server;

    if (server == null) {
      return;
    }

    _server = null;

    await server.close(
      force: true,
    );
  }
}
