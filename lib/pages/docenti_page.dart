import 'package:flutter/material.dart';

import '../services/app_database.dart';

class DocentiPage extends StatefulWidget {
  const DocentiPage({super.key});

  @override
  State<DocentiPage> createState() => _DocentiPageState();
}

class _DocentiPageState extends State<DocentiPage> {
  List<Map<String, dynamic>> docenti = [];
  bool caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaDocenti();
  }

  Future<void> caricaDocenti() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getDocenti();

    if (!mounted) return;

    setState(() {
      docenti = dati;
      caricamento = false;
    });
  }

  Future<void> apriDialogNuovoDocente() async {
    final nomeController = TextEditingController();
    final cognomeController = TextEditingController();
    final telefonoController = TextEditingController();
    final emailController = TextEditingController();
    final codiceFiscaleController = TextEditingController();
    final qualificaController = TextEditingController();
    final noteController = TextEditingController();
    bool attivo = true;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuovo docente'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: cognomeController,
                        decoration: const InputDecoration(
                          labelText: 'Cognome *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(labelText: 'Nome *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qualificaController,
                        decoration: const InputDecoration(
                          labelText: 'Qualifica',
                          hintText: 'Es. Docente sicurezza, antincendio...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codiceFiscaleController,
                        decoration: const InputDecoration(
                          labelText: 'Codice fiscale',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Note'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Docente attivo'),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (nomeController.text.trim().isEmpty ||
                        cognomeController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nome e cognome sono obbligatori.'),
                        ),
                      );
                      return;
                    }

                    await AppDatabase.instance.inserisciDocente(
                      nome: nomeController.text,
                      cognome: cognomeController.text,
                      telefono: telefonoController.text,
                      email: emailController.text,
                      codiceFiscale: codiceFiscaleController.text,
                      qualifica: qualificaController.text,
                      note: noteController.text,
                      attivo: attivo ? 1 : 0,
                    );

                    if (!dialogContext.mounted) return;
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

    nomeController.dispose();
    cognomeController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    codiceFiscaleController.dispose();
    qualificaController.dispose();
    noteController.dispose();

    if (salvato == true) {
      await caricaDocenti();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Docente salvato.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Docenti'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey.shade800,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Gestione Docenti',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: apriDialogNuovoDocente,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuovo docente'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${docenti.length} docenti presenti',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : docenti.isEmpty
                    ? Center(
                        child: Text(
                          'Nessun docente inserito',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey.shade500,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                          columns: const [
                            DataColumn(label: Text('Cognome')),
                            DataColumn(label: Text('Nome')),
                            DataColumn(label: Text('Qualifica')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Telefono')),
                            DataColumn(label: Text('Stato')),
                          ],
                          rows: docenti.map((docente) {
                            final attivo = docente['attivo'] == 1;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(docente['cognome']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(docente['nome']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(docente['qualifica']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(docente['email']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(docente['telefono']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      attivo ? 'Attivo' : 'Non attivo',
                                    ),
                                    backgroundColor: attivo
                                        ? Colors.green.shade50
                                        : Colors.grey.shade200,
                                    labelStyle: TextStyle(
                                      color: attivo
                                          ? Colors.green.shade800
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}
