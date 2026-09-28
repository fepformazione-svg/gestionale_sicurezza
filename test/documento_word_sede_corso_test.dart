import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/services/documento_word_context.dart';

void main() {
  test('DOC008D espone SEDE_CORSO completa per i modelli Word esistenti', () {
    const contesto = DocumentoWordContext(
      nome: 'Mario',
      cognome: 'Rossi',
      codiceFiscale: 'RSSMRA80A01H501U',
      luogoNascita: 'Roma',
      dataNascita: '01/01/1980',
      corso: 'Formazione lavoratori rischio alto',
      protocollo: 'FP-2026-123',
      dataCorso: '29/09/2026',
      sede: 'UFFICI CARDO',
      indirizzoSede: 'VIA FRANCESCO ANTOLISEI 6',
      comuneSede: 'ROMA',
      docenteNome: 'Luca',
      docenteCognome: 'Bianchi',
      docenteQualifica: 'Docente formatore',
      impresa: 'Impresa Demo S.r.l.',
    );

    expect(
      contesto.placeholderValues['{{SEDE_CORSO}}'],
      'UFFICI CARDO - VIA FRANCESCO ANTOLISEI 6 - ROMA',
      reason:
          'I modelli Word esistenti usano {{SEDE_CORSO}} '
          'e devono ricevere sede, indirizzo e comune associati.',
    );
  });
}
