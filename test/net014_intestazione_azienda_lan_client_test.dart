import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_api_client.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test(
    'NET014K-15 client LAN carica intestazione aziendale autenticata',
    () async {
      final server = LanServerService(
        apiToken: 'token-test-net014-intestazione',
        intestazioneAziendaProvider: () async {
          return {
            'titolo': 'F&P Formazione e Privacy',
            'sottotitolo': 'F&P S.r.l.s. - P.IVA 01234567890',
            'dettaglio': 'Roma - Tel. 0600000000',
            'logo_path': r'C:\riservato\logo.png',
            'note': 'INFORMAZIONE RISERVATA',
          };
        },
      );

      await server.start(address: InternetAddress.loopbackIPv4, port: 0);

      final client = LanApiClient(
        baseUrl:
            'http://${InternetAddress.loopbackIPv4.address}:${server.port}',
        apiToken: 'token-test-net014-intestazione',
      );

      try {
        final intestazione = await client.loadIntestazioneAzienda();

        expect(intestazione, {
          'titolo': 'F&P Formazione e Privacy',
          'sottotitolo': 'F&P S.r.l.s. - P.IVA 01234567890',
          'dettaglio': 'Roma - Tel. 0600000000',
        });

        expect(intestazione.keys.toSet(), {
          'titolo',
          'sottotitolo',
          'dettaglio',
        });

        expect(intestazione.toString().contains('RISERVATA'), false);

        expect(intestazione.toString().contains('riservato'), false);
      } finally {
        await client.close();
        await server.stop();
      }
    },
  );
}
