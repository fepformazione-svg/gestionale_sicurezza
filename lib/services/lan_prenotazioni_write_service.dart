import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Motore di scrittura LAN non collegato al server operativo.
///
/// NET015C1 lo prova esclusivamente con database temporanei creati nei test.
/// Il collegamento al server richiedera' una fase separata di autenticazione,
/// autorizzazione, migrazione e verifica del percorso del database.
class LanPrenotazioniWriteService {
  LanPrenotazioniWriteService(this._database);

  final Database _database;

  static const _campiAmmessi = <String>{
    'discente_id',
    'impresa_id',
    'corso_id',
    'docente_id',
    'aula_sede_id',
    'ente_attestato_id',
    'data',
    'prot',
    'aperto',
    'conferma',
    'registro',
  };

  static const _riferimenti = <String, String>{
    'discente_id': 'discenti',
    'impresa_id': 'imprese',
    'corso_id': 'corsi',
    'docente_id': 'docenti',
    'aula_sede_id': 'aule_sedi',
    'ente_attestato_id': 'enti_attestati',
  };

  /// Inserisce una prenotazione NON confermata e il relativo audit atomico.
  ///
  /// Il chiamante dovra' fornire un'identita' gia' autenticata: il parametro
  /// [operatore] non costituisce di per se' un controllo di autenticazione.
  Future<int> inserisciPrenotazione({
    required Map<String, dynamic> dati,
    required String operatore,
  }) async {
    final nomeOperatore = operatore.trim();
    if (nomeOperatore.isEmpty || nomeOperatore.length > 80) {
      throw ArgumentError.value(
        operatore,
        'operatore',
        'Operatore non valido.',
      );
    }

    for (final campo in dati.keys) {
      if (!_campiAmmessi.contains(campo)) {
        throw ArgumentError.value(campo, 'dati', 'Campo non consentito.');
      }
    }

    for (final campo in _riferimenti.keys) {
      final valore = dati[campo];
      if (valore != null && (valore is! int || valore <= 0)) {
        throw ArgumentError.value(valore, campo, 'ID non valido.');
      }
    }

    if (dati['discente_id'] == null && dati['impresa_id'] == null) {
      throw ArgumentError('Discente o impresa obbligatori.');
    }
    if (dati['corso_id'] == null) {
      throw ArgumentError('Corso obbligatorio.');
    }

    final data = dati['data'];
    if (data is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data) ||
        DateTime.tryParse(data) == null) {
      throw ArgumentError.value(data, 'data', 'Data non valida.');
    }

    final protocollo = dati['prot'];
    if (protocollo != null &&
        (protocollo is! String || protocollo.length > 100)) {
      throw ArgumentError.value(protocollo, 'prot', 'Protocollo non valido.');
    }

    for (final campo in ['aperto', 'registro']) {
      final valore = dati[campo];
      if (valore != null && valore != 0 && valore != 1) {
        throw ArgumentError.value(valore, campo, 'Valore ammesso: 0 o 1.');
      }
    }

    // La conferma modifica anche Diario e Scadenze: sara' gestita in una
    // successiva fase NET015C con un'unica transazione complessiva.
    if (dati['conferma'] != null && dati['conferma'] != 0) {
      throw ArgumentError('Conferma non ancora abilitata in NET015C1.');
    }

    return _database.transaction((txn) async {
      for (final riferimento in _riferimenti.entries) {
        final id = dati[riferimento.key];
        if (id == null) continue;

        final righe = await txn.query(
          riferimento.value,
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (righe.isEmpty) {
          throw ArgumentError.value(
            id,
            riferimento.key,
            'Collegamento inesistente.',
          );
        }
      }

      final adesso = DateTime.now().toUtc().toIso8601String();
      final id = await txn.insert('prenotazioni', {
        for (final campo in _riferimenti.keys) campo: dati[campo],
        'data': data,
        'prot': (protocollo as String?)?.trim(),
        'aperto': dati['aperto'] ?? 1,
        'conferma': 0,
        'registro': dati['registro'] ?? 0,
        'updated_at': adesso,
      });

      // Se il registro audit manca o fallisce, SQLite annulla anche l'INSERT.
      await txn.insert('lan_prenotazioni_audit', {
        'prenotazione_id': id,
        'operazione': 'INSERT',
        'operatore': nomeOperatore,
        'timestamp_utc': adesso,
      });

      return id;
    });
  }
}
