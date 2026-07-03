import '../models/assistente_operativo_item.dart';
import 'app_database.dart';

class AssistenteOperativoService {
  final AppDatabase database;

  const AssistenteOperativoService(this.database);

  Future<List<AssistenteOperativoItem>> generaRiepilogoOperativo() async {
    final conteggi = await Future.wait<int>([
      database.contaScadenzeScaduteAssistente(),
      database.contaScadenzeInScadenzaAssistente(),
      database.contaPraticheDaFatturareAssistente(),
      database.contaPrenotazioniAperteAssistente(),
      database.contaVisiteMedicheScaduteAssistente(),
      database.contaVisiteMedicheInScadenzaAssistente(),
    ]);

    final scadenzeScadute = conteggi[0];
    final scadenzeInScadenza = conteggi[1];
    final praticheDaFatturare = conteggi[2];
    final prenotazioniAperte = conteggi[3];
    final visiteMedicheScadute = conteggi[4];
    final visiteMedicheInScadenza = conteggi[5];

    final items = <AssistenteOperativoItem>[];

    _aggiungiSePresente(
      items,
      AssistenteOperativoItem(
        titolo: 'Scadenze scadute',
        descrizione:
            'Ci sono $scadenzeScadute scadenze già scadute da verificare.',
        conteggio: scadenzeScadute,
        priorita: PrioritaAssistenteOperativo.alta,
        modulo: ModuloAssistenteOperativo.scadenze,
        azioneSuggerita: 'Apri il modulo Scadenze e verifica i rinnovi.',
      ),
    );

    _aggiungiSePresente(
      items,
      AssistenteOperativoItem(
        titolo: 'Scadenze in scadenza',
        descrizione:
            'Ci sono $scadenzeInScadenza scadenze prossime alla scadenza.',
        conteggio: scadenzeInScadenza,
        priorita: PrioritaAssistenteOperativo.media,
        modulo: ModuloAssistenteOperativo.scadenze,
        azioneSuggerita: 'Programma i rinnovi prima della scadenza.',
      ),
    );

    _aggiungiSePresente(
      items,
      AssistenteOperativoItem(
        titolo: 'Pratiche da fatturare',
        descrizione:
            'Ci sono $praticheDaFatturare pratiche segnate come da fatturare.',
        conteggio: praticheDaFatturare,
        priorita: PrioritaAssistenteOperativo.alta,
        modulo: ModuloAssistenteOperativo.diario,
        azioneSuggerita: 'Apri il Diario e controlla le pratiche da fatturare.',
      ),
    );

    _aggiungiSePresente(
      items,
      AssistenteOperativoItem(
        titolo: 'Prenotazioni aperte',
        descrizione: 'Ci sono $prenotazioniAperte prenotazioni ancora aperte.',
        conteggio: prenotazioniAperte,
        priorita: PrioritaAssistenteOperativo.media,
        modulo: ModuloAssistenteOperativo.prenotazioni,
        azioneSuggerita: 'Verifica le prenotazioni ancora da chiudere.',
      ),
    );

    _aggiungiSePresente(
      items,
      AssistenteOperativoItem(
        titolo: 'Visite mediche scadute',
        descrizione:
            'Ci sono $visiteMedicheScadute visite mediche già scadute.',
        conteggio: visiteMedicheScadute,
        priorita: PrioritaAssistenteOperativo.alta,
        modulo: ModuloAssistenteOperativo.visiteMediche,
        azioneSuggerita: 'Apri Visite Mediche e aggiorna le scadenze.',
      ),
    );

    _aggiungiSePresente(
      items,
      AssistenteOperativoItem(
        titolo: 'Visite mediche in scadenza',
        descrizione:
            'Ci sono $visiteMedicheInScadenza visite mediche in scadenza.',
        conteggio: visiteMedicheInScadenza,
        priorita: PrioritaAssistenteOperativo.media,
        modulo: ModuloAssistenteOperativo.visiteMediche,
        azioneSuggerita: 'Pianifica le visite mediche da rinnovare.',
      ),
    );

    _ordinaPerPrioritaOperativa(items);

    return items;
  }

  void _ordinaPerPrioritaOperativa(List<AssistenteOperativoItem> items) {
    items.sort((a, b) {
      final confrontoPeso = _pesoPrioritaOperativa(
        a,
      ).compareTo(_pesoPrioritaOperativa(b));

      if (confrontoPeso != 0) {
        return confrontoPeso;
      }

      final confrontoConteggio = b.conteggio.compareTo(a.conteggio);

      if (confrontoConteggio != 0) {
        return confrontoConteggio;
      }

      return a.titolo.compareTo(b.titolo);
    });
  }

  int _pesoPrioritaOperativa(AssistenteOperativoItem item) {
    switch (item.priorita) {
      case PrioritaAssistenteOperativo.alta:
        switch (item.modulo) {
          case ModuloAssistenteOperativo.scadenze:
            return 10;
          case ModuloAssistenteOperativo.visiteMediche:
            return 20;
          case ModuloAssistenteOperativo.diario:
            return 30;
          case ModuloAssistenteOperativo.prenotazioni:
            return 40;
          case ModuloAssistenteOperativo.dashboard:
          case ModuloAssistenteOperativo.discenti:
          case ModuloAssistenteOperativo.imprese:
          case ModuloAssistenteOperativo.consensiPrivacy:
            return 90;
        }

      case PrioritaAssistenteOperativo.media:
        switch (item.modulo) {
          case ModuloAssistenteOperativo.scadenze:
            return 110;
          case ModuloAssistenteOperativo.visiteMediche:
            return 120;
          case ModuloAssistenteOperativo.prenotazioni:
            return 130;
          case ModuloAssistenteOperativo.diario:
            return 140;
          case ModuloAssistenteOperativo.dashboard:
          case ModuloAssistenteOperativo.discenti:
          case ModuloAssistenteOperativo.imprese:
          case ModuloAssistenteOperativo.consensiPrivacy:
            return 190;
        }

      case PrioritaAssistenteOperativo.bassa:
        switch (item.modulo) {
          case ModuloAssistenteOperativo.scadenze:
            return 210;
          case ModuloAssistenteOperativo.visiteMediche:
            return 220;
          case ModuloAssistenteOperativo.prenotazioni:
            return 230;
          case ModuloAssistenteOperativo.diario:
            return 240;
          case ModuloAssistenteOperativo.dashboard:
          case ModuloAssistenteOperativo.discenti:
          case ModuloAssistenteOperativo.imprese:
          case ModuloAssistenteOperativo.consensiPrivacy:
            return 290;
        }
    }
  }

  void _aggiungiSePresente(
    List<AssistenteOperativoItem> items,
    AssistenteOperativoItem item,
  ) {
    if (item.haElementi) {
      items.add(item);
    }
  }
}
