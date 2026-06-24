import 'package:flutter/material.dart';

import '../models/ruolo_utente.dart';
import '../models/utente_app.dart';
import '../services/app_database.dart';

class UtentiRuoliPage extends StatefulWidget {
  const UtentiRuoliPage({super.key});

  @override
  State<UtentiRuoliPage> createState() => _UtentiRuoliPageState();
}

class _UtentiRuoliPageState extends State<UtentiRuoliPage> {
  final TextEditingController ricercaController = TextEditingController();

  bool caricamento = true;
  bool soloAttivi = true;

  List<UtenteApp> utenti = [];
  List<RuoloUtente> ruoli = [];

  @override
  void initState() {
    super.initState();
    caricaDati();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    super.dispose();
  }

  Future<void> caricaDati() async {
    setState(() {
      caricamento = true;
    });

    final utentiCaricati = await AppDatabase.instance.getUtentiApp(
      soloAttivi: soloAttivi,
      ricerca: ricercaController.text,
    );

    final ruoliCaricati = await AppDatabase.instance.getRuoliUtenti(
      soloAttivi: false,
    );

    if (!mounted) return;

    setState(() {
      utenti = utentiCaricati;
      ruoli = ruoliCaricati;
      caricamento = false;
    });
  }

  String nomeRuolo(int? ruoloId) {
    if (ruoloId == null) {
      return '-';
    }

    final ruolo = ruoli.where((r) => r.id == ruoloId).toList();
    if (ruolo.isEmpty) {
      return '-';
    }

    return ruolo.first.nome;
  }

  Color coloreStato(bool attivo) {
    return attivo ? Colors.green.shade700 : Colors.grey.shade600;
  }

  Widget badgeStato(bool attivo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: attivo ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attivo ? Colors.green.shade300 : Colors.grey.shade400,
        ),
      ),
      child: Text(
        attivo ? 'ATTIVO' : 'NON ATTIVO',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: coloreStato(attivo),
        ),
      ),
    );
  }

  Widget sezioneRuoli() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ruoli disponibili',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'I ruoli definiscono il livello di accesso che sarà usato nelle prossime fasi del login.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (ruoli.isEmpty)
              const Text('Nessun ruolo presente.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ruoli.map((ruolo) {
                  return Chip(
                    label: Text(
                      ruolo.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    avatar: Icon(
                      ruolo.isAttivo ? Icons.verified_user : Icons.block,
                      size: 18,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget sezioneFiltri() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ricercaController,
                decoration: InputDecoration(
                  labelText: 'Cerca utente',
                  hintText: 'Nome, cognome, username o email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ricercaController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Azzera ricerca',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ricercaController.clear();
                            caricaDati();
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => caricaDati(),
              ),
            ),
            const SizedBox(width: 16),
            FilterChip(
              label: const Text('Solo attivi'),
              selected: soloAttivi,
              onSelected: (_) {
                setState(() {
                  soloAttivi = true;
                });
                caricaDati();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Tutti'),
              selected: !soloAttivi,
              onSelected: (_) {
                setState(() {
                  soloAttivi = false;
                });
                caricaDati();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget tabellaUtenti() {
    if (caricamento) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (utenti.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Nessun utente presente.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        elevation: 2,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                columns: const [
                  DataColumn(label: Text('Cognome')),
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Ruolo')),
                  DataColumn(label: Text('Ultimo accesso')),
                  DataColumn(label: Text('Stato')),
                ],
                rows: utenti.map((utente) {
                  return DataRow(
                    cells: [
                      DataCell(Text(utente.cognome)),
                      DataCell(Text(utente.nome)),
                      DataCell(Text(utente.username)),
                      DataCell(Text(utente.email ?? '-')),
                      DataCell(Text(nomeRuolo(utente.ruoloId))),
                      DataCell(Text(utente.ultimoAccesso ?? '-')),
                      DataCell(badgeStato(utente.isAttivo)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totale = utenti.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utenti e Ruoli'),
        actions: [
          IconButton(
            tooltip: 'Ricarica',
            icon: const Icon(Icons.refresh),
            onPressed: caricaDati,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blueGrey.shade50,
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.manage_accounts, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Area preparatoria per la gestione utenti, ruoli, accessi e tracciamento operazioni. '
                        'In questa fase il login non è ancora obbligatorio.',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            sezioneRuoli(),
            const SizedBox(height: 12),
            sezioneFiltri(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                soloAttivi
                    ? '$totale utenti attivi'
                    : '$totale utenti presenti',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            tabellaUtenti(),
          ],
        ),
      ),
    );
  }
}
