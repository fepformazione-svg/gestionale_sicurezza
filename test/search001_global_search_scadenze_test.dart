import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEARCH001 propaga la ricerca globale alla pagina Scadenze', () {
    final scadenzeSource = File(
      'lib/pages/scadenze_page.dart',
    ).readAsStringSync();

    final homeSource = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      scadenzeSource,
      contains('final String globalSearch;'),
      reason:
          'ScadenzePage deve esporre il valore '
          'della ricerca globale.',
    );

    expect(
      RegExp(
        r"const\s+ScadenzePage\s*\(\s*\{[\s\S]*?"
        r"this\.filtro\s*=\s*'tutte'[\s\S]*?"
        r"this\.globalSearch\s*=\s*''[\s\S]*?"
        r"\}\s*\);",
      ).hasMatch(scadenzeSource),
      isTrue,
      reason:
          'Il costruttore di ScadenzePage deve mantenere '
          'il filtro esistente e accettare globalSearch.',
    );

    expect(
      scadenzeSource,
      contains('_cercaController.text = widget.globalSearch;'),
      reason:
          'Il controller locale delle Scadenze deve essere '
          'inizializzato con la ricerca globale.',
    );

    expect(
      scadenzeSource,
      contains('void didUpdateWidget(covariant ScadenzePage oldWidget)'),
      reason:
          'ScadenzePage deve reagire alle variazioni '
          'della ricerca globale.',
    );

    expect(
      scadenzeSource,
      contains('oldWidget.globalSearch != widget.globalSearch'),
      reason:
          'ScadenzePage deve rilevare quando '
          'globalSearch cambia.',
    );

    expect(
      RegExp(
        r'if\s*\(\s*oldWidget\.globalSearch\s*!='
        r'\s*widget\.globalSearch\s*\)'
        r'[\s\S]*?_ricercaDebounce\?\.cancel\(\)'
        r'[\s\S]*?_cercaController\.text\s*='
        r'\s*widget\.globalSearch'
        r'[\s\S]*?caricaScadenze\(\)',
      ).hasMatch(scadenzeSource),
      isTrue,
      reason:
          'Quando cambia globalSearch, Scadenze deve '
          'annullare il debounce pendente, sincronizzare '
          'il controller e ricaricare i dati.',
    );

    expect(
      RegExp(
        r'ScadenzePage\s*\(\s*[\s\S]*?'
        r"key\s*:\s*ValueKey\('scadenze_\$filtroScadenze'\)"
        r'[\s\S]*?filtro\s*:\s*filtroScadenze'
        r'[\s\S]*?globalSearch\s*:\s*globalSearch'
        r'[\s\S]*?\)',
      ).hasMatch(homeSource),
      isTrue,
      reason:
          'HomePage deve propagare globalSearch a Scadenze '
          'senza cambiare la ValueKey del filtro.',
    );

    expect(
      scadenzeSource,
      contains('final ricerca = _cercaController.text.trim();'),
      reason:
          'La ricerca globale deve riutilizzare '
          'la ricerca SQLite già esistente.',
    );

    expect(
      scadenzeSource,
      contains('filtroStato: filtroStato'),
      reason:
          'La ricerca globale non deve eliminare '
          'il filtro stato Scadenze.',
    );
  });
}
