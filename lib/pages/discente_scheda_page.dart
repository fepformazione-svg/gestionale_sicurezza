import 'package:flutter/material.dart';

import '../models/discente.dart';
import '../services/database_service.dart';

class DiscenteSchedaPage extends StatefulWidget {
  final Discente discente;

  const DiscenteSchedaPage({super.key, required this.discente});

  @override
  State<DiscenteSchedaPage> createState() => _DiscenteSchedaPageState();
}

class _DiscenteSchedaPageState extends State<DiscenteSchedaPage> {
  bool caricamento = true;
  List<Map<String, dynamic>> storico = [];

  @override
  void initState() {
    super.initState();
    caricaStorico();
  }

  Future<void> caricaStorico() async {
    final id = widget.discente.id;

    if (id == null) {
      setState(() {
        storico = [];
        caricamento = false;
      });
      return;
    }

    final dati = await DatabaseService.instance.getStoricoDiscente(id);

    if (!mounted) return;

    setState(() {
      storico = dati;
      caricamento = false;
    });
  }

  String valore(dynamic v) {
    final testo = v?.toString().trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.discente;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('${d.nome} ${d.cognome}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnagraficaCard(discente: d),
            const SizedBox(height: 24),
            const Text(
              'Storico formativo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : storico.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun corso presente nello storico',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: storico.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        itemBuilder: (context, index) {
                          final r = storico[index];

                          return ListTile(
                            leading: const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF2563EB),
                            ),
                            title: Text(
                              valore(r['corso']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Data corso: ${valore(r['data'])}  •  Scadenza: ${valore(r['scadenza'])}',
                            ),
                            trailing: Text(
                              '${valore(r['durata_ore'])} h',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnagraficaCard extends StatelessWidget {
  final Discente discente;

  const _AnagraficaCard({required this.discente});

  String valore(String? v) {
    final testo = v?.trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        runSpacing: 18,
        spacing: 36,
        children: [
          _InfoItem(label: 'Nome', value: valore(discente.nome)),
          _InfoItem(label: 'Cognome', value: valore(discente.cognome)),
          _InfoItem(
            label: 'Luogo nascita',
            value: valore(discente.luogoNascita),
          ),
          _InfoItem(label: 'Data nascita', value: valore(discente.dataNascita)),
          _InfoItem(
            label: 'Codice fiscale',
            value: valore(discente.codiceFiscale),
          ),
          _InfoItem(label: 'Impresa', value: valore(discente.nomeImpresa)),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
