import 'package:flutter/material.dart';

import '../models/aula_sede.dart';
import '../services/app_database.dart';

class AuleSediPage extends StatefulWidget {
  const AuleSediPage({super.key});

  @override
  State<AuleSediPage> createState() => _AuleSediPageState();
}

class _AuleSediPageState extends State<AuleSediPage> {
  List<AulaSede> auleSedi = [];
  bool caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaAuleSedi();
  }

  Future<void> caricaAuleSedi() async {
    setState(() => caricamento = true);

    final dati = await AppDatabase.instance.getAuleSedi();

    if (!mounted) return;

    setState(() {
      auleSedi = dati;
      caricamento = false;
    });
  }

  Future<void> apriDialogNuovaAulaSede() async {
    final formKey = GlobalKey<FormState>();

    final denominazioneController = TextEditingController();
    final indirizzoController = TextEditingController();
    final comuneController = TextEditingController();
    final capienzaController = TextEditingController();
    final noteController = TextEditingController();

    String tipoSelezionato = 'Aula';
    bool attiva = true;

    final salvata = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova aula / sede formativa'),
              content: SizedBox(
                width: 520,
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
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSelezionato,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Aula',
                              child: Text('Aula'),
                            ),
                            DropdownMenuItem(
                              value: 'Campo prove',
                              child: Text('Campo prove'),
                            ),
                            DropdownMenuItem(
                              value: 'Sede cliente',
                              child: Text('Sede cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'Altro',
                              child: Text('Altro'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => tipoSelezionato = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: indirizzoController,
                          decoration: const InputDecoration(
                            labelText: 'Indirizzo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: comuneController,
                          decoration: const InputDecoration(
                            labelText: 'Comune',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: capienzaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capienza',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final testo = value?.trim() ?? '';
                            if (testo.isEmpty) return null;

                            final numero = int.tryParse(testo);
                            if (numero == null || numero < 0) {
                              return 'Inserisci un numero valido';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          value: attiva,
                          onChanged: (value) {
                            setDialogState(() => attiva = value);
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final capienzaTesto = capienzaController.text.trim();

                    final aulaSede = AulaSede(
                      denominazione: denominazioneController.text.trim(),
                      tipo: tipoSelezionato,
                      indirizzo: indirizzoController.text.trim(),
                      comune: comuneController.text.trim(),
                      capienza: capienzaTesto.isEmpty
                          ? null
                          : int.tryParse(capienzaTesto),
                      note: noteController.text.trim(),
                      attiva: attiva,
                    );

                    await AppDatabase.instance.inserisciAulaSede(aulaSede);

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    denominazioneController.dispose();
    indirizzoController.dispose();
    comuneController.dispose();
    capienzaController.dispose();
    noteController.dispose();

    if (salvata == true) {
      await caricaAuleSedi();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aula / sede formativa salvata.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> apriDialogModificaAulaSede(AulaSede aulaSede) async {
    final formKey = GlobalKey<FormState>();

    final denominazioneController = TextEditingController(
      text: aulaSede.denominazione,
    );
    final indirizzoController = TextEditingController(text: aulaSede.indirizzo);
    final comuneController = TextEditingController(text: aulaSede.comune);
    final capienzaController = TextEditingController(
      text: aulaSede.capienza == null ? '' : aulaSede.capienza.toString(),
    );
    final noteController = TextEditingController(text: aulaSede.note);

    String tipoSelezionato = aulaSede.tipo;
    bool attiva = aulaSede.attiva;

    final salvata = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica aula / sede formativa'),
              content: SizedBox(
                width: 520,
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
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSelezionato,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Aula',
                              child: Text('Aula'),
                            ),
                            DropdownMenuItem(
                              value: 'Campo prove',
                              child: Text('Campo prove'),
                            ),
                            DropdownMenuItem(
                              value: 'Sede cliente',
                              child: Text('Sede cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'Altro',
                              child: Text('Altro'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => tipoSelezionato = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: indirizzoController,
                          decoration: const InputDecoration(
                            labelText: 'Indirizzo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: comuneController,
                          decoration: const InputDecoration(
                            labelText: 'Comune',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: capienzaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capienza',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final testo = value?.trim() ?? '';
                            if (testo.isEmpty) return null;

                            final numero = int.tryParse(testo);
                            if (numero == null || numero < 0) {
                              return 'Inserisci un numero valido';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          value: attiva,
                          onChanged: (value) {
                            setDialogState(() => attiva = value);
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final capienzaTesto = capienzaController.text.trim();

                    final aulaSedeAggiornata = aulaSede.copyWith(
                      denominazione: denominazioneController.text.trim(),
                      tipo: tipoSelezionato,
                      indirizzo: indirizzoController.text.trim(),
                      comune: comuneController.text.trim(),
                      capienza: capienzaTesto.isEmpty
                          ? null
                          : int.tryParse(capienzaTesto),
                      note: noteController.text.trim(),
                      attiva: attiva,
                    );

                    await AppDatabase.instance.aggiornaAulaSede(
                      aulaSedeAggiornata,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    denominazioneController.dispose();
    indirizzoController.dispose();
    comuneController.dispose();
    capienzaController.dispose();
    noteController.dispose();

    if (salvata == true) {
      await caricaAuleSedi();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aula / sede formativa aggiornata.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String testoCapienza(AulaSede aulaSede) {
    if (aulaSede.capienza == null) return '-';
    if (aulaSede.capienza! <= 0) return '-';
    return aulaSede.capienza.toString();
  }

  Widget badgeTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          color: Colors.blueGrey.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget badgeStato(bool attiva) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: attiva ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: attiva ? Colors.green.shade200 : Colors.grey.shade400,
        ),
      ),
      child: Text(
        attiva ? 'Attiva' : 'Non attiva',
        style: TextStyle(
          color: attiva ? Colors.green.shade800 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.meeting_room, color: Colors.blueGrey.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Aule / Sedi formative',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: apriDialogNuovaAulaSede,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova voce'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: caricaAuleSedi,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Aggiorna'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gestione di aule, campi prova e sedi utilizzabili per corsi e sessioni formative.',
              style: TextStyle(color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.blueGrey.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: caricamento
                      ? const Center(child: CircularProgressIndicator())
                      : auleSedi.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 54,
                                color: Colors.blueGrey.shade300,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Nessuna aula o sede formativa presente',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Qui saranno elencate le aule, i campi prova e le sedi cliente.',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              Colors.blueGrey.shade50,
                            ),
                            columns: const [
                              DataColumn(label: Text('Denominazione')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Indirizzo')),
                              DataColumn(label: Text('Comune')),
                              DataColumn(label: Text('Capienza')),
                              DataColumn(label: Text('Stato')),
                              DataColumn(label: Text('Note')),
                              DataColumn(label: Text('Azioni')),
                            ],
                            rows: auleSedi.map((aulaSede) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      aulaSede.denominazione,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(badgeTipo(aulaSede.tipo)),
                                  DataCell(Text(aulaSede.indirizzo)),
                                  DataCell(Text(aulaSede.comune)),
                                  DataCell(Text(testoCapienza(aulaSede))),
                                  DataCell(badgeStato(aulaSede.attiva)),
                                  DataCell(Text(aulaSede.note)),
                                  DataCell(
                                    Builder(
                                      builder: (cellContext) {
                                        return IconButton(
                                          tooltip: 'Modifica aula / sede',
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blueGrey.shade700,
                                          ),
                                          onPressed: () {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (!mounted) return;
                                                  apriDialogModificaAulaSede(
                                                    aulaSede,
                                                  );
                                                });
                                          },
                                        );
                                      },
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
