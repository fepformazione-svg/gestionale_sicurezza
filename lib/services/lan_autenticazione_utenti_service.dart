import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/ruolo_utente.dart';
import '../models/utente_app.dart';

/// Identita' verificata contro il database del server, senza password/hash.
class LanIdentitaUtenteVerificata {
  const LanIdentitaUtenteVerificata({
    required this.utente,
    required this.ruolo,
  });

  final UtenteApp utente;
  final RuoloUtente ruolo;
}

/// Verifica locale delle credenziali sul database SQLite fornito dal server.
///
/// Fase NET015C3B2A: NON crea sessioni, NON espone un endpoint HTTP, NON
/// modifica log_accessi e NON abilita scritture LAN. Il chiamante deve aprire
/// il database centrale con un percorso verificato, mai indicato dal client.
///
/// Compatibilita' temporanea con il formato password legacy salt:SHA256.
/// Prima di esporre un login via rete servono trasporto cifrato, protezione
/// dai tentativi ripetuti e migrazione a un hash password adattivo.
class LanAutenticazioneUtentiService {
  const LanAutenticazioneUtentiService(this._database);

  final Database _database;

  Future<LanIdentitaUtenteVerificata?> verificaCredenziali({
    required String username,
    required String password,
  }) async {
    final login = username.trim().toLowerCase();
    // Mantiene il comportamento di AuthService per gli account esistenti.
    final passwordInserita = password.trim();

    if (login.isEmpty || login.length > 160 || passwordInserita.isEmpty) {
      return null;
    }

    // JOIN singola: utente e ruolo provengono dalla stessa lettura SQLite.
    // Non si accettano in input ID, ruoli o nomi operatore dichiarati dal PC2.
    final righe = await _database.rawQuery(
      '''
      SELECT
        u.id AS utente_id,
        u.nome AS utente_nome,
        u.cognome AS utente_cognome,
        u.username AS utente_username,
        u.password_hash AS password_hash,
        u.ruolo_id AS utente_ruolo_id,
        u.attivo AS utente_attivo,
        r.id AS ruolo_id,
        r.nome AS ruolo_nome,
        r.attivo AS ruolo_attivo
      FROM utenti_app u
      LEFT JOIN ruoli_utenti r ON r.id = u.ruolo_id
      WHERE LOWER(u.username) = ?
      LIMIT 1
    ''',
      [login],
    );

    if (righe.isEmpty) {
      return null;
    }

    final riga = righe.single;
    final utenteId = riga['utente_id'];
    final ruoloUtenteId = riga['utente_ruolo_id'];
    final ruoloId = riga['ruolo_id'];
    final usernameVerificato = riga['utente_username'];
    final nomeRuolo = riga['ruolo_nome'];
    final hashSalvato = riga['password_hash'];

    if (utenteId is! int ||
        utenteId <= 0 ||
        ruoloUtenteId is! int ||
        ruoloId is! int ||
        ruoloId <= 0 ||
        ruoloUtenteId != ruoloId ||
        riga['utente_attivo'] != 1 ||
        riga['ruolo_attivo'] != 1 ||
        usernameVerificato is! String ||
        usernameVerificato.trim().isEmpty ||
        nomeRuolo is! String ||
        nomeRuolo.trim().isEmpty ||
        hashSalvato is! String ||
        !_verificaPasswordLegacy(passwordInserita, hashSalvato)) {
      return null;
    }

    return LanIdentitaUtenteVerificata(
      utente: UtenteApp(
        id: utenteId,
        nome: riga['utente_nome'] as String? ?? '',
        cognome: riga['utente_cognome'] as String? ?? '',
        username: usernameVerificato,
        ruoloId: ruoloId,
        attivo: 1,
        // passwordHash resta null: non propagare hash oltre questo servizio.
      ),
      ruolo: RuoloUtente(id: ruoloId, nome: nomeRuolo, attivo: 1),
    );
  }

  bool _verificaPasswordLegacy(String password, String hashSalvato) {
    final parti = hashSalvato.trim().split(':');
    if (parti.length != 2 || parti[0].isEmpty || parti[1].length != 64) {
      return false;
    }

    final digest = sha256.convert(utf8.encode('${parti[0]}:$password'));
    final atteso = digest.toString();
    final salvato = parti[1];

    // Confronto senza uscita anticipata per i digest di uguale lunghezza.
    var differenze = 0;
    for (var indice = 0; indice < atteso.length; indice++) {
      differenze |= atteso.codeUnitAt(indice) ^ salvato.codeUnitAt(indice);
    }
    return differenze == 0;
  }
}
