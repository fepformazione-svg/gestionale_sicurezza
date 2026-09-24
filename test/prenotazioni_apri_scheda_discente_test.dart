import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PREN014 - Scheda discente da Prenotazioni', () {
    late String source;

    setUpAll(() {
      final file = File('lib/pages/prenotazioni_page.dart');

      expect(
        file.existsSync(),
        isTrue,
        reason: 'La pagina Prenotazioni deve esistere.',
      );

      source = file.readAsStringSync();
    });

    test(
      'carica il discente tramite discente_id e apre la scheda in dialog',
      () {
        expect(
          source,
          contains("import 'discente_scheda_page.dart';"),
          reason:
              'Prenotazioni deve poter riutilizzare '
              'la scheda discente esistente.',
        );

        expect(
          RegExp(
            r'Future<void>\s+apriSchedaDiscenteDaPrenotazione\s*\('
            r"[\s\S]{0,5000}?prenotazione\s*\[\s*'discente_id'\s*\]"
            r'[\s\S]{0,5000}?getDiscenteById\s*\('
            r'[\s\S]{0,5000}?showDialog'
            r'[\s\S]{0,5000}?DiscenteSchedaPage\s*\(',
          ).hasMatch(source),
          isTrue,
          reason:
              'Il click deve usare discente_id, recuperare il Discente '
              'e aprire DiscenteSchedaPage in una finestra modale.',
        );
      },
    );

    test(
      'PrenotazioneRow espone il callback dedicato alla scheda discente',
      () {
        expect(
          source,
          contains('final VoidCallback onApriDiscente;'),
          reason:
              'La riga deve avere un callback separato '
              'per il click sul nominativo.',
        );

        expect(
          source,
          contains('required this.onApriDiscente,'),
          reason:
              'Il callback deve essere obbligatorio '
              'nel costruttore della riga.',
        );

        expect(
          RegExp(
            r'onApriDiscente\s*:'
            r'[\s\S]{0,500}?'
            r'apriSchedaDiscenteDaPrenotazione\s*\(\s*p\s*,?\s*\)',
          ).hasMatch(source),
          isTrue,
          reason:
              'La pagina deve collegare la riga '
              'al metodo di apertura della scheda.',
        );
      },
    );

    test('il nominativo collegato e cliccabile e riconoscibile', () {
      expect(
        RegExp(
          r"message\s*:\s*'Apri scheda discente'"
          r'[\s\S]{0,1500}?'
          r'onTap\s*:\s*widget\.onApriDiscente',
        ).hasMatch(source),
        isTrue,
        reason:
            'Il nominativo valido deve avere tooltip '
            'e click dedicato alla scheda.',
      );
    });
  });
}
