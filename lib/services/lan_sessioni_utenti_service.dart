import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/ruolo_utente.dart';
import '../models/utente_app.dart';
import 'lan_autenticazione_utenti_service.dart';
import 'lan_prenotazioni_permessi_service.dart';

/// Credenziale temporanea emessa solo dopo il controllo delle credenziali.
///
/// [token] va consegnato al client soltanto attraverso un trasporto cifrato.
/// Non va scritto nei log, in SQLite o incluso nei messaggi di errore.
class LanSessioneUtenteCreata {
  const LanSessioneUtenteCreata({
    required this.token,
    required this.scadenzaUtc,
  });

  final String token;
  final DateTime scadenzaUtc;
}

class _LanSessioneRegistrata {
  const _LanSessioneRegistrata({
    required this.utenteId,
    required this.username,
    required this.ruoloId,
    required this.nomeRuolo,
    required this.scadenzaUtc,
  });

  final int utenteId;
  final String username;
  final int ruoloId;
  final String nomeRuolo;
  final DateTime scadenzaUtc;
}

/// Gestione isolata delle sessioni del SERVER LAN (NET015C3B2B).
///
/// Non si collega al server operativo e non scrive nel database. I token
/// casuali sono restituiti una sola volta e in memoria resta solo SHA-256.
/// Ogni verifica rilegge utente e ruolo da SQLite, invalidando le sessioni
/// se l'account viene disattivato o cambia la sua identita'/il suo ruolo.
///
/// Prima di esporre il login via HTTP servono TLS, limitazione dei tentativi,
/// protezione dei log e migrazione dell'hash password legacy.
class LanSessioniUtentiService {
  LanSessioniUtentiService({
    required Database database,
    Duration durata = const Duration(minutes: 30),
    int massimoSessioniAttive = 100,
    DateTime Function()? orologio,
  }) : _database = database,
       _autenticazione = LanAutenticazioneUtentiService(database),
       _durata = durata,
       _massimoSessioniAttive = massimoSessioniAttive,
       _orologio = orologio ?? DateTime.now {
    if (durata <= Duration.zero || durata > const Duration(hours: 12)) {
      throw ArgumentError.value(durata, 'durata', 'Durata non consentita.');
    }
    if (massimoSessioniAttive < 1 || massimoSessioniAttive > 10000) {
      throw ArgumentError.value(
        massimoSessioniAttive,
        'massimoSessioniAttive',
        'Limite non consentito.',
      );
    }
  }

  static final RegExp _formatoToken = RegExp(r'^[A-Za-z0-9_-]{43}$');

  final Database _database;
  final LanAutenticazioneUtentiService _autenticazione;
  final Duration _durata;
  final int _massimoSessioniAttive;
  final DateTime Function() _orologio;
  final Random _casuale = Random.secure();
  final Map<String, _LanSessioneRegistrata> _sessioni = {};

  DateTime _adessoUtc() => _orologio().toUtc();

