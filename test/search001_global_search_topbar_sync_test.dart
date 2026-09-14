import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SEARCH001 mantiene sincronizzato il testo visibile della topbar', () {
    final topbarSource = File('lib/widgets/app_topbar.dart').readAsStringSync();

    final homeSource = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      topbarSource,
      contains('class AppTopbar extends StatefulWidget'),
      reason:
          'AppTopbar deve gestire un controller interno '
          'sincronizzato con lo stato globale.',
    );

    expect(
      topbarSource,
      contains('final String searchText;'),
      reason:
          'AppTopbar deve ricevere il valore corrente '
          'della ricerca globale.',
    );

    expect(
      topbarSource,
      contains("this.searchText = ''"),
      reason: 'searchText deve avere valore iniziale vuoto.',
    );

    expect(
      topbarSource,
      contains('TextEditingController'),
      reason: 'La topbar deve avere un controller del campo ricerca.',
    );

    expect(
      topbarSource,
      contains('widget.searchText'),
      reason:
          'Il controller della topbar deve essere sincronizzato '
          'con searchText.',
    );

    expect(
      topbarSource,
      contains('didUpdateWidget(covariant AppTopbar oldWidget)'),
      reason:
          'La topbar deve reagire agli aggiornamenti '
          'programmatici di globalSearch.',
    );

    expect(
      topbarSource,
      contains('oldWidget.searchText != widget.searchText'),
      reason: 'La topbar deve rilevare quando cambia searchText.',
    );

    expect(
      RegExp(
        r'TextField\s*\([\s\S]*?'
        r'controller\s*:\s*_[A-Za-z0-9_]*search[A-Za-z0-9_]*Controller'
        r'[\s\S]*?onChanged\s*:\s*widget\.onSearchChanged',
        caseSensitive: false,
      ).hasMatch(topbarSource),
      isTrue,
      reason:
          'Il TextField della topbar deve usare il controller '
          'sincronizzato e mantenere onSearchChanged.',
    );

    expect(
      RegExp(
        r'AppTopbar\s*\([\s\S]*?'
        r'searchText\s*:\s*globalSearch[\s\S]*?'
        r'onSearchChanged\s*:\s*aggiornaRicercaGlobale'
        r'[\s\S]*?\)',
      ).hasMatch(homeSource),
      isTrue,
      reason:
          'HomePage deve passare globalSearch alla topbar '
          'oltre al callback onSearchChanged.',
    );

    expect(
      homeSource,
      contains("homeState.globalSearch = '';"),
      reason:
          'Il reset programmatico esistente deve restare '
          'compatibile con la sincronizzazione della topbar.',
    );
  });
}
