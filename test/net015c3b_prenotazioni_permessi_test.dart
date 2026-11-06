import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_sicurezza/models/ruolo_utente.dart';
import 'package:gestionale_sicurezza/models/utente_app.dart';
import 'package:gestionale_sicurezza/services/lan_prenotazioni_permessi_service.dart';

const _permessi = LanPrenotazioniPermessiService();

UtenteApp _utente({
  int? id = 10,
  int? ruoloId = 1,
  int attivo = 1,
  String username = 'utente-test',
}) => UtenteApp(
  id: id,
  nome: 'Utente',
  cognome: 'Prova',
  username: username,
  ruoloId: ruoloId,
  attivo: attivo,
);

RuoloUtente _ruolo({
  int? id = 1,
  String nome = 'Amministratore',
  int attivo = 1,
}) => RuoloUtente(id: id, nome: nome, attivo: attivo);

void main() {
  test('NET015C3B amministratore puo eseguire tutte le operazioni', () {
    for (final operazione in LanOperazionePrenotazioni.values) {
      expect(
        _permessi.puoEseguire(
          utente: _utente(),
          ruolo: _ruolo(),
          operazione: operazione,
        ),
        isTrue,
        reason: 'Operazione: $operazione',
      );
    }
  });

  test('NET015C3B operatore puo lavorare ma non eliminare', () {
    for (final operazione in LanOperazionePrenotazioni.values) {
      expect(
        _permessi.puoEseguire(
          utente: _utente(ruoloId: 2),
          ruolo: _ruolo(id: 2, nome: 'Operatore'),
          operazione: operazione,
        ),
        operazione != LanOperazionePrenotazioni.eliminare,
        reason: 'Operazione: $operazione',
      );
    }
  });

  test('NET015C3B solo lettura puo soltanto consultare', () {
    for (final operazione in LanOperazionePrenotazioni.values) {
      expect(
        _permessi.puoEseguire(
          utente: _utente(ruoloId: 3),
          ruolo: _ruolo(id: 3, nome: 'Solo lettura'),
          operazione: operazione,
        ),
        operazione == LanOperazionePrenotazioni.consultare,
        reason: 'Operazione: $operazione',
      );
    }
  });

  test('NET015C3B account o ruolo disattivato nega anche consultazione', () {
    for (final caso in [
      (utente: _utente(attivo: 0), ruolo: _ruolo()),
      (utente: _utente(), ruolo: _ruolo(attivo: 0)),
    ]) {
      for (final operazione in LanOperazionePrenotazioni.values) {
        expect(
          _permessi.puoEseguire(
            utente: caso.utente,
            ruolo: caso.ruolo,
            operazione: operazione,
          ),
          isFalse,
        );
      }
    }
  });

  test('NET015C3B identita e ruolo incoerenti sono sempre negati', () {
    for (final caso in [
      (utente: null, ruolo: _ruolo()),
      (utente: _utente(), ruolo: null),
      (utente: _utente(id: null), ruolo: _ruolo()),
      (utente: _utente(id: 0), ruolo: _ruolo()),
      (utente: _utente(ruoloId: null), ruolo: _ruolo()),
      (utente: _utente(ruoloId: 2), ruolo: _ruolo()),
      (utente: _utente(), ruolo: _ruolo(id: 0)),
      (utente: _utente(username: '  '), ruolo: _ruolo()),
      (utente: _utente(), ruolo: _ruolo(nome: 'Ruolo sconosciuto')),
    ]) {
      for (final operazione in LanOperazionePrenotazioni.values) {
        expect(
          _permessi.puoEseguire(
            utente: caso.utente,
            ruolo: caso.ruolo,
            operazione: operazione,
          ),
          isFalse,
        );
      }
    }
  });

  test('NET015C3B mantiene gli alias amministratore gia in uso', () {
    for (final nome in ['Amministratore', 'Admin', 'Administrator']) {
      expect(
        _permessi.puoEseguire(
          utente: _utente(),
          ruolo: _ruolo(nome: nome),
          operazione: LanOperazionePrenotazioni.eliminare,
        ),
        isTrue,
      );
    }
  });
}
