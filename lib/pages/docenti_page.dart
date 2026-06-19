import 'package:flutter/material.dart';

import '../services/app_database.dart';

class DocentiPage extends StatefulWidget {
  const DocentiPage({super.key});

  @override
  State<DocentiPage> createState() => _DocentiPageState();
}

class _DocentiPageState extends State<DocentiPage> {
  List<Map<String, dynamic>> docenti = [];
  final TextEditingController ricercaController = TextEditingController();
  String ricerca = '';
  bool caricamento = true;

  List<Map<String, dynamic>> get docentiFiltrati {
    final testo = ricerca.trim().toLowerCase();

    if (testo.isEmpty) return docenti;

    return docenti.where((docente) {
      final nome = docente['nome']?.toString().toLowerCase() ?? '';
      final cognome = docente['cognome']?.toString().toLowerCase() ?? '';
      final qualifica = docente['qualifica']?.toString().toLowerCase() ?? '';
      final email = docente['email']?.toString().toLowerCase() ?? '';
      final telefono = docente['telefono']?.toString().toLowerCase() ?? '';

      return nome.contains(testo) ||
          cognome.contains(testo) ||
          qualifica.contains(testo) ||
          email.contains(testo) ||
          telefono.contains(testo);
    }).toList();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    super.dispose();
  }

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

  Future<void> apriDialogModificaDocente(Map<String, dynamic> docente) async {
    final nomeController = TextEditingController(
      text: docente['nome']?.toString() ?? '',
    );
    final cognomeController = TextEditingController(
      text: docente['cognome']?.toString() ?? '',
    );
    final telefonoController = TextEditingController(
      text: docente['telefono']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: docente['email']?.toString() ?? '',
    );
    final codiceFiscaleController = TextEditingController(
      text: docente['codice_fiscale']?.toString() ?? '',
    );
    final qualificaController = TextEditingController(
      text: docente['qualifica']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: docente['note']?.toString() ?? '',
    );

    bool attivo = docente['attivo'] == 1;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica docente'),
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

                    await AppDatabase.instance.aggiornaDocente(
                      id: docente['id'] as int,
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
                  label: const Text('Salva modifiche'),
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
          content: Text('Docente aggiornato.'),
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
              ricerca.trim().isEmpty
                  ? '${docenti.length} docenti presenti'
                  : '${docentiFiltrati.length} docenti trovati su ${docenti.length}',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ricercaController,
              decoration: InputDecoration(
                hintText: 'Cerca docente, qualifica, email o telefono...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ricerca.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Pulisci ricerca',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ricercaController.clear();
                          setState(() {
                            ricerca = '';
                          });
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.blueGrey.shade100),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  ricerca = value;
                });
              },
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
                    : docentiFiltrati.isEmpty
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
                            DataColumn(label: Text('Azioni')),
                          ],
                          rows: docentiFiltrati.map((docente) {
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
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Modifica docente',
                                        icon: const Icon(Icons.edit_rounded),
                                        color: Colors.blueGrey,
                                        onPressed: () =>
                                            apriDialogModificaDocente(docente),
                                      ),
                                      IconButton(
                                        tooltip: attivo
                                            ? 'Disattiva docente'
                                            : 'Riattiva docente',
                                        icon: Icon(
                                          attivo
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                        color: attivo
                                            ? Colors.orange.shade700
                                            : Colors.green.shade700,
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);

                                          await AppDatabase.instance
                                              .aggiornaDocente(
                                                id: docente['id'] as int,
                                                nome:
                                                    docente['nome']
                                                        ?.toString() ??
                                                    '',
                                                cognome:
                                                    docente['cognome']
                                                        ?.toString() ??
                                                    '',
                                                telefono: docente['telefono']
                                                    ?.toString(),
                                                email: docente['email']
                                                    ?.toString(),
                                                codiceFiscale:
                                                    docente['codice_fiscale']
                                                        ?.toString(),
                                                qualifica: docente['qualifica']
                                                    ?.toString(),
                                                note: docente['note']
                                                    ?.toString(),
                                                attivo: attivo ? 0 : 1,
                                              );

                                          await caricaDocenti();

                                          if (!mounted) return;

                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                attivo
                                                    ? 'Docente disattivato.'
                                                    : 'Docente riattivato.',
                                              ),
                                              backgroundColor: attivo
                                                  ? Colors.orange
                                                  : Colors.green,
                                            ),
                                          );
                                        },
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
            ),
          ],
        ),
      ),
    );
  }
}
