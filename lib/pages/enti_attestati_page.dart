import 'package:flutter/material.dart';

import '../models/ente_attestato.dart';
import '../services/app_database.dart';

class EntiAttestatiPage extends StatefulWidget {
  const EntiAttestatiPage({super.key});

  @override
  State<EntiAttestatiPage> createState() => _EntiAttestatiPageState();
}

class _EntiAttestatiPageState extends State<EntiAttestatiPage> {
  List<EnteAttestato> entiAttestati = [];
  bool caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaEntiAttestati();
  }

  Future<void> caricaEntiAttestati() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getEntiAttestati();

    if (!mounted) return;

    setState(() {
      entiAttestati = dati;
      caricamento = false;
    });
  }

  Future<void> cambiaStatoEnte(EnteAttestato ente) async {
    final nuovoStato = ente.attivo == 1 ? 0 : 1;

    await AppDatabase.instance.aggiornaStatoEnteAttestato(
      id: ente.id!,
      attivo: nuovoStato,
    );

    await caricaEntiAttestati();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuovoStato == 1
              ? 'Ente rilascio attestati riattivato correttamente.'
              : 'Ente rilascio attestati disattivato correttamente.',
        ),
        backgroundColor: nuovoStato == 1 ? Colors.green : Colors.grey,
      ),
    );
  }

  Future<void> mostraDialogEnte({EnteAttestato? ente}) async {
    final formKey = GlobalKey<FormState>();
    final inModifica = ente != null;

    final denominazioneController = TextEditingController(
      text: ente?.denominazione ?? '',
    );
    final tipoController = TextEditingController(text: ente?.tipo ?? 'Ente');
    final codiceAccreditamentoController = TextEditingController(
      text: ente?.codiceAccreditamento ?? '',
    );
    final referenteController = TextEditingController(
      text: ente?.referente ?? '',
    );
    final telefonoController = TextEditingController(
      text: ente?.telefono ?? '',
    );
    final emailController = TextEditingController(text: ente?.email ?? '');
    final pecController = TextEditingController(text: ente?.pec ?? '');
    final indirizzoController = TextEditingController(
      text: ente?.indirizzo ?? '',
    );
    final comuneController = TextEditingController(text: ente?.comune ?? '');
    final noteController = TextEditingController(text: ente?.note ?? '');

    bool attivo = ente?.attivo == 1 || ente == null;

    String? valoreOpzionale(TextEditingController controller) {
      final valore = controller.text.trim();
      return valore.isEmpty ? null : valore;
    }

    try {
      final confermato = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.account_balance),
                    const SizedBox(width: 8),
                    Text(
                      inModifica
                          ? 'Modifica ente attestati'
                          : 'Nuova voce ente attestati',
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 680,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: denominazioneController,
                            decoration: const InputDecoration(
                              labelText: 'Denominazione *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Inserisci la denominazione';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: tipoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                    hintText: 'Es. Ente, Organismo, Regione',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: codiceAccreditamentoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Codice accreditamento',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: referenteController,
                            decoration: const InputDecoration(
                              labelText: 'Referente',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: telefonoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefono',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: pecController,
                            decoration: const InputDecoration(
                              labelText: 'PEC',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: indirizzoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Indirizzo',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: comuneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Comune',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Voce attiva'),
                            value: attivo,
                            onChanged: (value) {
                              setDialogState(() {
                                attivo = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annulla'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(true);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Salva'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confermato != true) return;

      if (inModifica) {
        await AppDatabase.instance.aggiornaEnteAttestato(
          id: ente.id!,
          denominazione: denominazioneController.text.trim(),
          tipo: tipoController.text.trim().isEmpty
              ? 'Ente'
              : tipoController.text.trim(),
          codiceAccreditamento: valoreOpzionale(codiceAccreditamentoController),
          referente: valoreOpzionale(referenteController),
          telefono: valoreOpzionale(telefonoController),
          email: valoreOpzionale(emailController),
          pec: valoreOpzionale(pecController),
          indirizzo: valoreOpzionale(indirizzoController),
          comune: valoreOpzionale(comuneController),
          note: valoreOpzionale(noteController),
          attivo: attivo ? 1 : 0,
        );
      } else {
        await AppDatabase.instance.inserisciEnteAttestato(
          denominazione: denominazioneController.text.trim(),
          tipo: tipoController.text.trim().isEmpty
              ? 'Ente'
              : tipoController.text.trim(),
          codiceAccreditamento: valoreOpzionale(codiceAccreditamentoController),
          referente: valoreOpzionale(referenteController),
          telefono: valoreOpzionale(telefonoController),
          email: valoreOpzionale(emailController),
          pec: valoreOpzionale(pecController),
          indirizzo: valoreOpzionale(indirizzoController),
          comune: valoreOpzionale(comuneController),
          note: valoreOpzionale(noteController),
          attivo: attivo ? 1 : 0,
        );
      }

      await caricaEntiAttestati();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inModifica
                ? 'Ente rilascio attestati aggiornato correttamente.'
                : 'Ente rilascio attestati salvato correttamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      denominazioneController.dispose();
      tipoController.dispose();
      codiceAccreditamentoController.dispose();
      referenteController.dispose();
      telefonoController.dispose();
      emailController.dispose();
      pecController.dispose();
      indirizzoController.dispose();
      comuneController.dispose();
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enti rilascio attestati'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => mostraDialogEnte(),
              icon: const Icon(Icons.add),
              label: const Text('Nuova voce'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${entiAttestati.length} enti presenti',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aggiorna elenco',
                      onPressed: caricaEntiAttestati,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: caricamento
                  ? const Center(child: CircularProgressIndicator())
                  : entiAttestati.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun ente rilascio attestati presente.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 28,
                            horizontalMargin: 28,
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text('Denominazione')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Codice accreditamento')),
                              DataColumn(label: Text('Referente')),
                              DataColumn(label: Text('Telefono')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Stato')),
                              DataColumn(label: Text('Azioni')),
                            ],
                            rows: entiAttestati.map((ente) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 230,
                                      child: Text(
                                        ente.denominazione,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        ente.tipo,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 145,
                                      child: Text(
                                        ente.codiceAccreditamento ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        ente.referente ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 125,
                                      child: Text(
                                        ente.telefono ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 190,
                                      child: Text(
                                        ente.email ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 82,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: ente.attivo == 1
                                            ? Colors.green[100]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        ente.attivo == 1
                                            ? 'ATTIVO'
                                            : 'NON ATT.',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: ente.attivo == 1
                                              ? Colors.green[800]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip:
                                                'Modifica ente rilascio attestati',
                                            onPressed: () =>
                                                mostraDialogEnte(ente: ente),
                                            icon: const Icon(Icons.edit),
                                          ),
                                          IconButton(
                                            tooltip: ente.attivo == 1
                                                ? 'Disattiva ente rilascio attestati'
                                                : 'Riattiva ente rilascio attestati',
                                            onPressed: () =>
                                                cambiaStatoEnte(ente),
                                            icon: Icon(
                                              ente.attivo == 1
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
