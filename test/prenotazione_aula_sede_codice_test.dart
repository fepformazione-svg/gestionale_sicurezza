import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEDI001 Prenotazioni usa il codice breve nel lookup e nella tendina', () {
    final databaseSource = File(
      'lib/services/database_service.dart',
    ).readAsStringSync();

    final dialogSource = File(
      'lib/widgets/prenotazione_dialog.dart',
    ).readAsStringSync();

    expect(
      databaseSource,
      matches(
        RegExp(
          r'SELECT\s+'
          r'id,\s+'
          r'codice,\s+'
          r'denominazione,\s+'
          r'tipo,\s+'
          r'indirizzo,\s+'
          r'comune,\s+'
          r'attiva\s+'
          r'FROM aule_sedi',
          multiLine: true,
        ),
      ),
      reason:
          'Il lookup delle Aule/Sedi deve restituire anche il codice breve.',
    );

    expect(
      dialogSource,
      matches(
        RegExp(
          r"final codice = \(item\['codice'\] \?\? ''\)"
          r'\s*\.toString\(\);',
          multiLine: true,
        ),
      ),
      reason: 'La tendina Prenotazioni deve leggere il codice della sede.',
    );

    expect(
      dialogSource,
      matches(
        RegExp(
          r'final descrizione = \[\s*'
          r'if \(codice\.isNotEmpty\) codice,\s*'
          r'denominazione,\s*'
          r'if \(tipo\.isNotEmpty\) tipo,\s*'
          r'if \(comune\.isNotEmpty\) comune,\s*'
          r"\]\.join\(' - '\);",
          multiLine: true,
        ),
      ),
      reason: 'La tendina deve mostrare codice, denominazione, tipo e comune.',
    );

    expect(
      dialogSource,
      contains('child: Text(descrizione),'),
      reason:
          'Il testo visibile della tendina deve usare la descrizione completa.',
    );
  });
}
