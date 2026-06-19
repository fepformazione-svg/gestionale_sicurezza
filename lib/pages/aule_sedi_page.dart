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
