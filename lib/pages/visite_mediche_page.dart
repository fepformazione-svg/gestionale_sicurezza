import 'package:flutter/material.dart';

import '../services/app_database.dart';

class VisiteMedichePage extends StatefulWidget {
  const VisiteMedichePage({super.key});

  @override
  State<VisiteMedichePage> createState() => _VisiteMedichePageState();
}

class _VisiteMedichePageState extends State<VisiteMedichePage> {
  final TextEditingController _cercaController = TextEditingController();

  List<Map<String, dynamic>> visite = [];
  List<Map<String, dynamic>> visiteFiltrate = [];
  bool caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaVisite();
  }

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  Future<void> caricaVisite() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getVisiteMediche();

    if (!mounted) return;

    setState(() {
      visite = dati;
      applicaFiltro();
      caricamento = false;
    });
  }

  void applicaFiltro() {
    final ricerca = _cercaController.text.trim().toLowerCase();

    if (ricerca.isEmpty) {
      visiteFiltrate = List<Map<String, dynamic>>.from(visite);
      return;
    }

    visiteFiltrate = visite.where((visita) {
      final nome = visita['discente_nome']?.toString().toLowerCase() ?? '';
      final cognome =
          visita['discente_cognome']?.toString().toLowerCase() ?? '';
      final discente = '$cognome $nome $nome $cognome';
      final medico =
          visita['medico_struttura_denominazione']?.toString().toLowerCase() ??
          '';
      final tipo =
          visita['medico_struttura_tipo']?.toString().toLowerCase() ?? '';
      final esito = visita['esito']?.toString().toLowerCase() ?? '';
      final giudizio = visita['giudizio']?.toString().toLowerCase() ?? '';

      return discente.contains(ricerca) ||
          medico.contains(ricerca) ||
          tipo.contains(ricerca) ||
          esito.contains(ricerca) ||
          giudizio.contains(ricerca);
    }).toList();
  }

  String testoValore(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visite Mediche'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cercaController,
                    decoration: InputDecoration(
                      hintText:
                          'Cerca discente, medico, struttura, esito o giudizio...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _cercaController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Azzera ricerca',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                setState(() {
                                  _cercaController.clear();
                                  applicaFiltro();
                                });
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        applicaFiltro();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funzione Nuova visita in arrivo.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuova visita'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : visiteFiltrate.isEmpty
                    ? Center(
                        child: Text(
                          _cercaController.text.trim().isEmpty
                              ? 'Nessuna visita medica presente'
                              : 'Nessuna visita medica trovata',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF1F5F9),
                          ),
                          columns: const [
                            DataColumn(label: Text('Discente')),
                            DataColumn(label: Text('Medico / Struttura')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Data visita')),
                            DataColumn(label: Text('Scadenza')),
                            DataColumn(label: Text('Esito')),
                            DataColumn(label: Text('Giudizio')),
                            DataColumn(label: Text('Note')),
                          ],
                          rows: visiteFiltrate.map((visita) {
                            final nome = testoValore(visita['discente_nome']);
                            final cognome = testoValore(
                              visita['discente_cognome'],
                            );

                            return DataRow(
                              cells: [
                                DataCell(Text('$cognome $nome')),
                                DataCell(
                                  Text(
                                    testoValore(
                                      visita['medico_struttura_denominazione'],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    testoValore(
                                      visita['medico_struttura_tipo'],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(testoValore(visita['data_visita'])),
                                ),
                                DataCell(
                                  Text(testoValore(visita['data_scadenza'])),
                                ),
                                DataCell(Text(testoValore(visita['esito']))),
                                DataCell(Text(testoValore(visita['giudizio']))),
                                DataCell(Text(testoValore(visita['note']))),
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
