import 'package:flutter/material.dart';

import '../models/attrezzatura.dart';
import '../services/app_database.dart';

class AttrezzaturePage extends StatefulWidget {
  const AttrezzaturePage({super.key});

  @override
  State<AttrezzaturePage> createState() => _AttrezzaturePageState();
}

class _AttrezzaturePageState extends State<AttrezzaturePage> {
  List<Attrezzatura> attrezzature = [];
  bool caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaAttrezzature();
  }

  Future<void> caricaAttrezzature() async {
    final dati = await AppDatabase.instance.getAttrezzature();

    if (!mounted) return;

    setState(() {
      attrezzature = dati;
      caricamento = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attrezzature'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: caricamento
            ? const Center(child: CircularProgressIndicator())
            : Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: attrezzature.isEmpty
                      ? const _StatoVuotoAttrezzature()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.construction_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${attrezzature.length} ${attrezzature.length == 1 ? 'attrezzatura presente' : 'attrezzature presenti'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor:
                                      WidgetStateProperty.all<Color>(
                                        const Color(0xFFF1F5F9),
                                      ),
                                  columns: const [
                                    DataColumn(label: Text('Denominazione')),
                                    DataColumn(label: Text('Categoria')),
                                    DataColumn(label: Text('Codice')),
                                    DataColumn(label: Text('Quantità')),
                                    DataColumn(label: Text('Unità')),
                                    DataColumn(label: Text('Stato')),
                                  ],
                                  rows: attrezzature.map((attrezzatura) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(attrezzatura.denominazione),
                                        ),
                                        DataCell(Text(attrezzatura.categoria)),
                                        DataCell(Text(attrezzatura.codice)),
                                        DataCell(
                                          Text(
                                            attrezzatura.quantita.toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(attrezzatura.unitaMisura),
                                        ),
                                        DataCell(
                                          _BadgeStatoAttrezzatura(
                                            attiva: attrezzatura.attiva,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
      ),
    );
  }
}

class _StatoVuotoAttrezzature extends StatelessWidget {
  const _StatoVuotoAttrezzature();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.construction_rounded, color: Color(0xFF2563EB), size: 32),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gestione attrezzature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Nessuna attrezzatura inserita. In questa sezione potrai gestire materiali, DPI, dotazioni didattiche e strumenti usati nei corsi.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeStatoAttrezzatura extends StatelessWidget {
  final bool attiva;

  const _BadgeStatoAttrezzatura({required this.attiva});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: attiva ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        attiva ? 'Attiva' : 'Non attiva',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: attiva ? const Color(0xFF166534) : const Color(0xFF991B1B),
        ),
      ),
    );
  }
}
