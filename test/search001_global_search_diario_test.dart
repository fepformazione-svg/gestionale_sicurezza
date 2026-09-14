import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEARCH001 propaga la ricerca globale alla pagina Diario', () {
    final diarioSource = File('lib/pages/diario_page.dart').readAsStringSync();

    final homeSource = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      diarioSource,
      contains('final String globalSearch;'),
      reason:
          'DiarioPage deve esporre il valore '
          'della ricerca globale.',
    );

    expect(
      RegExp(
        r"const\s+DiarioPage\s*\(\s*\{[\s\S]*?"
        r"this\.soloDaFatturare\s*=\s*false[\s\S]*?"
        r"this\.globalSearch\s*=\s*''[\s\S]*?"
        r"\}\s*\);",
      ).hasMatch(diarioSource),
      isTrue,
      reason:
          'Il costruttore di DiarioPage deve mantenere '
          'soloDaFatturare e accettare globalSearch.',
    );

    expect(
      diarioSource,
      contains('_cercaController.text = widget.globalSearch;'),
      reason:
          'Il controller locale del Diario deve essere '
          'inizializzato con la ricerca globale.',
    );

    expect(
      diarioSource,
      contains('oldWidget.globalSearch != widget.globalSearch'),
      reason:
          'DiarioPage deve rilevare le variazioni '
          'della ricerca globale.',
    );

    expect(
      RegExp(
        r'if\s*\(\s*oldWidget\.globalSearch\s*!='
        r'\s*widget\.globalSearch\s*\)'
        r'[\s\S]*?_cercaController\.text\s*='
        r'\s*widget\.globalSearch'
        r'[\s\S]*?caricaDiario\(\)',
      ).hasMatch(diarioSource),
      isTrue,
      reason:
          'Quando cambia globalSearch il Diario deve '
          'sincronizzare il controller e ricaricare i dati.',
    );

    expect(
      RegExp(
        r'DiarioPage\s*\(\s*[\s\S]*?'
        r'soloDaFatturare\s*:\s*diarioSoloDaFatturare'
        r'[\s\S]*?globalSearch\s*:\s*globalSearch'
        r'[\s\S]*?\)',
      ).hasMatch(homeSource),
      isTrue,
      reason:
          'HomePage deve propagare globalSearch al Diario '
          'mantenendo il filtro soloDaFatturare.',
    );

    expect(
      diarioSource,
      contains('final ricerca = _cercaController.text.trim();'),
      reason:
          'La ricerca globale deve riutilizzare '
          'la ricerca SQLite già esistente nel Diario.',
    );
  });
}
