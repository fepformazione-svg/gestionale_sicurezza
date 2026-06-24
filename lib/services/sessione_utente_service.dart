import '../models/utente_app.dart';

class SessioneUtenteService {
  SessioneUtenteService._();

  static final SessioneUtenteService instance = SessioneUtenteService._();

  UtenteApp? _utenteCorrente;

  UtenteApp? get utenteCorrente => _utenteCorrente;

  bool get utenteLoggato => _utenteCorrente != null;

  String get usernameCorrente => _utenteCorrente?.username ?? 'Nessun utente';

  String get nomeVisualizzato {
    final utente = _utenteCorrente;
    if (utente == null) return 'Nessun utente';

    return utente.username;
  }

  void impostaUtenteCorrente(UtenteApp utente) {
    _utenteCorrente = utente;
  }

  void svuotaSessione() {
    _utenteCorrente = null;
  }
}
