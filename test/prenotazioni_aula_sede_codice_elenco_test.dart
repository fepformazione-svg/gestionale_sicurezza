import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEDI001 lista Prenotazioni mostra e ricerca il codice breve sede', () {
    final databaseSource = File(
      'lib/services/database_service.dart',
    ).readAsStringSync();

    final pageSource = File(
      'lib/pages/prenotazioni_page.dart',
    ).readAsStringSync();

    expect(
      databaseSource,
      contains('aula.codice AS aula_sede_codice,'),
      reason:
          'La query principale Prenotazioni deve restituire il codice breve della sede.',
    );

    expect(
      pageSource,
      contains("prenotazione['aula_sede_codice']?.toString().trim() ?? ''"),
      reason: 'Il testo Aula/Sede della lista deve leggere il codice breve.',
    );

    final riferimentiCodice = RegExp(
      r'aula_sede_codice',
    ).allMatches(pageSource).length;

    expect(
      riferimentiCodice,
      greaterThanOrEqualTo(2),
      reason:
          'Il codice deve essere usato sia nel testo/ricerca sia nella visualizzazione della riga Prenotazioni.',
    );

    final partiConCodice = RegExp(
      r'if\s*\(codice\.isNotEmpty\)\s*codice,',
    ).allMatches(pageSource).length;

    expect(
      partiConCodice,
      greaterThanOrEqualTo(2),
      reason:
          'La lista deve anteporre il codice sia nel helper sia nel rendering della riga.',
    );

    expect(
      databaseSource,
      contains("COALESCE(aula.denominazione, '') AS sede,"),
      reason:
          'La query documentale Word deve continuare a usare la denominazione completa della sede.',
    );
  });
}
