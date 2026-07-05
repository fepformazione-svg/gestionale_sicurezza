import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssistenteAiPage extends StatelessWidget {
  const AssistenteAiPage({super.key});

  static const String _promptPriorita = '''
Agisci come assistente operativo per un gestionale sicurezza sul lavoro.

Categoria:
Priorita operative.

Obiettivo:
aiutami a trasformare le informazioni disponibili in una lista ordinata di priorita giornaliere.

Regole:
- non inventare dati;
- non usare dati personali se non sono necessari;
- segnala informazioni mancanti o ambigue;
- separa urgenze, attivita importanti e attivita rinviabili;
- usa un tono pratico, sintetico e operativo;
- ricorda che la decisione finale resta al professionista.

Dati disponibili:
[INCOLLA QUI SOLO DATI NON SENSIBILI O ANONIMIZZATI]

Output richiesto:
1. Urgenze da gestire subito
2. Attivita importanti da pianificare
3. Attivita rinviabili
4. Rischi o anomalie da verificare
5. Prossime azioni consigliate
''';

  static const String _promptEmail = '''
Agisci come assistente per la redazione di email professionali in ambito sicurezza sul lavoro.

Categoria:
Email clienti.

Obiettivo:
prepara una bozza email chiara, professionale e pronta da revisionare.

Destinatario:
[CLIENTE / AZIENDA / CONSULENTE / DISCENTE / FORNITORE]

Contesto:
[DESCRIVI IL CONTESTO SENZA INSERIRE DATI SENSIBILI NON NECESSARI]

Messaggio da comunicare:
[INSERISCI I PUNTI PRINCIPALI]

Regole:
- tono professionale e cortese;
- testo breve e comprensibile;
- nessuna affermazione normativa non verificata;
- non promettere adempimenti, scadenze o responsabilita non indicate;
- lascia eventuali punti dubbi come nota da verificare;
- ricorda che il testo deve essere controllato prima dell'invio.

Output richiesto:
1. Oggetto email
2. Corpo email
3. Eventuali note da verificare prima dell'invio
''';

  static const String _promptDocumenti = '''
Agisci come supporto operativo per il controllo documentale di corsi, pratiche e adempimenti SSL.

Categoria:
Controllo documentale.

Obiettivo:
aiutami a capire se la documentazione indicata sembra completa o se mancano elementi da verificare.

Documenti o informazioni disponibili:
[ELENCO DOCUMENTI / DATI ANONIMIZZATI]

Tipo pratica:
[CORSO / DVR / SOPRALLUOGO / VISITA MEDICA / SCADENZA / ALTRO]

Regole:
- non dare per presenti documenti non indicati;
- evidenzia assenze, incongruenze o dubbi;
- separa controllo formale e controllo sostanziale;
- non formulare conclusioni legali definitive;
- ricorda che serve verifica professionale finale.

Output richiesto:
1. Documenti presenti
2. Documenti mancanti o dubbi
3. Controlli formali consigliati
4. Controlli sostanziali consigliati
5. Note operative finali
''';

  static const String _promptSopralluogoDvr = '''
Agisci come assistente per preparare un sopralluogo aziendale e raccogliere elementi utili al DVR.

Categoria:
Sopralluoghi / DVR.

Contesto aziendale:
[SETTORE / ATTIVITA / NUMERO INDICATIVO ADDETTI / MANSIONI / RISCHI NOTI]

Obiettivo:
prepara una checklist preliminare per sopralluogo e raccolta dati DVR.

Regole:
- non sostituire la valutazione del RSPP, del datore di lavoro o del consulente;
- segnala gli aspetti da verificare sul posto;
- non inventare obblighi specifici se mancano dati;
- distingui tra documenti, ambienti, attrezzature, mansioni e criticita;
- usa un formato pratico da portare in sopralluogo.

Output richiesto:
1. Documenti da richiedere
2. Aree e reparti da verificare
3. Attrezzature, impianti e sostanze da controllare
4. Mansioni e rischi da approfondire
5. Domande da fare al referente aziendale
6. Criticita tipiche da osservare
7. Azioni successive consigliate
''';

  static const String _promptScadenzeRinnovi = '''
Agisci come assistente operativo per la gestione di scadenze, rinnovi e adempimenti periodici in ambito SSL.

Categoria:
Scadenze e rinnovi.

Obiettivo:
aiutami a ordinare le scadenze indicate e a preparare un piano operativo di rinnovo.

Dati disponibili:
[INCOLLA QUI ELENCO SCADENZE ANONIMIZZATO: TIPO, STATO, DATA SCADENZA, GIORNI RESIDUI]

Regole:
- non inventare date o adempimenti non indicati;
- evidenzia prima le scadenze gia scadute;
- poi evidenzia quelle in scadenza ravvicinata;
- segnala dati mancanti o incoerenti;
- non sostituire il controllo professionale sulle periodicita normative;
- suggerisci azioni pratiche e verificabili.

Output richiesto:
1. Scadenze gia scadute
2. Scadenze in scadenza ravvicinata
3. Rinnovi da programmare
4. Dati mancanti o da controllare
5. Piano operativo consigliato
6. Messaggio sintetico da inviare al cliente, se utile
''';

  static const String _promptPrivacyGdpr = '''
Agisci come supporto operativo per una prima verifica privacy/GDPR collegata ad attivita di sicurezza sul lavoro.

Categoria:
Privacy / GDPR.

Obiettivo:
aiutami a individuare punti privacy da verificare prima di usare, archiviare o condividere dati.

Contesto:
[DESCRIVI IL TRATTAMENTO O IL DOCUMENTO SENZA INSERIRE DATI PERSONALI NON NECESSARI]

Dati coinvolti:
[ES. DATI ANAGRAFICI / ATTESTATI / VISITE MEDICHE / IDONEITA / FOTO / VIDEO / EMAIL / ALTRO]

Regole:
- non fornire pareri legali definitivi;
- evidenzia i dati personali e gli eventuali dati particolari;
- suggerisci cautele operative;
- ricorda di verificare informative, autorizzazioni, basi giuridiche e tempi di conservazione;
- segnala quando serve confronto con consulente privacy/DPO;
- non suggerire invio automatico di dati a strumenti esterni.

Output richiesto:
1. Dati personali o particolari coinvolti
2. Finalita del trattamento da chiarire
3. Cautele operative consigliate
4. Documenti privacy da verificare
5. Rischi da evitare
6. Note per verifica professionale finale
''';

  static Future<void> _copiaNegliAppunti(
    BuildContext context,
    String testo,
  ) async {
    await Clipboard.setData(ClipboardData(text: testo));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testo copiato negli appunti'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assistente AI-ready',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Area predisposta per usare l'intelligenza artificiale come supporto operativo, senza integrazione API e senza invio automatico di dati.",
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              const _AvvisoCard(),
              const SizedBox(height: 20),
              Text(
                'Prompt guidati per categorie operative',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final itemWidth = isWide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Priorita operative',
                          descrizione:
                              'Per ordinare urgenze, attivita importanti e azioni rinviabili della giornata.',
                          prompt: _promptPriorita,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptPriorita),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Email clienti',
                          descrizione:
                              'Per preparare comunicazioni professionali da controllare prima dell\'invio.',
                          prompt: _promptEmail,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptEmail),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Controllo documentale',
                          descrizione:
                              'Per verificare completezza, dubbi e controlli consigliati su pratiche e fascicoli.',
                          prompt: _promptDocumenti,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptDocumenti),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Sopralluoghi / DVR',
                          descrizione:
                              'Per preparare checklist operative prima di sopralluoghi e raccolte dati DVR.',
                          prompt: _promptSopralluogoDvr,
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            _promptSopralluogoDvr,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Scadenze e rinnovi',
                          descrizione:
                              'Per ordinare scadenze, rinnovi e azioni da programmare con il cliente.',
                          prompt: _promptScadenzeRinnovi,
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            _promptScadenzeRinnovi,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Privacy / GDPR',
                          descrizione:
                              'Per una prima verifica operativa su dati, cautele privacy e punti da controllare.',
                          prompt: _promptPrivacyGdpr,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptPrivacyGdpr),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Fonti ufficiali da verificare',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final itemWidth = isWide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _FonteCard(
                          titolo: 'Normattiva',
                          descrizione: 'Testi normativi vigenti.',
                          url: 'https://www.normattiva.it/',
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            'https://www.normattiva.it/',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FonteCard(
                          titolo: 'Gazzetta Ufficiale',
                          descrizione: 'Pubblicazione ufficiale degli atti.',
                          url: 'https://www.gazzettaufficiale.it/',
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            'https://www.gazzettaufficiale.it/',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FonteCard(
                          titolo: 'Ministero del Lavoro',
                          descrizione:
                              'Informazioni istituzionali su lavoro e sicurezza.',
                          url: 'https://www.lavoro.gov.it/',
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            'https://www.lavoro.gov.it/',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FonteCard(
                          titolo: 'Ispettorato Nazionale del Lavoro',
                          descrizione:
                              'Indicazioni, interpelli, provvedimenti e documentazione.',
                          url: 'https://www.ispettorato.gov.it/',
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            'https://www.ispettorato.gov.it/',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FonteCard(
                          titolo: 'Vigili del Fuoco',
                          descrizione:
                              'Prevenzione incendi, modulistica e riferimenti tecnici.',
                          url: 'https://www.vigilfuoco.it/',
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            'https://www.vigilfuoco.it/',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FonteCard(
                          titolo: 'Garante Privacy',
                          descrizione:
                              'Privacy, GDPR, videosorveglianza e trattamento dati.',
                          url: 'https://www.garanteprivacy.it/',
                          onCopy: () => _copiaNegliAppunti(
                            context,
                            'https://www.garanteprivacy.it/',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const _UsoOperativoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvvisoCard extends StatelessWidget {
  const _AvvisoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: theme.colorScheme.error, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Uso sicuro dell'assistente AI",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Questa pagina non usa API, non invia dati all'esterno e non elabora automaticamente informazioni del gestionale. I prompt sono solo strumenti copiabili. Prima di usare strumenti AI esterni, anonimizzare i dati e verificare sempre il risultato con fonti ufficiali e valutazione professionale.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.titolo,
    required this.descrizione,
    required this.prompt,
    required this.onCopy,
  });

  final String titolo;
  final String descrizione;
  final String prompt;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.article_outlined, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              titolo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(descrizione),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                prompt,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copia prompt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FonteCard extends StatelessWidget {
  const _FonteCard({
    required this.titolo,
    required this.descrizione,
    required this.url,
    required this.onCopy,
  });

  final String titolo;
  final String descrizione;
  final String url;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(descrizione),
                  const SizedBox(height: 8),
                  SelectableText(url, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copia link'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsoOperativoCard extends StatelessWidget {
  const _UsoOperativoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Procedura consigliata',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const _ProceduraRiga(
              numero: '1',
              testo: 'Scegli il prompt piu adatto alla situazione.',
            ),
            const _ProceduraRiga(
              numero: '2',
              testo: 'Copia il prompt negli appunti.',
            ),
            const _ProceduraRiga(
              numero: '3',
              testo:
                  'Incollalo in uno strumento AI esterno solo dopo aver rimosso o anonimizzato dati personali e sensibili.',
            ),
            const _ProceduraRiga(
              numero: '4',
              testo:
                  'Controlla la risposta con fonti ufficiali e con la tua valutazione professionale.',
            ),
            const _ProceduraRiga(
              numero: '5',
              testo:
                  'Usa il risultato come bozza o supporto, non come decisione automatica.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProceduraRiga extends StatelessWidget {
  const _ProceduraRiga({required this.numero, required this.testo});

  final String numero;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            child: Text(numero, style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(testo)),
        ],
      ),
    );
  }
}
