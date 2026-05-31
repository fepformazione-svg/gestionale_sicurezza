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

  bool eliminato = false;

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

  Future<void> eliminaDiscente() async {
    final id = widget.discente.id;
    if (id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina discente'),
          content: Text(
            'Vuoi eliminare definitivamente ${widget.discente.nome} ${widget.discente.cognome}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.deleteDiscente(id);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  String valore(dynamic v) {
    final testo = v?.toString().trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  DateTime? parseData(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';
    if (testo.isEmpty) return null;

    if (testo.contains('/')) {
      final parti = testo.split('/');
      if (parti.length == 3) {
        return DateTime.tryParse(
          '${parti[2]}-${parti[1].padLeft(2, '0')}-${parti[0].padLeft(2, '0')}',
        );
      }
    }

    return DateTime.tryParse(testo);
  }

  String statoScadenzaCorso(dynamic scadenza) {
    final data = parseData(scadenza);

    if (data == null) return 'SENZA SCADENZA';

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(data.year, data.month, data.day);

    final giorni = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorni < 0) return 'SCADUTO';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDO';
  }

  Color coloreStatoCorso(String stato) {
    switch (stato) {
      case 'VALIDO':
        return const Color(0xFF16A34A);
      case 'IN SCADENZA':
        return const Color(0xFFF59E0B);
      case 'SCADUTO':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color sfondoStatoCorso(String stato) {
    switch (stato) {
      case 'VALIDO':
        return const Color(0xFFEAF7EE);
      case 'IN SCADENZA':
        return const Color(0xFFFFF7E6);
      case 'SCADUTO':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
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
        actions: [
          IconButton(
            tooltip: 'Modifica',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pop(context, 'modifica');
            },
          ),
          IconButton(
            tooltip: 'Elimina',
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            onPressed: eliminaDiscente,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnagraficaCard(discente: d),
            const SizedBox(height: 18),
            _SorveglianzaSanitariaCard(discente: d),
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
                          final stato = statoScadenzaCorso(r['scadenza']);

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
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sfondoStatoCorso(stato),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    stato,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: coloreStatoCorso(stato),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${valore(r['durata_ore'])} h',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
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

class _SorveglianzaSanitariaCard extends StatelessWidget {
  final Discente discente;

  const _SorveglianzaSanitariaCard({required this.discente});

  String valore(String? v) {
    final testo = v?.trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  String _statoVisitaMedica(bool visitaSvolta, String? scadenza) {
    if (!visitaSvolta) return 'NON PRESENTE';

    final testo = scadenza?.trim() ?? '';
    if (testo.isEmpty) return 'SENZA SCADENZA';

    DateTime? data;

    if (testo.contains('/')) {
      final parti = testo.split('/');
      if (parti.length == 3) {
        data = DateTime.tryParse(
          '${parti[2]}-${parti[1].padLeft(2, '0')}-${parti[0].padLeft(2, '0')}',
        );
      }
    } else {
      data = DateTime.tryParse(testo);
    }

    if (data == null) return 'SENZA SCADENZA';

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(data.year, data.month, data.day);

    final giorni = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorni < 0) return 'SCADUTA';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDA';
  }

  Color _coloreStato(String stato) {
    switch (stato) {
      case 'VALIDA':
        return const Color(0xFF16A34A);
      case 'IN SCADENZA':
        return const Color(0xFFF59E0B);
      case 'SCADUTA':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _sfondoStato(String stato) {
    switch (stato) {
      case 'VALIDA':
        return const Color(0xFFEAF7EE);
      case 'IN SCADENZA':
        return const Color(0xFFFFF7E6);
      case 'SCADUTA':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitaSvolta = discente.visitaMedicaSvolta == 1;

    final statoVisita = _statoVisitaMedica(
      visitaSvolta,
      discente.scadenzaVisitaMedica,
    );

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
          _InfoItem(label: 'Visita medica', value: visitaSvolta ? 'Sì' : 'No'),
          _InfoItem(
            label: 'Data visita',
            value: valore(discente.dataVisitaMedica),
          ),
          _InfoItem(
            label: 'Scadenza visita',
            value: valore(discente.scadenzaVisitaMedica),
          ),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _sfondoStato(statoVisita),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statoVisita,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _coloreStato(statoVisita),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
