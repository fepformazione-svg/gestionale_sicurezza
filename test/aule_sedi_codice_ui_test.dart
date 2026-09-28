import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEDI001 UI Aule Sedi gestisce il codice breve in creazione e modifica', () {
    final source = File('lib/pages/aule_sedi_page.dart').readAsStringSync();

    expect(
      source,
      contains('final codiceController = TextEditingController();'),
      reason: 'La nuova sede deve avere un controller dedicato al codice.',
    );

    expect(
      source,
      contains(
        'final codiceController = TextEditingController(text: aulaSede.codice);',
      ),
      reason: 'La modifica deve caricare il codice esistente della sede.',
    );

    final labelCodice = RegExp("labelText: 'Codice'").allMatches(source).length;

    expect(
      labelCodice,
      greaterThanOrEqualTo(2),
      reason:
          'Il campo Codice deve essere visibile sia in Nuova voce sia in Modifica.',
    );

    final salvataggiCodice = RegExp(
      r'codice:\s*codiceController\.text\.trim\(\)\.toUpperCase\(\),',
    ).allMatches(source).length;

    expect(
      salvataggiCodice,
      greaterThanOrEqualTo(2),
      reason: 'Il codice deve essere salvato sia in creazione sia in modifica.',
    );

    final disposeCodice = RegExp(
      r'codiceController\.dispose\(\);',
    ).allMatches(source).length;

    expect(
      disposeCodice,
      greaterThanOrEqualTo(2),
      reason: 'Il controller del codice deve essere correttamente rilasciato.',
    );
  });
}
