import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

Future<HttpClientResponse> _inviaPost(
  HttpClient client,
  int porta, {
  String? token,
  String corpo = '{"dati":{"corso_id":1}}',
  bool json = true,
}) async {
  final request = await client.post(
    InternetAddress.loopbackIPv4.address,
    porta,
    '/api/prenotazioni',
  );
  if (token != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
  if (json) request.headers.contentType = ContentType.json;
  request.write(corpo);
  return request.close();
}

void main() {
  test('NET015C2 POST autenticato inoltra solo i dati al provider', () async {
    final ricevuti = <Map<String, dynamic>>[];
    final server = LanServerService(
      apiToken: 'token-net015c2-test',
      prenotazioniInsertProvider: (dati) async {
        ricevuti.add(dati);
        return 51;
      },
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final response = await _inviaPost(
        client,
        server.port,
        token: 'token-net015c2-test',
        corpo: jsonEncode({
          'dati': {'corso_id': 1, 'prot': 'PROVA-LAN'},
        }),
      );
      final body =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      expect(response.statusCode, HttpStatus.created);
      expect(body['id'], 51);
      expect(ricevuti, [
        {'corso_id': 1, 'prot': 'PROVA-LAN'},
      ]);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C2 POST nega token assente o errato', () async {
    var chiamate = 0;
    final server = LanServerService(
      apiToken: 'token-net015c2-test',
      prenotazioniInsertProvider: (dati) async {
        chiamate++;
        return 1;
      },
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final senzaToken = await _inviaPost(client, server.port);
      expect(senzaToken.statusCode, HttpStatus.unauthorized);
      await senzaToken.drain<void>();
      final tokenErrato = await _inviaPost(
        client,
        server.port,
        token: 'token-errato',
      );
      expect(tokenErrato.statusCode, HttpStatus.unauthorized);
      await tokenErrato.drain<void>();
      expect(chiamate, 0);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C2 POST senza token server rimane vietato', () async {
    var chiamate = 0;
    final server = LanServerService(
      prenotazioniInsertProvider: (dati) async {
        chiamate++;
        return 1;
      },
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final risposta = await _inviaPost(
        client,
        server.port,
        token: 'qualunque',
      );
      expect(risposta.statusCode, HttpStatus.unauthorized);
      await risposta.drain<void>();
      expect(chiamate, 0);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C2 POST senza provider non abilita scritture', () async {
    final server = LanServerService(apiToken: 'token-net015c2-test');
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final risposta = await _inviaPost(
        client,
        server.port,
        token: 'token-net015c2-test',
      );
      expect(risposta.statusCode, HttpStatus.serviceUnavailable);
      await risposta.drain<void>();
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });

  test('NET015C2 POST rifiuta JSON non valido e corpi troppo grandi', () async {
    var chiamate = 0;
    final server = LanServerService(
      apiToken: 'token-net015c2-test',
      prenotazioniInsertProvider: (dati) async {
        chiamate++;
        return 1;
      },
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    final client = HttpClient();

    try {
      final invalida = await _inviaPost(
        client,
        server.port,
        token: 'token-net015c2-test',
        corpo: 'non-json',
      );
      expect(invalida.statusCode, HttpStatus.badRequest);
      await invalida.drain<void>();

      final troppoGrande = await _inviaPost(
        client,
        server.port,
        token: 'token-net015c2-test',
        corpo: jsonEncode({
          'dati': {'prot': ''.padRight(17000, 'x')},
        }),
      );
      expect(troppoGrande.statusCode, HttpStatus.requestEntityTooLarge);
      await troppoGrande.drain<void>();
      expect(chiamate, 0);
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
