import 'package:flutter/material.dart';

import '../models/registro_trattamento.dart';
import '../services/app_database.dart';

class RegistroTrattamentiPage extends StatefulWidget {
  const RegistroTrattamentiPage({super.key});

  @override
  State<RegistroTrattamentiPage> createState() =>
      _RegistroTrattamentiPageState();
}

class _RegistroTrattamentiPageState extends State<RegistroTrattamentiPage> {
  bool caricamento = true;
  String? errore;
  List<RegistroTrattamento> trattamenti = [];

  String filtroStato = 'tutti';

  List<RegistroTrattamento> get trattamentiFiltrati {
    if (filtroStato == 'attivi') {
      return trattamenti.where((trattamento) => trattamento.attivo).toList();
    }

    if (filtroStato == 'non_attivi') {
      return trattamenti.where((trattamento) => !trattamento.attivo).toList();
    }

    return trattamenti;
  }

  @override
  void initState() {
    super.initState();
    caricaTrattamenti();
  }

  Future<void> caricaTrattamenti() async {
    setState(() {
      caricamento = true;
      errore = null;
    });

    try {
      final dati = await AppDatabase.instance.getRegistroTrattamenti();

      if (!mounted) return;

      setState(() {
        trattamenti = dati;
        caricamento = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errore = e.toString();
        caricamento = false;
      });
    }
  }

