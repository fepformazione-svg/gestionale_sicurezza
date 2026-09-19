import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/models/corso.dart';

void main() {
  group('Corso - documenti Word', () {
    test('fromMap carica i percorsi Test e Gradimento', () {
      final corso = Corso.fromMap({
        'id': 7,
        'denominazione': 'Corso di prova',
        'durata_ore': 8,
        'validita_anni': 5,
        'modello_test_word_path': r'C:\Modelli\Test.docx',
        'modello_gradimento_word_path': r'C:\Modelli\Gradimento.docx',
      });

      expect(corso.modelloTestWordPath, r'C:\Modelli\Test.docx');

      expect(corso.modelloGradimentoWordPath, r'C:\Modelli\Gradimento.docx');
    });

    test('toMap salva i percorsi Test e Gradimento', () {
      final corso = Corso.fromMap({
        'id': 7,
        'denominazione': 'Corso di prova',
        'durata_ore': 8,
        'validita_anni': 5,
        'modello_test_word_path': r'C:\Modelli\Test.docx',
        'modello_gradimento_word_path': r'C:\Modelli\Gradimento.docx',
      });

      final map = corso.toMap();

      expect(map['modello_test_word_path'], r'C:\Modelli\Test.docx');

      expect(
        map['modello_gradimento_word_path'],
        r'C:\Modelli\Gradimento.docx',
      );
    });

    test('i nuovi campi restano null per i corsi esistenti', () {
      final corso = Corso.fromMap({
        'id': 8,
        'denominazione': 'Corso esistente',
        'durata_ore': 4,
        'validita_anni': 0,
      });

      expect(corso.modelloTestWordPath, isNull);

      expect(corso.modelloGradimentoWordPath, isNull);
    });
  });
}
