import 'package:gestionale_sicurezza/services/lan_readonly_database_service.dart';

const filtriPrenotazioniLan = <String>[
  'tutte',
  'aperte',
  'registro',
  'chiuse',
  'da_fare',
  'senza_discente',
  'aziendali_senza_discente',
  'senza_docente',
  'recenti_da_sistemare',
];

/// Restituisce una pagina e tutti i conteggi, usando solo SQLite read-only.
///
/// Il risultato non include percorsi dei modelli Word o altri file locali.
Future<Map<String, dynamic>> loadLanPrenotazioniReadOnly(
  String databasePath, {
  required int limit,
  required int offset,
  String ricerca = '',
  String filtro = 'tutte',
}) async {
  if (limit < 1 || limit > 100) {
    throw ArgumentError.value(limit, 'limit', 'Valore ammesso: 1-100.');
  }
  if (offset < 0) {
    throw ArgumentError.value(offset, 'offset', 'Non puo essere negativo.');
  }
  if (!filtriPrenotazioniLan.contains(filtro)) {
    throw ArgumentError.value(filtro, 'filtro', 'Filtro non riconosciuto.');
  }

  final ricercaPulita = ricerca.trim();
  if (ricercaPulita.length > 160) {
    throw ArgumentError.value(
      ricercaPulita.length,
      'ricerca',
      'Ricerca troppo lunga.',
    );
  }

  final database = await openLanReadOnlyDatabase(databasePath);
  try {
    final conteggi = <String, int>{};
    for (final filtroConteggio in filtriPrenotazioniLan) {
      final countArgs = <Object?>[];
      final whereSql = _wherePrenotazioniSql(
        ricerca: ricercaPulita,
        filtro: filtroConteggio,
        args: countArgs,
      );
      final countRows = await database.rawQuery('''
        SELECT COUNT(*) AS totale
        FROM prenotazioni p
        LEFT JOIN discenti d ON d.id = p.discente_id
        LEFT JOIN imprese i ON i.id = p.impresa_id
        LEFT JOIN corsi c ON c.id = p.corso_id
        LEFT JOIN docenti doc ON doc.id = p.docente_id
        $whereSql
      ''', countArgs);
      conteggi[filtroConteggio] =
          (countRows.first['totale'] as num?)?.toInt() ?? 0;
    }

    final args = <Object?>[];
    final whereSql = _wherePrenotazioniSql(
      ricerca: ricercaPulita,
      filtro: filtro,
      args: args,
    );
    final rows = await database.rawQuery(
      '''
      SELECT
        p.id,
        p.discente_id,
        p.impresa_id,
        p.corso_id,
        p.data,
        p.prot,
        p.aperto,
        p.conferma,
        p.ok,
        p.registro,
        p.seleziona,
        p.docente_id,
        p.aula_sede_id,
        p.ente_attestato_id,
        CASE
          WHEN p.discente_id IS NULL
            AND p.impresa_id IS NOT NULL
            AND p.corso_id IS NOT NULL THEN 'AZIENDALE / SENZA DISCENTE'
          WHEN p.discente_id IS NULL THEN 'PRENOTAZIONE NON CLASSIFICATA'
          WHEN d.id IS NULL THEN 'DISCENTE NON TROVATO'
          ELSE COALESCE(d.nome, '')
        END AS discente_nome,
        COALESCE(d.cognome, '') AS discente_cognome,
        i.intestazione AS impresa_nome,
        c.denominazione AS corso_nome,
        doc.nome AS docente_nome,
        doc.cognome AS docente_cognome,
        doc.qualifica AS docente_qualifica,
        aula.codice AS aula_sede_codice,
        aula.denominazione AS aula_sede_denominazione,
        aula.comune AS aula_sede_comune,
        ente.denominazione AS ente_attestato_denominazione,
        ente.tipo AS ente_attestato_tipo,
        (
          SELECT GROUP_CONCAT(
            a.denominazione ||
            ' x' ||
            CASE
              WHEN COALESCE(pa.quantita, 1) = CAST(COALESCE(pa.quantita, 1) AS INTEGER)
              THEN CAST(COALESCE(pa.quantita, 1) AS INTEGER)
              ELSE COALESCE(pa.quantita, 1)
            END ||
            CASE
              WHEN pa.note IS NOT NULL AND TRIM(pa.note) <> ''
              THEN ' - ' || pa.note
              ELSE ''
            END,
            ', '
          )
          FROM prenotazioni_attrezzature pa
          INNER JOIN attrezzature a ON a.id = pa.attrezzatura_id
          WHERE pa.prenotazione_id = p.id
        ) AS attrezzature_sintesi
      FROM prenotazioni p
      LEFT JOIN discenti d ON d.id = p.discente_id
      LEFT JOIN imprese i ON i.id = p.impresa_id
      LEFT JOIN corsi c ON c.id = p.corso_id
      LEFT JOIN docenti doc ON doc.id = p.docente_id
      LEFT JOIN aule_sedi aula ON aula.id = p.aula_sede_id
      LEFT JOIN enti_attestati ente ON ente.id = p.ente_attestato_id
      $whereSql
      ORDER BY p.id DESC
      LIMIT ? OFFSET ?
    ''',
      <Object?>[...args, limit, offset],
    );

    return <String, dynamic>{
      'items': rows.map(Map<String, dynamic>.from).toList(growable: false),
      'conteggi': conteggi,
    };
  } finally {
    await database.close();
  }
}

