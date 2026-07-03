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

    return items;
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
