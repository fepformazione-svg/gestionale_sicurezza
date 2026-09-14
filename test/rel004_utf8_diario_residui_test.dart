import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('REL004 corregge i residui UTF-8 nel Diario', () {
    final source = File('lib/pages/diario_page.dart').readAsStringSync();

    const testiAttesi = <String>[
      "].join(' · ');",
      'Corso già rinnovato',
      'Attendi il completamento del rinnovo già avviato',
      'Il gestionale userà il corso di aggiornamento corrispondente, se presente, e aggiungerà il nuovo record nel Diario.',
    ];

    for (final testo in testiAttesi) {
      expect(
        source,
        contains(testo),
        reason: 'Testo UTF-8 corretto non trovato: $testo',
      );
    }
  });
}