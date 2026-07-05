import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssistenteAiPage extends StatelessWidget {
  const AssistenteAiPage({super.key});

  static const String _promptPriorita = '''
Agisci come assistente operativo per un gestionale sicurezza sul lavoro.

Obiettivo:
aiutami a individuare le priorità operative della giornata.

Regole:
- non inventare dati;
- segnala eventuali informazioni mancanti;
- separa urgenze, attività importanti e attività rinviabili;
- usa un tono pratico e sintetico;
- ricorda che la decisione finale resta al professionista.

Dati disponibili:
[INCOLLA QUI SOLO DATI NON SENSIBILI O ANONIMIZZATI]

Output richiesto:
1. Priorità immediate
2. Attività da pianificare
3. Rischi o anomalie da verificare
4. Prossime azioni consigliate
''';

  static const String _promptEmail = '''
Agisci come assistente per la redazione di comunicazioni professionali in ambito sicurezza sul lavoro.

Obiettivo:
prepara una bozza email chiara e professionale.

Destinatario:
[CLIENTE / AZIENDA / CONSULENTE / DISCENTE]

Contesto:
[DESCRIVI IL CONTESTO SENZA INSERIRE DATI SENSIBILI NON NECESSARI]

Messaggio da comunicare:
[INSERISCI I PUNTI PRINCIPALI]

Regole:
- tono professionale;
- testo breve;
- nessuna affermazione normativa non verificata;
- inserisci una chiusura cortese;
- lascia eventuali punti dubbi come nota da verificare.

Output richiesto:
oggetto email + corpo email.
''';

  static const String _promptDocumenti = '''
Agisci come supporto operativo per il controllo documentale di corsi e pratiche SSL.

Obiettivo:
aiutami a controllare se la pratica sembra completa.

Documenti o informazioni disponibili:
[ELENCO DOCUMENTI / DATI ANONIMIZZATI]

Regole:
- non dare per presenti documenti non indicati;
- evidenzia assenze o dubbi;
- separa controllo formale e controllo sostanziale;
- ricorda che serve verifica professionale finale.

Output richiesto:
1. Documenti presenti
2. Documenti mancanti o dubbi
3. Controlli consigliati
4. Note operative
''';

  static const String _promptSopralluogo = '''
Agisci come assistente per preparare un sopralluogo in azienda.

Contesto aziendale:
[SETTORE / ATTIVITÀ / NUMERO INDICATIVO ADDETTI / RISCHI NOTI]

Obiettivo:
prepara una checklist preliminare per sopralluogo.

Regole:
- non sostituire la valutazione del RSPP o del consulente;
- segnala gli aspetti da verificare sul posto;
- non inventare obblighi specifici se mancano dati;
- usa un formato pratico.

Output richiesto:
1. Documenti da chiedere
2. Aree da verificare
3. Domande da fare al referente
4. Criticità tipiche da controllare
5. Azioni successive
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
                'Area predisposta per usare l’intelligenza artificiale come supporto operativo, senza integrazione API e senza invio automatico di dati.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              const _AvvisoCard(),
              const SizedBox(height: 20),
              Text(
                'Prompt guidati',
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
                          titolo: 'Priorità operative',
                          descrizione:
                              'Per trasformare scadenze, visite e pratiche in una lista ordinata di cose da fare.',
                          prompt: _promptPriorita,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptPriorita),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Bozza email cliente',
                          descrizione:
                              'Per preparare comunicazioni professionali da controllare prima dell’invio.',
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
                              'Per verificare se una pratica o un fascicolo sembrano completi.',
                          prompt: _promptDocumenti,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptDocumenti),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _PromptCard(
                          titolo: 'Preparazione sopralluogo',
                          descrizione:
                              'Per costruire una checklist preliminare prima di una visita in azienda.',
                          prompt: _promptSopralluogo,
                          onCopy: () =>
                              _copiaNegliAppunti(context, _promptSopralluogo),
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
                    'Uso sicuro dell’assistente AI',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Questa pagina non usa API, non invia dati all’esterno e non elabora automaticamente informazioni del gestionale. I prompt sono solo strumenti copiabili. Prima di usare strumenti AI esterni, anonimizzare i dati e verificare sempre il risultato con fonti ufficiali e valutazione professionale.',
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
              testo: 'Scegli il prompt più adatto alla situazione.',
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
