import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEDI001 elenco Aule Sedi mostra e ricerca il codice breve', () {
    final source = File('lib/pages/aule_sedi_page.dart').readAsStringSync();

    expect(
      source,
      matches(
        RegExp(
          r"final testo = \[\s*"
          r"aulaSede\.codice,\s*"
          r"aulaSede\.denominazione,",
          multiLine: true,
        ),
      ),
      reason: 'La ricerca Aule/Sedi deve comprendere il codice breve.',
    );

    expect(
      source,
      matches(
        RegExp(
          r"labelText:\s*"
          r"'Cerca codice, aula, sede, tipo, comune o note\.\.\.'",
          multiLine: true,
        ),
      ),
      reason:
          'Il suggerimento di ricerca deve indicare che e possibile cercare il codice.',
    );

    expect(
      source,
      contains("DataColumn(label: Text('Codice'))"),
      reason: 'La tabella Aule/Sedi deve avere una colonna Codice.',
    );

    expect(
      source,
      matches(
        RegExp(
          r"DataCell\(\s*"
          r"Text\(\s*"
          r"aulaSede\.codice\.isEmpty\s*"
          r"\?\s*'-'\s*"
          r":\s*aulaSede\.codice,\s*"
          r"\),\s*"
          r"\)",
          multiLine: true,
        ),
      ),
      reason:
          'La tabella deve mostrare il codice breve oppure - se non ancora assegnato.',
    );
  });
}
