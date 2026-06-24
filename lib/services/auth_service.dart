import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/utente_app.dart';
import 'app_database.dart';

enum EsitoLoginUtente {
  riuscito,
  usernameVuoto,
  passwordVuota,
  utenteNonTrovato,
  utenteNonAttivo,
  passwordNonImpostata,
  passwordErrata,
  errore,
}

class RisultatoLoginUtente {
  final bool ok;
  final EsitoLoginUtente esito;
  final UtenteApp? utente;
  final String messaggio;

  const RisultatoLoginUtente({
    required this.ok,
    required this.esito,
    this.utente,
    required this.messaggio,
  });
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  Future<RisultatoLoginUtente> verificaCredenziali({
    required String username,
    required String password,
    String? dispositivo,
  }) async {
    final usernameNormalizzato = username.trim();
    final passwordInserita = password.trim();

    if (usernameNormalizzato.isEmpty) {
      return const RisultatoLoginUtente(
        ok: false,
        esito: EsitoLoginUtente.usernameVuoto,
        messaggio: 'Username obbligatorio.',
      );
    }

    if (passwordInserita.isEmpty) {
      await _registraTentativo(
        username: usernameNormalizzato,
        esito: 'KO',
        messaggio: 'Password vuota.',
        dispositivo: dispositivo,
      );

      return const RisultatoLoginUtente(
        ok: false,
        esito: EsitoLoginUtente.passwordVuota,
        messaggio: 'Password obbligatoria.',
      );
    }

    try {
      final utente = await AppDatabase.instance.getUtenteAppByUsername(
        usernameNormalizzato,
      );

      if (utente == null) {
        await _registraTentativo(
          username: usernameNormalizzato,
          esito: 'KO',
          messaggio: 'Utente non trovato.',
          dispositivo: dispositivo,
        );

        return const RisultatoLoginUtente(
          ok: false,
          esito: EsitoLoginUtente.utenteNonTrovato,
          messaggio: 'Username o password non corretti.',
        );
      }

      if (utente.attivo != 1) {
        await _registraTentativo(
          utenteId: utente.id,
          username: utente.username,
          esito: 'KO',
          messaggio: 'Utente non attivo.',
          dispositivo: dispositivo,
        );

        return const RisultatoLoginUtente(
          ok: false,
          esito: EsitoLoginUtente.utenteNonAttivo,
          messaggio: 'Utente non attivo.',
        );
      }

      final passwordHash = utente.passwordHash?.trim() ?? '';
      if (passwordHash.isEmpty) {
        await _registraTentativo(
          utenteId: utente.id,
          username: utente.username,
          esito: 'KO',
          messaggio: 'Password non impostata.',
          dispositivo: dispositivo,
        );

        return const RisultatoLoginUtente(
          ok: false,
          esito: EsitoLoginUtente.passwordNonImpostata,
          messaggio: 'Password non impostata per questo utente.',
        );
      }

      final passwordCorretta = verificaPassword(
        password: passwordInserita,
        passwordHashSalvato: passwordHash,
      );

      if (!passwordCorretta) {
        await _registraTentativo(
          utenteId: utente.id,
          username: utente.username,
          esito: 'KO',
          messaggio: 'Password errata.',
          dispositivo: dispositivo,
        );

        return const RisultatoLoginUtente(
          ok: false,
          esito: EsitoLoginUtente.passwordErrata,
          messaggio: 'Username o password non corretti.',
        );
      }

      if (utente.id != null) {
        await AppDatabase.instance.aggiornaUltimoAccessoUtenteApp(utente.id!);
      }

      await _registraTentativo(
        utenteId: utente.id,
        username: utente.username,
        esito: 'OK',
        messaggio: 'Accesso riuscito.',
        dispositivo: dispositivo,
      );

      return RisultatoLoginUtente(
        ok: true,
        esito: EsitoLoginUtente.riuscito,
        utente: utente,
        messaggio: 'Accesso riuscito.',
      );
    } catch (e) {
      await _registraTentativo(
        username: usernameNormalizzato,
        esito: 'ERRORE',
        messaggio: e.toString(),
        dispositivo: dispositivo,
      );

      return RisultatoLoginUtente(
        ok: false,
        esito: EsitoLoginUtente.errore,
        messaggio: 'Errore durante la verifica credenziali: $e',
      );
    }
  }

  bool verificaPassword({
    required String password,
    required String passwordHashSalvato,
  }) {
    final parti = passwordHashSalvato.split(':');
    if (parti.length != 2) {
      return false;
    }

    final salt = parti[0];
    final digestSalvato = parti[1];

    if (salt.isEmpty || digestSalvato.isEmpty) {
      return false;
    }

    final bytes = utf8.encode('$salt:$password');
    final digestCalcolato = sha256.convert(bytes).toString();

    return digestCalcolato == digestSalvato;
  }

  Future<void> _registraTentativo({
    int? utenteId,
    String? username,
    required String esito,
    String? messaggio,
    String? dispositivo,
  }) async {
    try {
      await AppDatabase.instance.registraLogAccesso(
        utenteId: utenteId,
        username: username,
        esito: esito,
        messaggio: messaggio,
        dispositivo: dispositivo,
      );
    } catch (_) {
      // Il log accessi non deve mai bloccare la verifica credenziali.
    }
  }
}
