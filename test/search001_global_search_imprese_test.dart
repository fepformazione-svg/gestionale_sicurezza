import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEARCH001 propaga la ricerca globale alla pagina Imprese', () {
    final impreseSource = File(
      'lib/pages/imprese_page.dart',
    ).readAsStringSync();

    final homeSource = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      impreseSource,
      contains('final String globalSearch;'),
      reason:
          'ImpresePage deve esporre il valore '
          'della ricerca globale.',
    );

    expect(
      RegExp(
        r"const\s+ImpresePage\s*\(\s*\{[\s\S]*?"
        r"this\.globalSearch\s*=\s*''[\s\S]*?"
        r"\}\s*\);",
      ).hasMatch(impreseSource),
      isTrue,
      reason:
          'Il costruttore di ImpresePage deve accettare '
          'globalSearch con valore predefinito vuoto.',
    );

    expect(
      RegExp(
        r'TextEditingController\s+'
        r'\w*[Rr]icerca\w*\s*=\s*'
        r'TextEditingController\(\)',
      ).hasMatch(impreseSource),
      isTrue,
      reason:
          'La ricerca locale di Imprese deve avere '
          'un controller sincronizzabile.',
    );

    expect(
      RegExp(
        r'\w*[Rr]icerca\w*\.text\s*=\s*'
        r'widget\.globalSearch',
      ).hasMatch(impreseSource),
      isTrue,
      reason:
          'La barra locale di Imprese deve mostrare '
          'la ricerca globale ricevuta.',
    );

    expect(
      impreseSource,
      contains('void didUpdateWidget(covariant ImpresePage oldWidget)'),
      reason:
          'ImpresePage deve reagire alle variazioni '
          'della ricerca globale.',
    );

    expect(
      impreseSource,
      contains('oldWidget.globalSearch != widget.globalSearch'),
      reason:
          'ImpresePage deve rilevare quando '
          'globalSearch cambia.',
    );

    expect(
      RegExp(
        r'AppSearchBar\s*\([\s\S]*?'
        r'controller\s*:\s*\w*[Rr]icerca\w*'
        r'[\s\S]*?onChanged\s*:\s*cercaImprese',
      ).hasMatch(impreseSource),
      isTrue,
      reason:
          'AppSearchBar di Imprese deve usare '
          'il controller sincronizzato mantenendo '
          'cercaImprese come ricerca locale.',
    );

    expect(
      RegExp(
        r'ImpresePage\s*\(\s*'
        r'globalSearch\s*:\s*globalSearch'
        r'\s*,?\s*\)',
      ).hasMatch(homeSource),
      isTrue,
      reason:
          'HomePage deve propagare globalSearch '
          'alla pagina Imprese.',
    );
  });
}
