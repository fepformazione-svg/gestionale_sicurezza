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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enti rilascio attestati')),
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
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text('Denominazione')),
                              DataColumn(label: Text('Tipo')),

                              DataColumn(label: Text('Referente')),
                              DataColumn(label: Text('Telefono')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Stato')),
                            ],
                            rows: entiAttestati.map((ente) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 260,
                                      child: Text(
                                        ente.denominazione,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        ente.tipo,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        ente.referente ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        ente.telefono ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 220,
                                      child: Text(
                                        ente.email ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 90,
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: ente.attivo == 1
                                              ? Colors.green[800]
                                              : Colors.grey[700],
                                        ),
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