  Future<void> cambiaStatoTrattamento(RegistroTrattamento trattamento) async {
    final nuovoStatoAttivo = !trattamento.attivo;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            nuovoStatoAttivo
                ? 'Riattivare trattamento?'
                : 'Disattivare trattamento?',
          ),
          content: Text(
            nuovoStatoAttivo
                ? 'Il trattamento tornerà attivo nel Registro trattamenti.'
                : 'Il trattamento non verrà cancellato, ma sarà segnato come non attivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(nuovoStatoAttivo ? 'Riattiva' : 'Disattiva'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    final trattamentoAggiornato = RegistroTrattamento(
      id: trattamento.id,
      nomeTrattamento: trattamento.nomeTrattamento,
      finalita: trattamento.finalita,
      categorieInteressati: trattamento.categorieInteressati,
      categorieDati: trattamento.categorieDati,
      baseGiuridica: trattamento.baseGiuridica,
      destinatari: trattamento.destinatari,
      trasferimentoExtraUe: trattamento.trasferimentoExtraUe,
      tempiConservazione: trattamento.tempiConservazione,
      misureSicurezza: trattamento.misureSicurezza,
      responsabileInterno: trattamento.responsabileInterno,
      note: trattamento.note,
      attivo: nuovoStatoAttivo,
      createdAt: trattamento.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await AppDatabase.instance.updateRegistroTrattamento(trattamentoAggiornato);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuovoStatoAttivo
              ? 'Trattamento riattivato correttamente.'
              : 'Trattamento disattivato correttamente.',
        ),
      ),
    );

    await caricaTrattamenti();
  }

  Widget _buildStatoVuoto() {
    return const Center(
      child: Text(
        'Nessun trattamento registrato.\n'
        'Il registro è collegato al database, ma non contiene ancora dati.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildErrore() {
    return Center(
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Errore durante il caricamento del registro trattamenti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(errore ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: caricaTrattamenti,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabella() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Trattamento')),
              DataColumn(label: Text('Finalità')),
              DataColumn(label: Text('Base giuridica')),
              DataColumn(label: Text('Categorie dati')),
              DataColumn(label: Text('Conservazione')),
              DataColumn(label: Text('Stato')),
              DataColumn(label: Text('Azioni')),
            ],
            rows: trattamentiFiltrati.map((trattamento) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(trattamento.nomeTrattamento),
                    ),
                  ),
                  DataCell(
                    SizedBox(width: 260, child: Text(trattamento.finalita)),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(trattamento.baseGiuridica),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(trattamento.categorieDati),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(trattamento.tempiConservazione),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(trattamento.attivo ? 'Attivo' : 'Non attivo'),
                      backgroundColor: trattamento.attivo
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Modifica trattamento',
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              mostraDialogTrattamento(trattamento: trattamento),
                        ),
                        IconButton(
                          tooltip: trattamento.attivo
                              ? 'Disattiva trattamento'
                              : 'Riattiva trattamento',
                          icon: Icon(
                            trattamento.attivo
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          color: trattamento.attivo
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          onPressed: () => cambiaStatoTrattamento(trattamento),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildContenuto() {
    if (caricamento) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errore != null) {
      return _buildErrore();
    }

    if (trattamenti.isEmpty) {
      return _buildStatoVuoto();
    }

    return _buildTabella();
  }

  Future<void> mostraDialogTrattamento({
    RegistroTrattamento? trattamento,
  }) async {
    final isModifica = trattamento != null;

    final risultato = await showDialog<_NuovoTrattamentoDialogResult>(
      context: context,
      builder: (dialogContext) {
        return _NuovoTrattamentoDialog(trattamento: trattamento);
      },
    );

    if (risultato == null) {
      return;
    }

    try {
      final trattamentoDaSalvare = RegistroTrattamento(
        id: trattamento?.id,
        nomeTrattamento: risultato.nome,
        finalita: risultato.finalita,
        baseGiuridica: risultato.baseGiuridica,
        categorieDati: risultato.categorieDati,
        categorieInteressati: risultato.categorieInteressati,
        destinatari: risultato.destinatari,
        trasferimentoExtraUe: trattamento?.trasferimentoExtraUe ?? '',
        tempiConservazione: risultato.conservazione,
        misureSicurezza: risultato.misureSicurezza,
        responsabileInterno: trattamento?.responsabileInterno ?? '',
        note: risultato.note,
        attivo: trattamento?.attivo ?? true,
        createdAt: trattamento?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      if (isModifica) {
        await AppDatabase.instance.updateRegistroTrattamento(
          trattamentoDaSalvare,
        );
      } else {
        await AppDatabase.instance.insertRegistroTrattamento(
          trattamentoDaSalvare,
        );
      }

      if (!mounted) {
        return;
      }

      await caricaTrattamenti();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isModifica
                ? 'Trattamento "${risultato.nome}" modificato.'
                : 'Trattamento "${risultato.nome}" salvato nel registro.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            isModifica
                ? 'Errore durante la modifica del trattamento: $e'
                : 'Errore durante il salvataggio del trattamento: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro trattamenti'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: caricamento ? null : caricaTrattamenti,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Trattamenti registrati: ${trattamenti.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text(
                  'Filtro stato:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Tutti'),
                  selected: filtroStato == 'tutti',
                  onSelected: (_) {
                    setState(() {
                      filtroStato = 'tutti';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Attivi'),
                  selected: filtroStato == 'attivi',
                  onSelected: (_) {
                    setState(() {
                      filtroStato = 'attivi';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Non attivi'),
                  selected: filtroStato == 'non_attivi',
                  onSelected: (_) {
                    setState(() {
                      filtroStato = 'non_attivi';
                    });
                  },
                ),
                const Spacer(),
                Text(
                  'Visibili: ${trattamentiFiltrati.length} / ${trattamenti.length}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Expanded(child: _buildContenuto()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostraDialogTrattamento(),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo trattamento'),
      ),
    );
  }
}

class _NuovoTrattamentoDialogResult {
  const _NuovoTrattamentoDialogResult({
    required this.nome,
    required this.finalita,
    required this.baseGiuridica,
    required this.categorieInteressati,
    required this.categorieDati,
    required this.destinatari,
    required this.conservazione,
    required this.misureSicurezza,
    required this.note,
  });

  final String nome;
  final String finalita;
  final String baseGiuridica;
  final String categorieInteressati;
  final String categorieDati;
  final String destinatari;
  final String conservazione;
  final String misureSicurezza;
  final String note;
}

class _NuovoTrattamentoDialog extends StatefulWidget {
  const _NuovoTrattamentoDialog({this.trattamento});

  final RegistroTrattamento? trattamento;

  @override
  State<_NuovoTrattamentoDialog> createState() =>
      _NuovoTrattamentoDialogState();
}

class _NuovoTrattamentoDialogState extends State<_NuovoTrattamentoDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _finalitaController = TextEditingController();
  final TextEditingController _baseGiuridicaController =
      TextEditingController();
  final TextEditingController _categorieInteressatiController =
      TextEditingController();
  final TextEditingController _categorieDatiController =
      TextEditingController();
  final TextEditingController _destinatariController = TextEditingController();
  final TextEditingController _conservazioneController =
      TextEditingController();
  final TextEditingController _misureSicurezzaController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _erroreNome;
  String? _erroreFinalita;

  @override
  void initState() {
    super.initState();

    final trattamento = widget.trattamento;
    if (trattamento == null) {
      return;
    }

    _nomeController.text = trattamento.nomeTrattamento;
    _finalitaController.text = trattamento.finalita;
    _baseGiuridicaController.text = trattamento.baseGiuridica;
    _categorieInteressatiController.text = trattamento.categorieInteressati;
    _categorieDatiController.text = trattamento.categorieDati;
    _destinatariController.text = trattamento.destinatari;
    _conservazioneController.text = trattamento.tempiConservazione;
    _misureSicurezzaController.text = trattamento.misureSicurezza;
    _noteController.text = trattamento.note;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _finalitaController.dispose();
    _baseGiuridicaController.dispose();
    _categorieInteressatiController.dispose();
    _categorieDatiController.dispose();
    _destinatariController.dispose();
    _conservazioneController.dispose();
    _misureSicurezzaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _salva() {
    final nomeVuoto = _nomeController.text.trim().isEmpty;
    final finalitaVuota = _finalitaController.text.trim().isEmpty;

    setState(() {
      _erroreNome = nomeVuoto ? 'Inserisci il nome del trattamento' : null;
      _erroreFinalita = finalitaVuota
          ? 'Inserisci la finalità del trattamento'
          : null;
    });

    if (nomeVuoto || finalitaVuota) {
      return;
    }

    Navigator.of(context).pop(
      _NuovoTrattamentoDialogResult(
        nome: _nomeController.text.trim(),
        finalita: _finalitaController.text.trim(),
        baseGiuridica: _baseGiuridicaController.text.trim(),
        categorieInteressati: _categorieInteressatiController.text.trim(),
        categorieDati: _categorieDatiController.text.trim(),
        destinatari: _destinatariController.text.trim(),
        conservazione: _conservazioneController.text.trim(),
        misureSicurezza: _misureSicurezzaController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.trattamento == null
            ? 'Nuovo trattamento'
            : 'Modifica trattamento',
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome trattamento *',
                  border: const OutlineInputBorder(),
                  errorText: _erroreNome,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _finalitaController,
                decoration: InputDecoration(
                  labelText: 'Finalità *',
                  border: const OutlineInputBorder(),
                  errorText: _erroreFinalita,
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseGiuridicaController,
                decoration: const InputDecoration(
                  labelText: 'Base giuridica',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categorieInteressatiController,
                decoration: const InputDecoration(
                  labelText: 'Categorie interessati',
                  border: OutlineInputBorder(),
                  hintText:
                      'Es. discenti, lavoratori, imprese clienti, docenti',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categorieDatiController,
                decoration: const InputDecoration(
                  labelText: 'Categorie dati personali',
                  border: OutlineInputBorder(),
                  hintText:
                      'Es. dati anagrafici, contatti, attestati, idoneità sanitarie',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _destinatariController,
                decoration: const InputDecoration(
                  labelText: 'Destinatari / categorie destinatari',
                  border: OutlineInputBorder(),
                  hintText:
                      'Es. enti attestati, consulenti, medico competente, software house',
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _conservazioneController,
                decoration: const InputDecoration(
                  labelText: 'Tempi di conservazione',
                  border: OutlineInputBorder(),
                  hintText:
                      'Es. 10 anni, durata rapporto contrattuale, obblighi di legge',
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _misureSicurezzaController,
                decoration: const InputDecoration(
                  labelText: 'Misure di sicurezza',
                  border: OutlineInputBorder(),
                  hintText:
                      'Es. accessi profilati, backup, antivirus, cifratura, armadi chiusi',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton.icon(
          onPressed: _salva,
          icon: const Icon(Icons.save),
          label: Text(widget.trattamento == null ? 'Salva' : 'Salva modifiche'),
        ),
      ],
    );
  }
}
