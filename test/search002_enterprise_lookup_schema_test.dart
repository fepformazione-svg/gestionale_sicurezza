import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SEARCH002 allinea EnterpriseLookupRepository allo schema SQLite reale',
    () {
      final repositorySource = File(
        'lib/services/enterprise_lookup_repository.dart',
      ).readAsStringSync();

      expect(
        RegExp(
          r'searchDiscenti[\s\S]*?'
          r"table:\s*'discenti'[\s\S]*?"
          r"textColumn:\s*'nome'",
        ).hasMatch(repositorySource),
        isTrue,
        reason:
            'Il lookup Discenti deve continuare a usare '
            'la colonna esistente nome.',
      );

      expect(
        RegExp(
          r'searchImprese[\s\S]*?'
          r"table:\s*'imprese'[\s\S]*?"
          r"textColumn:\s*'intestazione'",
        ).hasMatch(repositorySource),
        isTrue,
        reason:
            'La tabella imprese non ha una colonna nome: '
            'il lookup deve usare intestazione.',
      );

      expect(
        RegExp(
          r'searchCorsi[\s\S]*?'
          r"table:\s*'corsi'[\s\S]*?"
          r"textColumn:\s*'denominazione'",
        ).hasMatch(repositorySource),
        isTrue,
        reason:
            'La tabella corsi non ha una colonna nome: '
            'il lookup deve usare denominazione.',
      );
    },
  );
}
