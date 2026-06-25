import 'package:flutter/foundation.dart';

import '../models/utente_app.dart';
import '../models/ruolo_utente.dart';

class SessioneUtenteService {
  SessioneUtenteService._();

  static final SessioneUtenteService instance = SessioneUtenteService._();

  final ValueNotifier<int> notificatoreSessione = ValueNotifier<int>(0);

  UtenteApp? _utenteCorrente;

  UtenteApp? get utenteCorrente => _utenteCorrente;

  bool get utenteLoggato => _utenteCorrente != null;

  String get usernameCorrente => _utenteCorrente?.username ?? 'Nessun utente';

  String get nomeVisualizzato {
    final utente = _utenteCorrente;
    if (utente == null) return 'Nessun utente';

    return utente.username;
  }

  String _normalizzaRuolo(String valore) {
    return valore
        .trim()
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ù', 'u');
  }

  String nomeRuoloCorrente(List<RuoloUtente> ruoli) {
    final utente = _utenteCorrente;
    if (utente == null || utente.ruoloId == null) {
      return '';
    }

    for (final ruolo in ruoli) {
      if (ruolo.id == utente.ruoloId) {
        return ruolo.nome;
      }
    }

    return '';
  }

  bool utenteCorrenteAmministratore(List<RuoloUtente> ruoli) {
    final nomeRuolo = _normalizzaRuolo(nomeRuoloCorrente(ruoli));

    return nomeRuolo == 'amministratore' ||
        nomeRuolo == 'admin' ||
        nomeRuolo == 'administrator';
  }

  bool puoGestireUtenti(List<RuoloUtente> ruoli) {
    return utenteLoggato && utenteCorrenteAmministratore(ruoli);
  }

  void impostaUtenteCorrente(UtenteApp utente) {
    _utenteCorrente = utente;
    notificatoreSessione.value++;
  }

  void svuotaSessione() {
    _utenteCorrente = null;
    notificatoreSessione.value++;
  }
}
