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
                  onPressed: () {},
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
