import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DOC002 - CorsoDocumentiDialog', () {
    test('esiste un dialog dedicato ai modelli Word Test e Gradimento', () {
      final file = File('lib/widgets/corso_documenti_dialog.dart');

      expect(
        file.existsSync(),
        isTrue,
        reason:
            'DOC002 richiede un widget dedicato '
            'lib/widgets/corso_documenti_dialog.dart.',
      );

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        source,
        contains('class CorsoDocumentiDialog extends StatefulWidget'),
        reason:
            'Il widget deve essere un dialog stateful dedicato '
            'alla gestione dei modelli Word del corso.',
      );

      expect(
        source,
        contains('final Corso corso;'),
        reason: 'Il dialog deve ricevere il corso da configurare.',
      );

      expect(
        source,
        contains('Modello Test'),
        reason: 'Il dialog deve distinguere il modello Word del Test.',
      );

      expect(
        source,
        contains('Modello Gradimento'),
        reason:
            'Il dialog deve distinguere il modello Word '
            'del Gradimento.',
      );
    });

    test('gestisce selezione docx apertura rimozione e persistenza', () {
      final file = File('lib/widgets/corso_documenti_dialog.dart');

      expect(file.existsSync(), isTrue);

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        source,
        contains("package:file_picker/file_picker.dart"),
        reason:
            'Il dialog deve usare file_picker '
            'per associare il modello Word.',
      );

      expect(
        source,
        contains("package:open_file/open_file.dart"),
        reason:
            'Il dialog deve usare open_file '
            'per aprire il modello associato.',
      );

      expect(
        source,
        contains("../services/database_service.dart"),
        reason:
            'Il dialog deve poter salvare '
            'i percorsi del corso nel database.',
      );

      expect(
        source,
        contains('FilePicker.pickFiles'),
        reason: 'Deve essere presente la selezione file.',
      );

      expect(
        source,
        contains('FileType.custom'),
        reason: 'La selezione deve usare un tipo file personalizzato.',
      );

      expect(
        RegExp(
          r"allowedExtensions\s*:\s*(?:const\s*)?\[\s*'docx'\s*\]",
        ).hasMatch(source),
        isTrue,
        reason:
            'La selezione deve consentire esclusivamente '
            'documenti Word .docx.',
      );

      expect(
        source,
        contains('OpenFile.open'),
        reason:
            'Deve essere possibile aprire '
            'il documento Word associato.',
      );

      expect(
        source,
        contains('DatabaseService.instance.updateCorso'),
        reason:
            'Associazione, sostituzione e rimozione '
            'devono essere persistite sul corso.',
      );

      expect(
        source,
        contains('modelloTestWordPath'),
        reason:
            'Il dialog deve gestire '
            'il percorso del modello Test.',
      );

      expect(
        source,
        contains('modelloGradimentoWordPath'),
        reason:
            'Il dialog deve gestire '
            'il percorso del modello Gradimento.',
      );

      expect(
        source,
        contains("'Seleziona'"),
        reason:
            'Quando non esiste un modello '
            'deve essere disponibile Seleziona.',
      );

      expect(
        source,
        contains("'Sostituisci'"),
        reason:
            'Quando un modello è già associato '
            'deve essere disponibile Sostituisci.',
      );

      expect(
        source,
        contains("'Apri'"),
        reason: 'Un modello associato deve poter essere aperto.',
      );

      expect(
        source,
        contains("'Rimuovi'"),
        reason: 'Un modello associato deve poter essere rimosso.',
      );
    });

    test('integra i modelli Word nella pagina Corsi', () {
      final file = File('lib/pages/corsi_page.dart');

      expect(
        file.existsSync(),
        isTrue,
        reason: 'La pagina Corsi deve esistere.',
      );

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        source,
        contains("import '../widgets/corso_documenti_dialog.dart';"),
        reason:
            'CorsiPage deve importare '
            'CorsoDocumentiDialog.',
      );

      expect(
        source,
        contains('Future<void> apriDialogModelliWord(Corso corso) async'),
        reason:
            'CorsiPage deve avere un metodo dedicato '
            'all apertura dei modelli Word.',
      );

      expect(
        source,
        contains('CorsoDocumentiDialog(corso: corso)'),
        reason:
            'Il metodo deve aprire '
            'CorsoDocumentiDialog per il corso selezionato.',
      );

      expect(
        source,
        contains('barrierDismissible: false'),
        reason:
            'Il dialog dei modelli deve seguire '
            'il pattern non dismissibile dei codici piattaforma.',
      );

      expect(
        RegExp(
          r'apriDialogModelliWord\(Corso corso\)[\s\S]*?'
          r'if\s*\(\s*modificato\s*==\s*true\s*\)'
          r'[\s\S]*?await\s+caricaCorsi\(\)',
        ).hasMatch(source),
        isTrue,
        reason:
            'Dopo una modifica ai modelli Word '
            'la lista corsi deve essere ricaricata.',
      );

      final occorrenzeGestisciModelli = RegExp(
        r'Gestisci modelli Word',
      ).allMatches(source).length;

      expect(
        occorrenzeGestisciModelli,
        greaterThanOrEqualTo(2),
        reason:
            'Gestisci modelli Word deve essere raggiungibile '
            'sia dal dialog Modifica corso '
            'sia dalle azioni della riga.',
      );

      expect(
        RegExp(
          r"Tooltip\s*\([\s\S]*?"
          r"message\s*:\s*'Gestisci modelli Word'"
          r"[\s\S]*?"
          r'apriDialogModelliWord\s*\(',
        ).hasMatch(source),
        isTrue,
        reason:
            'La riga del corso deve avere '
            'una azione Gestisci modelli Word.',
      );

      expect(
        RegExp(
          r"OutlinedButton\.icon\s*\([\s\S]*?"
          r'apriDialogModelliWord\s*\(\s*corso\s*\)'
          r"[\s\S]*?"
          r"label\s*:\s*const\s+Text\(\s*'Gestisci modelli Word'\s*\)",
        ).hasMatch(source),
        isTrue,
        reason:
            'Il dialog Modifica corso deve offrire '
            'il pulsante Gestisci modelli Word.',
      );
    });

    test('preserva i percorsi Word quando modifica il corso', () {
      final file = File('lib/pages/corsi_page.dart');

      expect(
        file.existsSync(),
        isTrue,
        reason: 'La pagina Corsi deve esistere.',
      );

      if (!file.existsSync()) {
        return;
      }

      final source = file.readAsStringSync();

      expect(
        RegExp(
          r'modelloTestWordPath\s*:\s*'
          r'corso\.modelloTestWordPath',
        ).hasMatch(source),
        isTrue,
        reason:
            'Salva modifiche deve conservare '
            'il modello Word Test già associato.',
      );

      expect(
        RegExp(
          r'modelloGradimentoWordPath\s*:\s*'
          r'corso\.modelloGradimentoWordPath',
        ).hasMatch(source),
        isTrue,
        reason:
            'Salva modifiche deve conservare '
            'il modello Word Gradimento già associato.',
      );
    });
  });
}