  String _impronta(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  void _eliminaScadute() {
    final adesso = _adessoUtc();
    _sessioni.removeWhere(
      (_, sessione) => !adesso.isBefore(sessione.scadenzaUtc),
    );
  }

  int get numeroSessioniAttive {
    _eliminaScadute();
    return _sessioni.length;
  }

  /// Autentica con i dati del server; nessuna identita' arriva dal client.
  ///
  /// Restituisce null per credenziali errate o limite sessioni raggiunto.
  Future<LanSessioneUtenteCreata?> apriSessione({
    required String username,
    required String password,
  }) async {
    final identita = await _autenticazione.verificaCredenziali(
      username: username,
      password: password,
    );
    if (identita == null) {
      return null;
    }

    _eliminaScadute();
    if (_sessioni.length >= _massimoSessioniAttive) {
      return null;
    }

    final idUtente = identita.utente.id!;
    final idRuolo = identita.ruolo.id!;
    final scadenza = _adessoUtc().add(_durata);

    // 32 byte (256 bit) da un generatore crittografico del sistema operativo.
    for (var tentativo = 0; tentativo < 3; tentativo++) {
      final bytes = List<int>.generate(32, (_) => _casuale.nextInt(256));
      final token = base64UrlEncode(bytes).replaceAll('=', '');
      final impronta = _impronta(token);
      if (_sessioni.containsKey(impronta)) {
        continue;
      }

      _sessioni[impronta] = _LanSessioneRegistrata(
        utenteId: idUtente,
        username: identita.utente.username,
        ruoloId: idRuolo,
        nomeRuolo: identita.ruolo.nome,
        scadenzaUtc: scadenza,
      );
      return LanSessioneUtenteCreata(token: token, scadenzaUtc: scadenza);
    }

    throw StateError('Impossibile generare una sessione univoca.');
  }

  /// Valida scadenza, revoca e stato ATTUALE di utente e ruolo in SQLite.
  Future<LanIdentitaUtenteVerificata?> verificaSessione(String token) async {
    if (!_formatoToken.hasMatch(token)) {
      return null;
    }

    final impronta = _impronta(token);
    final sessione = _sessioni[impronta];
    if (sessione == null) {
      return null;
    }
    if (!_adessoUtc().isBefore(sessione.scadenzaUtc)) {
      _sessioni.remove(impronta);
      return null;
    }

    try {
      final righe = await _database.rawQuery(
        '''
        SELECT
          u.id AS utente_id,
          u.nome AS utente_nome,
          u.cognome AS utente_cognome,
          u.username AS utente_username,
          u.ruolo_id AS utente_ruolo_id,
          u.attivo AS utente_attivo,
          r.id AS ruolo_id,
          r.nome AS ruolo_nome,
          r.attivo AS ruolo_attivo
        FROM utenti_app u
        LEFT JOIN ruoli_utenti r ON r.id = u.ruolo_id
        WHERE u.id = ?
        LIMIT 1
      ''',
        [sessione.utenteId],
      );

      if (righe.isEmpty) {
        _sessioni.remove(impronta);
        return null;
      }

      final riga = righe.single;
      final utenteId = riga['utente_id'];
      final ruoloId = riga['ruolo_id'];
      final usernameAttuale = riga['utente_username'];
      final nomeRuoloAttuale = riga['ruolo_nome'];

      if (utenteId != sessione.utenteId ||
          riga['utente_attivo'] != 1 ||
          riga['ruolo_attivo'] != 1 ||
          riga['utente_ruolo_id'] != sessione.ruoloId ||
          ruoloId != sessione.ruoloId ||
          usernameAttuale != sessione.username ||
          nomeRuoloAttuale != sessione.nomeRuolo ||
          usernameAttuale is! String ||
          usernameAttuale.trim().isEmpty ||
          nomeRuoloAttuale is! String ||
          nomeRuoloAttuale.trim().isEmpty) {
        _sessioni.remove(impronta);
        return null;
      }

      // La revoca o la scadenza possono essere avvenute durante la query.
      if (!identical(_sessioni[impronta], sessione) ||
          !_adessoUtc().isBefore(sessione.scadenzaUtc)) {
        _sessioni.remove(impronta);
        return null;
      }

      return LanIdentitaUtenteVerificata(
        utente: UtenteApp(
          id: sessione.utenteId,
          nome: riga['utente_nome'] as String? ?? '',
          cognome: riga['utente_cognome'] as String? ?? '',
          username: usernameAttuale,
          ruoloId: sessione.ruoloId,
          attivo: 1,
        ),
        ruolo: RuoloUtente(
          id: sessione.ruoloId,
          nome: nomeRuoloAttuale,
          attivo: 1,
        ),
      );
    } on Exception {
      // In caso di indisponibilita' SQLite, mai conservare una sessione
      // che non e' stato possibile riconvalidare.
      _sessioni.remove(impronta);
      return null;
    }
  }

  /// Nessun privilegio nasce dal token: si applica la matrice dei permessi.
  Future<bool> puoEseguirePrenotazioni({
    required String token,
    required LanOperazionePrenotazioni operazione,
  }) async {
    final identita = await verificaSessione(token);
    return const LanPrenotazioniPermessiService().puoEseguire(
      utente: identita?.utente,
      ruolo: identita?.ruolo,
      operazione: operazione,
    );
  }

  bool revocaSessione(String token) {
    if (!_formatoToken.hasMatch(token)) {
      return false;
    }
    return _sessioni.remove(_impronta(token)) != null;
  }

  int revocaSessioniUtente(int utenteId) {
    if (utenteId <= 0) {
      return 0;
    }
    final prima = _sessioni.length;
    _sessioni.removeWhere((_, sessione) => sessione.utenteId == utenteId);
    return prima - _sessioni.length;
  }

  void revocaTutteLeSessioni() => _sessioni.clear();
}
