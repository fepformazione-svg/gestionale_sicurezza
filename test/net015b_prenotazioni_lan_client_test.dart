import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/lan_api_client.dart';
import 'package:gestionale_sicurezza/services/lan_client_configuration.dart';
import 'package:gestionale_sicurezza/services/lan_client_runtime.dart';
import 'package:gestionale_sicurezza/services/lan_server_service.dart';

void main() {
  test(
    'NET015B1 client e runtime LAN leggono Prenotazioni autenticate',
    () async {
      final richieste = <Map<String, Object>>[];
      final server = LanServerService(
        apiToken: 'token-test-net015b',
        prenotazioniProvider:
            ({
              required int limit,
              required int offset,
              required String ricerca,
              required String filtro,
            }) async {
              richieste.add({
                'limit': limit,
                'offset': offset,
                'ricerca': ricerca,
                'filtro': filtro,
              });
              return <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  {
                    'id': 42,
                    'prot': 'P-042',
                    'attrezzature_sintesi': 'Imbracatura x2',
                  },
                ],
                'conteggi': <String, int>{
                  'tutte': 4,
                  'aperte': 1,
                  'registro': 0,
                  'chiuse': 2,
                  'da_fare': 1,
                  'senza_discente': 0,
                  'aziendali_senza_discente': 0,
                  'senza_docente': 1,
                  'recenti_da_sistemare': 1,
                },
              };
            },
      );
      await server.start(address: InternetAddress.loopbackIPv4, port: 0);
      final baseUrl =
          'http://${InternetAddress.loopbackIPv4.address}:${server.port}';
      final client = LanApiClient(
        baseUrl: baseUrl,
        apiToken: 'token-test-net015b',
      );
      final runtime = LanClientRuntime.fromConfiguration(
        LanClientConfiguration(
          baseUrl: baseUrl,
          apiToken: 'token-test-net015b',
        ),
      );
      final wrongClient = LanApiClient(
        baseUrl: baseUrl,
        apiToken: 'token-sbagliato',
      );

      try {
        final pagina = await client.loadPrenotazioni(
          limit: 50,
          offset: 5,
          ricerca: 'Rossi Mario',
          filtro: 'aperte',
        );
        expect((pagina['items'] as List<dynamic>).single['id'], 42);
        expect(
          (pagina['items'] as List<dynamic>).single['attrezzature_sintesi'],
          'Imbracatura x2',
        );
        expect((pagina['conteggi'] as Map<String, int>)['tutte'], 4);
        expect(pagina['limit'], 50);
        expect(pagina['offset'], 5);

        expect(runtime.enabled, true);
        expect(runtime.prenotazioniProvider, isNotNull);
        final dalRuntime = await runtime.prenotazioniProvider!(
          limit: 10,
          offset: 0,
          ricerca: '',
          filtro: 'tutte',
        );
        expect((dalRuntime['items'] as List<dynamic>).single['prot'], 'P-042');
        expect(richieste, [
          {
            'limit': 50,
            'offset': 5,
            'ricerca': 'Rossi Mario',
            'filtro': 'aperte',
          },
          {'limit': 10, 'offset': 0, 'ricerca': '', 'filtro': 'tutte'},
        ]);

        await expectLater(
          wrongClient.loadPrenotazioni(
            limit: 10,
            offset: 0,
            ricerca: '',
            filtro: 'tutte',
          ),
          throwsA(isA<HttpException>()),
        );
      } finally {
        await wrongClient.close();
        await client.close();
        await runtime.close();
        await server.stop();
      }
    },
  );

  test('NET015B1 runtime locale non crea provider Prenotazioni', () async {
    final runtime = LanClientRuntime.fromConfiguration(null);
    expect(runtime.enabled, false);
    expect(runtime.prenotazioniProvider, isNull);
    await runtime.close();
  });
}
