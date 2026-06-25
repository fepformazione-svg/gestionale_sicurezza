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

  Widget _buildStatoVuoto() {
    return const Center(
      child: Text(
        'Nessun trattamento registrato.\n'
        'Il registro è collegato al database, ma non contiene ancora dati.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
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
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Errore durante il caricamento del registro trattamenti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errore ?? '',
                textAlign: TextAlign.center,
              ),
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
            ],
            rows: trattamenti.map((trattamento) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(trattamento.nomeTrattamento),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(trattamento.finalita),
                    ),
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
                      label: Text(
                        trattamento.attivo ? 'Attivo' : 'Non attivo',
                      ),
                      backgroundColor: trattamento.attivo
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errore != null) {
      return _buildErrore();
    }

    if (trattamenti.isEmpty) {
      return _buildStatoVuoto();
    }

    return _buildTabella();
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContenuto(),
            ),
          ],
        ),
      ),
    );
  }
}
