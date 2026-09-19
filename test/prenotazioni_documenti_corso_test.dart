import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DOC003 - Documenti corso da Prenotazioni', () {
    test('aggiunge Documenti corso al menu contestuale della prenotazione', () {
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
        RegExp(
          r"PopupMenuItem\s*\([\s\S]*?"
          r"value\s*:\s*'documenti_corso'"
          r"[\s\S]*?"
          r"Documenti corso",
        ).hasMatch(source),
        isTrue,
        reason:
            'Il menu contestuale della singola prenotazione '
            'deve offrire Documenti corso.',
      );

      expect(
        RegExp(
          r"if\s*\(\s*result\s*==\s*'documenti_corso'\s*\)"
          r"[\s\S]*?"
          r"apriDocumentiCorsoPrenotazione\s*\(\s*p\s*,?\s*\)",
        ).hasMatch(source),
        isTrue,
        reason:
            'La voce Documenti corso deve aprire '
            'i documenti del corso della prenotazione selezionata.',
      );
    });

    test('usa il corso della prenotazione e distingue Test e Gradimento', () {
      final file = File('lib/pages/prenotazioni_page.dart');

      expect(file.existsSync(), isTrue);

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        source,
        contains('Future<void> apriDocumentiCorsoPrenotazione('),
        reason:
            'Prenotazioni deve avere un metodo operativo '
            'dedicato ai documenti del corso.',
      );

      expect(
        RegExp(r"prenotazione\s*\[\s*'corso_id'\s*\]").hasMatch(source),
        isTrue,
        reason:
            'Il corso deve essere individuato tramite '
            'il corso_id della prenotazione.',
      );

      expect(
        source,
        contains('modelloTestWordPath'),
        reason:
            'DOC003 deve utilizzare il modello Word Test '
            'associato al corso.',
      );

      expect(
        source,
        contains('modelloGradimentoWordPath'),
        reason:
            'DOC003 deve utilizzare il modello Word Gradimento '
            'associato al corso.',
      );

      expect(
        source,
        contains('Test Word'),
        reason:
            'L interfaccia operativa deve distinguere '
            'il documento Test.',
      );

      expect(
        source,
        contains('Gradimento Word'),
        reason:
            'L interfaccia operativa deve distinguere '
            'il documento Gradimento.',
      );
    });

    test('apre il modello solo se associato ed esistente', () {
      final file = File('lib/pages/prenotazioni_page.dart');

      expect(file.existsSync(), isTrue);

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        RegExp(
          r"Future<void>\s+_apriModelloWordCorso\s*\("
          r"[\s\S]*?"
          r"File\s*\("
          r"[\s\S]*?"
          r"\.exists\s*\(\s*\)"
          r"[\s\S]*?"
          r"OpenFile\.open\s*\(",
        ).hasMatch(source),
        isTrue,
        reason:
            'L apertura operativa deve verificare '
            'che il file esista prima di invocare OpenFile.open.',
      );

      expect(
        RegExp(
          r"_apriModelloWordCorso\s*\("
          r"[\s\S]*?"
          r"(null|isEmpty|trim)",
        ).hasMatch(source),
        isTrue,
        reason:
            'Deve essere gestita anche '
            'l assenza di un modello Word associato.',
      );
    });
  });
}