String _wherePrenotazioniSql({
  required String ricerca,
  required String filtro,
  required List<Object?> args,
}) {
  final condizioni = <String>[];

  switch (filtro) {
    case 'registro':
      condizioni.add('COALESCE(p.registro, 0) = 1');
      break;
    case 'chiuse':
      condizioni.add('''
        COALESCE(p.registro, 0) = 0
        AND COALESCE(p.conferma, 0) = 1
      ''');
      break;
    case 'aperte':
      condizioni.add('''
        COALESCE(p.registro, 0) = 0
        AND COALESCE(p.conferma, 0) = 0
        AND COALESCE(p.aperto, 0) = 1
      ''');
      break;
    case 'da_fare':
      condizioni.add('''
        COALESCE(p.registro, 0) = 0
        AND COALESCE(p.conferma, 0) = 0
        AND COALESCE(p.aperto, 0) = 0
      ''');
      break;
    case 'senza_discente':
      condizioni.add('''
        (p.discente_id IS NULL OR d.id IS NULL)
      ''');
      break;
    case 'aziendali_senza_discente':
      condizioni.add('''
        p.discente_id IS NULL
        AND p.impresa_id IS NOT NULL
        AND p.corso_id IS NOT NULL
      ''');
      break;
    case 'senza_docente':
      condizioni.add('''
        (p.docente_id IS NULL OR (p.docente_id IS NOT NULL AND doc.id IS NULL))
      ''');
      break;
    case 'recenti_da_sistemare':
      condizioni.add('''
        p.id IN (
          SELECT pr.id
          FROM prenotazioni pr
          ORDER BY pr.id DESC
          LIMIT 250
        )
        AND (
          p.discente_id IS NULL
          OR d.id IS NULL
          OR p.docente_id IS NULL
          OR (p.docente_id IS NOT NULL AND doc.id IS NULL)
        )
      ''');
      break;
    case 'tutte':
      break;
  }

  final query = ricerca.trim().toLowerCase();
  if (query.isNotEmpty) {
    final like = '%$query%';
    condizioni.add('''
      (
        LOWER(
          CASE
            WHEN p.discente_id IS NULL
              AND p.impresa_id IS NOT NULL
              AND p.corso_id IS NOT NULL THEN 'AZIENDALE / SENZA DISCENTE'
            WHEN p.discente_id IS NULL THEN 'PRENOTAZIONE NON CLASSIFICATA'
            WHEN d.id IS NULL THEN 'DISCENTE NON TROVATO'
            ELSE COALESCE(d.nome, '')
          END
        ) LIKE ?
        OR LOWER(COALESCE(d.cognome, '')) LIKE ?
        OR LOWER(TRIM(COALESCE(d.cognome, '') || ' ' || COALESCE(d.nome, ''))) LIKE ?
        OR LOWER(TRIM(COALESCE(d.nome, '') || ' ' || COALESCE(d.cognome, ''))) LIKE ?
        OR LOWER(COALESCE(i.intestazione, '')) LIKE ?
        OR LOWER(COALESCE(c.denominazione, '')) LIKE ?
        OR LOWER(COALESCE(p.data, '')) LIKE ?
        OR LOWER(COALESCE(p.prot, '')) LIKE ?
        OR LOWER(
          CASE
            WHEN COALESCE(p.registro, 0) = 1 THEN 'registro'
            WHEN COALESCE(p.conferma, 0) = 1 THEN 'chiuso'
            WHEN COALESCE(p.aperto, 0) = 1 THEN 'aperto'
            ELSE 'da fare'
          END
        ) LIKE ?
      )
    ''');
    args.addAll(List<Object?>.filled(9, like));
  }

  return condizioni.isEmpty ? '' : 'WHERE ${condizioni.join(' AND ')}';
}
