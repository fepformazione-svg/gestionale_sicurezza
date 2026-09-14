import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DIARIO002 corregge i testi UTF-8 di fattura e Da fatturare', () {
    final source = File('lib/pages/diario_page.dart').readAsStringSync();

    const testiAttesi = <String>[
      'Fattura già inserita. Svuota prima il riferimento fattura per modificare Da fatturare',
      'Salvando una fattura, il corso verrà rimosso automaticamente dai Da fatturare.',
      'Vuoi rimuovere il riferimento fattura da questo corso? Dopo la rimozione, il campo Da fatturare tornerà modificabile manualmente.',
      'Riferimento fattura salvato. Il corso è stato rimosso dai Da fatturare.',
      'Il corso è da fatturare. Clicca per rimuoverlo dai Da fatturare',
      'Il corso non è da fatturare. Clicca per segnarlo come Da fatturare',
      'Fattura già inserita. Per modificare Da fatturare, svuota prima il riferimento fattura.',
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
