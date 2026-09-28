import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_sicurezza/models/aula_sede.dart';

void main() {
  group('SEDI001 AulaSede codice', () {
    test('legge e salva il codice breve della sede', () {
      final aula = AulaSede.fromMap({
        'id': 1,
        'codice': 'UC',
        'denominazione': 'UFFICI CARDO',
        'tipo': 'Sede cliente',
        'indirizzo': 'VIA FRANCESCO ANTOLISEI 6',
        'comune': 'ROMA',
        'capienza': 20,
        'note': '',
        'attiva': 1,
      });

      expect(aula.codice, 'UC');
      expect(aula.toMap()['codice'], 'UC');

      final modificata = aula.copyWith(codice: 'UC2');

      expect(modificata.codice, 'UC2');
      expect(modificata.denominazione, 'UFFICI CARDO');
      expect(modificata.indirizzo, 'VIA FRANCESCO ANTOLISEI 6');
      expect(modificata.comune, 'ROMA');
    });
  });
}
