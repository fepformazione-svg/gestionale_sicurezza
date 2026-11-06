import '../models/ruolo_utente.dart';
import '../models/utente_app.dart';

enum LanOperazionePrenotazioni {
  consultare,
  inserire,
  modificare,
  confermare,
  annullareConferma,
  eliminare,
}

/// Matrice dei permessi approvata per le Prenotazioni in LAN.
///
/// Non autentica l'utente e non apre il database: [utente] e [ruolo] devono
/// essere recuperati e verificati dal SERVER centrale, mai dal JSON del client.
/// Questa fase non abilita alcun endpoint di scrittura.
class LanPrenotazioniPermessiService {
  const LanPrenotazioniPermessiService();

  bool puoEseguire({
    required UtenteApp? utente,
    required RuoloUtente? ruolo,
    required LanOperazionePrenotazioni operazione,
  }) {
    final utenteId = utente?.id;
    final ruoloId = ruolo?.id;

    if (utente == null ||
        ruolo == null ||
        utenteId == null ||
        utenteId <= 0 ||
        ruoloId == null ||
        ruoloId <= 0 ||
        utente.ruoloId != ruoloId ||
        utente.username.trim().isEmpty ||
        !utente.isAttivo ||
        !ruolo.isAttivo) {
      return false;
    }

    final nomeRuolo = ruolo.nome.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (nomeRuolo == 'amministratore' ||
        nomeRuolo == 'admin' ||
        nomeRuolo == 'administrator') {
      return true;
    }

    if (nomeRuolo == 'operatore') {
      return operazione != LanOperazionePrenotazioni.eliminare;
    }

    if (nomeRuolo == 'solo lettura') {
      return operazione == LanOperazionePrenotazioni.consultare;
    }

    // Ruoli sconosciuti o nuovi non ricevono automaticamente privilegi.
    return false;
  }
}
