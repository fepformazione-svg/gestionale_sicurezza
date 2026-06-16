import 'package:flutter/material.dart';
import '../models/prezzario.dart';
import '../services/database_service.dart';

class PrezzarioPage extends StatefulWidget {
  const PrezzarioPage({super.key});

  @override
  State<PrezzarioPage> createState() => _PrezzarioPageState();
}

class _PrezzarioPageState extends State<PrezzarioPage> {
  bool caricamento = true;
  List<Prezzario> vociPrezzario = [];

  @override
  void initState() {
    super.initState();
    caricaPrezzario();
  }

  Future<void> caricaPrezzario() async {
    setState(() {
      caricamento = true;
    });

    final dati = await DatabaseService.instance.getPrezzario();

    if (!mounted) return;

    setState(() {
      vociPrezzario = dati;
      caricamento = false;
    });
  }

  String formattaPrezzo(double valore) {
    return '€ ${valore.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.price_change_rounded,
              color: Color(0xFF0F172A),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Prezzario',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: caricaPrezzario,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Aggiorna'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Prezzi personalizzati per impresa e corso.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
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
                : vociPrezzario.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.price_check_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nessuna voce di prezzario presente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Aggiungeremo inserimento e modifica nel prossimo step.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF1F5F9),
                      ),
                      columns: const [
                        DataColumn(label: Text('Impresa')),
                        DataColumn(label: Text('Corso')),
                        DataColumn(label: Text('Prezzo')),
                        DataColumn(label: Text('Note')),
                      ],
                      rows: vociPrezzario.map((voce) {
                        return DataRow(
                          cells: [
                            DataCell(Text(voce.impresa ?? '-')),
                            DataCell(Text(voce.corso ?? '-')),
                            DataCell(Text(formattaPrezzo(voce.prezzo))),
                            DataCell(Text(voce.note.isEmpty ? '-' : voce.note)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
