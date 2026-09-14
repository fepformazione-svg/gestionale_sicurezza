import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEARCH001 propaga la ricerca globale alla pagina Corsi', () {
    final corsiSource = File('lib/pages/corsi_page.dart').readAsStringSync();

    final homeSource = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      corsiSource,
      contains('final String globalSearch;'),
      reason:
          'CorsiPage deve esporre il valore '
          'della ricerca globale.',
    );

    expect(
      RegExp(
        r"const\s+CorsiPage\s*\(\s*\{[\s\S]*?"
        r"this\.globalSearch\s*=\s*''[\s\S]*?"
        r"\}\s*\);",
      ).hasMatch(corsiSource),
      isTrue,
      reason:
          'Il costruttore di CorsiPage deve accettare '
          'globalSearch con valore predefinito vuoto.',
    );

    expect(
      RegExp(
        r'TextEditingController\s+'
        r'\w*[Rr]icerca\w*\s*=\s*'
        r'TextEditingController\(\)',
      ).hasMatch(corsiSource),
      isTrue,
      reason:
          'La ricerca locale di Corsi deve avere '
          'un controller sincronizzabile.',
    );

    expect(
      RegExp(
        r'\w*[Rr]icerca\w*\.text\s*=\s*'
        r'widget\.globalSearch',
      ).hasMatch(corsiSource),
      isTrue,
      reason:
          'La barra locale di Corsi deve mostrare '
          'la ricerca globale ricevuta.',
    );

    expect(
      corsiSource,
      contains('void didUpdateWidget(covariant CorsiPage oldWidget)'),
      reason:
          'CorsiPage deve reagire alle variazioni '
          'della ricerca globale.',
    );

    expect(
      corsiSource,
      contains('oldWidget.globalSearch != widget.globalSearch'),
      reason:
          'CorsiPage deve rilevare quando '
          'globalSearch cambia.',
    );

    expect(
      RegExp(
        r'AppSearchBar\s*\([\s\S]*?'
        r'controller\s*:\s*\w*[Rr]icerca\w*'
        r'[\s\S]*?onChanged\s*:\s*cercaCorsi',
      ).hasMatch(corsiSource),
      isTrue,
      reason:
          'AppSearchBar di Corsi deve usare '
          'il controller sincronizzato mantenendo '
          'cercaCorsi come ricerca locale.',
    );

    expect(
      RegExp(
        r'CorsiPage\s*\(\s*'
        r'globalSearch\s*:\s*globalSearch'
        r'\s*,?\s*\)',
      ).hasMatch(homeSource),
      isTrue,
      reason:
          'HomePage deve propagare globalSearch '
          'alla pagina Corsi.',
    );
  });
}
