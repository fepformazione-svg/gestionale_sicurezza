import 'dart:async';
import 'dart:io';

import 'package:gestionale_sicurezza/services/lan_server_service.dart';

Future<void> main(List<String> args) async {
  var host = '127.0.0.1';
  var port = 8765;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--host' && i + 1 < args.length) {
      host = args[++i];
      continue;
    }

    if (args[i] == '--port' && i + 1 < args.length) {
      final parsedPort = int.tryParse(args[++i]);

      if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
        stderr.writeln('Porta non valida.');
        exitCode = 64;
        return;
      }

      port = parsedPort;
    }
  }

  final address = InternetAddress.tryParse(host);

  if (address == null) {
    stderr.writeln('Indirizzo IP non valido: $host');
    exitCode = 64;
    return;
  }

  final server = LanServerService();

  await server.start(address: address, port: port);

  stdout.writeln('GESTIONALE SICUREZZA LAN SERVER ATTIVO');
  stdout.writeln('http://$host:${server.port}/health');

  final stopCompleter = Completer<void>();

  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();

    if (!stopCompleter.isCompleted) {
      stopCompleter.complete();
    }
  });

  await stopCompleter.future;
}
