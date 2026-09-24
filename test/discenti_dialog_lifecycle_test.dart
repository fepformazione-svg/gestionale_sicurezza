import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DISC002 - lifecycle dialog discente', () {
    late String source;

    setUpAll(() {
      final file = File('lib/pages/discenti_page.dart');

      expect(
        file.existsSync(),
        isTrue,
        reason: 'La pagina Discenti deve esistere.',
      );

      source = file.readAsStringSync();
    });

    test(
      'attende la chiusura completa della route prima di disporre i controller',
      () {
        expect(
          source,
          contains('await dialogRoute.completed;'),
          reason:
              'I TextEditingController del dialog non devono essere distrutti '
              'mentre la route sta ancora eseguendo l'
              'animazione di uscita.',
        );

        final indiceAttesa = source.indexOf('await dialogRoute.completed;');

        final indiceDispose = source.indexOf('nomeController.dispose();');

        expect(indiceAttesa, greaterThanOrEqualTo(0));

        expect(
          indiceDispose,
          greaterThan(indiceAttesa),
          reason:
              'Il dispose dei controller deve avvenire solo dopo '
              'il completamento effettivo della route.',
        );
      },
    );
  });
}
