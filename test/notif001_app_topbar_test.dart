import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NOTIF001 AppTopbar espone priorita, badge e callback notifica', () {
    final source = File('lib/widgets/app_topbar.dart').readAsStringSync();

    expect(
      source,
      contains("import '../models/assistente_operativo_item.dart';"),
      reason: 'AppTopbar deve conoscere il model delle priorita operative.',
    );

    expect(
      source,
      contains('final List<AssistenteOperativoItem> notificationItems;'),
      reason: 'AppTopbar deve ricevere le priorita operative dalla Home.',
    );

    expect(
      source,
      contains(
        'final ValueChanged<AssistenteOperativoItem>? onNotificationSelected;',
      ),
      reason:
          'AppTopbar deve notificare alla Home quale voce e stata selezionata.',
    );

    expect(
      source,
      contains('notificationItems.length'),
      reason:
          'Il badge deve riflettere il numero di categorie operative attive.',
    );

    expect(
      source,
      contains("'99+'"),
      reason: 'Il badge deve gestire in modo sicuro conteggi elevati.',
    );

    expect(
      source,
      contains("'Nessuna priorità operativa'"),
      reason: 'Il pannello deve gestire anche lo stato senza priorita.',
    );

    expect(
      source,
      contains('item.titolo'),
      reason: 'Ogni notifica deve mostrare il titolo della priorita.',
    );

    expect(
      source,
      contains('item.conteggio'),
      reason: 'Ogni notifica deve mostrare il relativo conteggio.',
    );

    expect(
      source,
      contains('widget.onNotificationSelected?.call(item)'),
      reason: 'Il click su una notifica deve essere inoltrato alla Home.',
    );
  });
}
