import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PREN010 allinea in alto Data corso e Protocollo',
    () {
      final source = File(
        'lib/widgets/prenotazione_dialog.dart',
      ).readAsStringSync();

      const dataLabel = "labelText: 'Data corso'";
      const protocolloLabel = "labelText: 'Protocollo'";

      final dataIndex = source.indexOf(dataLabel);
      expect(
        dataIndex,
        greaterThanOrEqualTo(0),
        reason: 'Campo Data corso non trovato.',
      );

      final protocolloIndex = source.indexOf(
        protocolloLabel,
        dataIndex,
      );
      expect(
        protocolloIndex,
        greaterThan(dataIndex),
        reason: 'Campo Protocollo non trovato dopo Data corso.',
      );

      final rowStart = source.lastIndexOf(
        'Row(',
        dataIndex,
      );
      expect(
        rowStart,
        greaterThanOrEqualTo(0),
        reason: 'Row contenente Data corso non trovata.',
      );

      final rowSource = source.substring(
        rowStart,
        protocolloIndex + protocolloLabel.length,
      );

      expect(
        rowSource,
        contains(
          'crossAxisAlignment: CrossAxisAlignment.start',
        ),
        reason:
            'Data corso e Protocollo devono essere '
            'allineati sul bordo superiore.',
      );
    },
  );
}
