import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NOTIF001 Home collega priorita reali alla campanella', () {
    final source = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      source,
      contains('List<AssistenteOperativoItem> notificationItems ='),
      reason:
          'HomePage deve possedere lo stato delle priorita mostrate nella campanella.',
    );

    expect(
      source,
      contains('AssistenteOperativoService(AppDatabase.instance)'),
      reason: 'HomePage deve riutilizzare il servizio operativo gia esistente.',
    );

    expect(
      source,
      contains('Future<void> _caricaNotificheOperative()'),
      reason:
          'HomePage deve avere un caricamento dedicato delle notifiche operative.',
    );

    expect(
      source,
      contains('generaRiepilogoOperativo()'),
      reason:
          'Le notifiche devono provenire dal riepilogo operativo esistente.',
    );

    expect(
      source,
      contains('notificationItems = riepilogo'),
      reason:
          'Il risultato del servizio deve aggiornare lo stato della campanella.',
    );

    expect(
      source,
      contains('notificationItems: notificationItems'),
      reason: 'HomePage deve passare le priorita reali ad AppTopbar.',
    );

    expect(
      source,
      contains('onNotificationSelected:'),
      reason: 'HomePage deve gestire il click su una voce della campanella.',
    );
  });

  test('NOTIF001 usa una sola navigazione operativa condivisa', () {
    final source = File('lib/pages/home_page.dart').readAsStringSync();

    expect(
      source,
      contains('void _apriPrioritaOperativa('),
      reason: 'La navigazione delle priorita deve essere centralizzata.',
    );

    expect(
      source,
      contains('AssistenteOperativoItem item'),
      reason:
          'La navigazione condivisa deve lavorare direttamente sul model operativo.',
    );

    expect(source, contains("filtroScadenze = 'scaduti'"));

    expect(source, contains("filtroScadenze = 'in_scadenza'"));

    expect(source, contains('diarioSoloDaFatturare = true'));

    expect(source, contains("filtroVisiteMediche = 'Scadute'"));

    expect(source, contains("filtroVisiteMediche = 'In scadenza'"));

    expect(
      source,
      contains('_apriPrioritaOperativa(item)'),
      reason: 'Il click della campanella deve usare la navigazione condivisa.',
    );
  });
}
