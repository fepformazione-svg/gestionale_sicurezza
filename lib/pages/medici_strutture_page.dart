import 'package:flutter/material.dart';

import '../services/app_database.dart';

class MediciStrutturePage extends StatefulWidget {
  const MediciStrutturePage({super.key});

  @override
  State<MediciStrutturePage> createState() => _MediciStrutturePageState();
}

class _MediciStrutturePageState extends State<MediciStrutturePage> {
  final TextEditingController _cercaController = TextEditingController();

  List<Map<String, dynamic>> mediciStrutture = [];
  bool caricamento = true;
  bool soloAttivi = false;

  @override
  void initState() {
    super.initState();
    caricaMediciStrutture();
  }

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  Future<void> caricaMediciStrutture() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getMediciStrutture(
      ricerca: _cercaController.text,
      soloAttivi: soloAttivi,
    );

    if (!mounted) return;

    setState(() {
      mediciStrutture = dati;
      caricamento = false;
    });
  }

  Color coloreTipo(String tipo) {
    final tipoNormalizzato = tipo.toLowerCase().trim();

    if (tipoNormalizzato.contains('struttura')) {
      return const Color(0xFF7C3AED);
    }

    return const Color(0xFF2563EB);
  }

  Widget badgeTipo(String tipo) {
    final colore = coloreTipo(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colore.withValues(alpha: 0.25)),
      ),
      child: Text(
        tipo.isEmpty ? 'Medico' : tipo,
        style: TextStyle(
          color: colore,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget badgeAttivo(int attivo) {
    final isAttivo = attivo == 1;
    final colore = isAttivo ? const Color(0xFF16A34A) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colore.withValues(alpha: 0.25)),
      ),
      child: Text(
        isAttivo ? 'ATTIVO' : 'NON ATTIVO',
        style: TextStyle(
          color: colore,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Medici / Strutture mediche'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cercaController,
                    onChanged: (_) => caricaMediciStrutture(),
                    decoration: InputDecoration(
                      hintText:
                          'Cerca medico, struttura, referente, telefono, email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _cercaController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Azzera ricerca',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _cercaController.clear();
                                caricaMediciStrutture();
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  selected: soloAttivi,
                  label: const Text('Solo attivi'),
                  avatar: const Icon(Icons.check_circle_rounded, size: 18),
                  onSelected: (valore) {
                    setState(() {
                      soloAttivi = valore;
                    });
                    caricaMediciStrutture();
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nuova voce medici/strutture: funzione in arrivo.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuova voce'),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                    : mediciStrutture.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.medical_services_rounded,
                                size: 52,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _cercaController.text.trim().isEmpty
                                    ? 'Nessun medico o struttura presente'
                                    : 'Nessun risultato trovato',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _cercaController.text.trim().isEmpty
                                    ? 'Aggiungi medici competenti o strutture mediche per gestire le visite del lavoro.'
                                    : 'Prova a modificare o azzerare la ricerca.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          columns: const [
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Denominazione')),
                            DataColumn(label: Text('Referente')),
                            DataColumn(label: Text('Telefono')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Stato')),
                          ],
                          rows: mediciStrutture.map((voce) {
                            final tipo = voce['tipo']?.toString() ?? 'Medico';
                            final attivo =
                                int.tryParse(
                                  voce['attivo']?.toString() ?? '1',
                                ) ??
                                1;

                            return DataRow(
                              cells: [
                                DataCell(badgeTipo(tipo)),
                                DataCell(
                                  Text(
                                    voce['denominazione']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(voce['referente']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(voce['telefono']?.toString() ?? ''),
                                ),
                                DataCell(Text(voce['email']?.toString() ?? '')),
                                DataCell(badgeAttivo(attivo)),
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
