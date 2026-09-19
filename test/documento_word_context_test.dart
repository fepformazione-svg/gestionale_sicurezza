import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/services/documento_word_context.dart';

void main() {
  group('DOC004 DocumentoWordContext', () {
    DocumentoWordContext creaContestoCompleto() {
      return const DocumentoWordContext(
        nome: 'Mario',
        cognome: 'Rossi',
        codiceFiscale: 'RSSMRA80A01H501U',
        luogoNascita: 'Roma',
        dataNascita: '01/01/1980',
        corso: 'Formazione lavoratori rischio alto',
        protocollo: 'FP-2026-123',
        dataCorso: '19/09/2026',
        sede: 'Aula Roma',
        indirizzoSede: 'Via Esempio 10',
        comuneSede: 'Roma',
        docenteNome: 'Luca',
        docenteCognome: 'Bianchi',
        docenteQualifica: 'Docente formatore',
        impresa: 'Impresa Demo S.r.l.',
      );
    }

    test('espone i placeholder standard per il modello Word', () {
      final contesto = creaContestoCompleto();

      expect(contesto.placeholderValues, {
        '{{NOME}}': 'Mario',
        '{{COGNOME}}': 'Rossi',
        '{{NOME_COGNOME}}': 'Mario Rossi',
        '{{CODICE_FISCALE}}': 'RSSMRA80A01H501U',
        '{{LUOGO_NASCITA}}': 'Roma',
        '{{DATA_NASCITA}}': '01/01/1980',
        '{{CORSO}}': 'Formazione lavoratori rischio alto',
        '{{PROTOCOLLO}}': 'FP-2026-123',
        '{{DATA_CORSO}}': '19/09/2026',
        '{{SEDE}}': 'Aula Roma',
        '{{INDIRIZZO_SEDE}}': 'Via Esempio 10',
        '{{COMUNE_SEDE}}': 'Roma',
        '{{DOCENTE}}': 'Luca Bianchi',
        '{{QUALIFICA_DOCENTE}}': 'Docente formatore',
        '{{IMPRESA}}': 'Impresa Demo S.r.l.',
      });
    });

    test(
      'crea una copia vuota mantenendo i dati del corso e cancellando il corsista',
      () {
        final contesto = creaContestoCompleto();

        final vuoto = contesto.senzaDiscente();

        expect(vuoto.nome, '');
        expect(vuoto.cognome, '');
        expect(vuoto.codiceFiscale, '');
        expect(vuoto.luogoNascita, '');
        expect(vuoto.dataNascita, '');

        expect(vuoto.corso, contesto.corso);
        expect(vuoto.protocollo, contesto.protocollo);
        expect(vuoto.dataCorso, contesto.dataCorso);
        expect(vuoto.sede, contesto.sede);
        expect(vuoto.indirizzoSede, contesto.indirizzoSede);
        expect(vuoto.comuneSede, contesto.comuneSede);
        expect(vuoto.docenteNome, contesto.docenteNome);
        expect(vuoto.docenteCognome, contesto.docenteCognome);
        expect(vuoto.docenteQualifica, contesto.docenteQualifica);
        expect(vuoto.impresa, contesto.impresa);

        expect(vuoto.placeholderValues['{{NOME}}'], '');
        expect(vuoto.placeholderValues['{{COGNOME}}'], '');
        expect(vuoto.placeholderValues['{{NOME_COGNOME}}'], '');
        expect(vuoto.placeholderValues['{{CODICE_FISCALE}}'], '');
        expect(vuoto.placeholderValues['{{LUOGO_NASCITA}}'], '');
        expect(vuoto.placeholderValues['{{DATA_NASCITA}}'], '');

        expect(
          vuoto.placeholderValues['{{CORSO}}'],
          'Formazione lavoratori rischio alto',
        );
        expect(vuoto.placeholderValues['{{PROTOCOLLO}}'], 'FP-2026-123');
      },
    );
  });
}
