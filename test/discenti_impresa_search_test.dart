import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DISC001 rende ricercabile Impresa di appartenenza', () {
    final source = File('lib/pages/discenti_page.dart').readAsStringSync();

    expect(
      source,
      contains("import 'package:dropdown_search/dropdown_search.dart';"),
    );

    expect(source, contains('DropdownSearch<Impresa>'));

    expect(source, contains('showSearchBox: true'));

    expect(source, contains("'Impresa di appartenenza'"));

    expect(source, contains("'Cerca impresa'"));
  });
}
