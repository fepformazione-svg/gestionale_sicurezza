import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DOC004E - Documenti Word personalizzati da Prenotazioni', () {
    test(
      'collega Prenotazioni al motore DOCX e al contesto della prenotazione',
      () {
        final file = File('lib/pages/prenotazioni_page.dart');

        expect(
          file.existsSync(),
          isTrue,
          reason: 'La pagina Prenotazioni deve esistere.',
        );

        if (!file.existsSync()) {
          return;
        }

        final source = file.readAsStringSync();

        expect(
          source,
          contains("../services/documento_word_docx_service.dart"),
          reason:
              'Prenotazioni deve importare il motore locale '
              'DocumentoWordDocxService.',
        );

        expect(
          source,
          contains('getDocumentoWordContextByPrenotazioneId'),
          reason:
              'La generazione deve recuperare i dati completi '
              'dalla prenotazione selezionata.',
        );

        expect(
          source,
          contains('DocumentoWordDocxService'),
          reason: 'La pagina deve usare il motore DOCX già validato.',
        );

        expect(
          source,
          contains('placeholderValues'),
          reason: 'Il contesto deve alimentare i placeholder del modello Word.',
        );
      },
    );

    test('offre generazione personalizzata e copia senza corsista', () {
      final file = File('lib/pages/prenotazioni_page.dart');

      expect(file.existsSync(), isTrue);

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        source,
        contains('Genera personalizzato'),
        reason:
            'Il dialog Documenti corso deve offrire '
            'la generazione per il corsista collegato.',
      );

      expect(
        source,
        contains('Genera senza corsista'),
        reason:
            'Il dialog deve poter creare anche '
            'una copia per un partecipante dell ultimo momento.',
      );

      expect(
        source,
        contains('senzaDiscente()'),
        reason:
            'La copia senza corsista deve cancellare '
            'solo i dati personali mantenendo quelli del corso.',
      );
    });

    test(
      'salva copie Word in cartella dedicata con nome univoco e le apre',
      () {
        final file = File('lib/pages/prenotazioni_page.dart');

        expect(file.existsSync(), isTrue);

        if (!file.existsSync()) {
          return;
        }

        final source = file.readAsStringSync();

        expect(
          source,
          contains('getApplicationDocumentsDirectory'),
          reason:
              'La cartella deve derivare dalla directory Documenti '
              'dell utente.',
        );

        expect(
          source,
          contains("'Gestionale Sicurezza'"),
          reason:
              'I documenti devono restare nell area dati '
              'del Gestionale Sicurezza.',
        );

        expect(
          source,
          contains("'Documenti Corso'"),
          reason: 'Le copie Word devono avere una cartella dedicata.',
        );

        expect(
          source,
          contains('microsecondsSinceEpoch'),
          reason:
              'Il nome file deve avere un suffisso univoco '
              'senza sovrascrivere documenti precedenti.',
        );

        expect(
          source,
          contains('generaDaModello'),
          reason:
              'La pagina deve creare una copia dal master '
              'senza modificarlo.',
        );

        expect(
          RegExp(
            r'OpenFile\.open\s*\(\s*percorsoGenerato\s*,?\s*\)',
          ).hasMatch(source),
          isTrue,
          reason:
              'Il documento appena generato deve essere '
              'aperto automaticamente.',
        );
      },
    );
  });
}
