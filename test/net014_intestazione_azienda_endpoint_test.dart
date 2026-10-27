import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test(
    'NET014K GET /api/intestazione-azienda richiede token e limita i dati',
    () async {
      final server = LanServerService(
        apiToken: 'token-test-net014-intestazione',
        intestazioneAziendaProvider: () async {
          return {
            'titolo': 'F&P Formazione e Privacy',
            'sottotitolo': 'F&P S.r.l.s. - P.IVA 01234567890',
            'dettaglio': 'Roma - Tel. 0600000000',
            'logo_path': r'C:\riservato\logo.png',
            'note': 'Informazione interna da non trasmettere',
          };
        },
      );

      await server.start(address: InternetAddress.loopbackIPv4, port: 0);

      final client = HttpClient();

      try {
        final richiestaSenzaToken = await client.get(
          InternetAddress.loopbackIPv4.address,
          server.port,
          '/api/intestazione-azienda',
        );

        final rispostaSenzaToken = await richiestaSenzaToken.close();

        await rispostaSenzaToken.drain<void>();

        expect(rispostaSenzaToken.statusCode, HttpStatus.unauthorized);

        final richiestaAutorizzata = await client.get(
          InternetAddress.loopbackIPv4.address,
          server.port,
          '/api/intestazione-azienda',
        );

        richiestaAutorizzata.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer token-test-net014-intestazione',
        );

        final risposta = await richiestaAutorizzata.close();
        final testo = await risposta.transform(utf8.decoder).join();

        expect(risposta.statusCode, HttpStatus.ok);

        expect(risposta.headers.contentType?.mimeType, 'application/json');

        final json = jsonDecode(testo) as Map<String, dynamic>;

        expect(json['sola_lettura'], true);

        final intestazione = json['intestazione'] as Map<String, dynamic>;

        expect(intestazione, hasLength(3));

        expect(intestazione['titolo'], 'F&P Formazione e Privacy');

        expect(intestazione['sottotitolo'], 'F&P S.r.l.s. - P.IVA 01234567890');

        expect(intestazione['dettaglio'], 'Roma - Tel. 0600000000');

        expect(intestazione.containsKey('logo_path'), false);
        expect(intestazione.containsKey('note'), false);
      } finally {
        client.close(force: true);
        await server.stop();
      }
    },
  );
}
