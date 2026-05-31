import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_service.dart';
import 'discente_scheda_page.dart';
import '../models/discente.dart';

class ScadenzePage extends StatefulWidget {
  final String filtro;

  const ScadenzePage({super.key, this.filtro = 'tutte'});

  @override
  State<ScadenzePage> createState() => _ScadenzePageState();
}

class _ScadenzePageState extends State<ScadenzePage> {
  final TextEditingController _cercaController = TextEditingController();

  List<Map<String, dynamic>> _scadenze = [];
  bool _caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaScadenze();
  }

  Future<void> caricaScadenze() async {
    setState(() {
      _caricamento = true;
    });

    try {
      final dati = await DatabaseService.instance.caricaScadenze();

      setState(() {
        _scadenze = dati;
        _caricamento = false;
      });
    } catch (e) {
      debugPrint('ERRORE CARICA SCADENZE: $e');

      setState(() {
        _scadenze = [];
        _caricamento = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore scadenze: $e')));
      }
    }
  }

  String formattaData(dynamic valore) {
    if (valore == null || valore.toString().isEmpty) {
      return '-';
    }

    try {
      final testo = valore.toString();

      DateTime data;

      // SQLITE YYYY-MM-DD
      if (testo.contains('-')) {
        data = DateTime.parse(testo);
      } else {
        return testo;
      }

      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    } catch (_) {
      return valore.toString();
    }
  }

  String calcolaStato(Map<String, dynamic> riga) {
    final statoDb = riga['stato']?.toString().toUpperCase();

    if (statoDb == 'SCADUTO') {
      return 'Scaduto';
    }

    if (statoDb == 'IN SCADENZA') {
      return 'In scadenza';
    }

    if (statoDb == 'VALIDO') {
      return 'Valido';
    }

    final valore = riga['scadenza'];

    if (valore == null || valore.toString().isEmpty) {
      return 'Senza scadenza';
    }

    final scadenza = DateTime.tryParse(valore.toString());

    if (scadenza == null) {
      return 'Senza scadenza';
    }

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);

    final scadenzaPulita = DateTime(
      scadenza.year,
      scadenza.month,
      scadenza.day,
    );

    final differenza = scadenzaPulita.difference(oggiPulito).inDays;

    if (differenza < 0) {
      return 'Scaduto';
    }

    if (differenza <= 60) {
      return 'In scadenza';
    }

    return 'Valido';
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'Valido':
        return const Color(0xFF16A34A);
      case 'In scadenza':
        return const Color(0xFFF59E0B);
      case 'Scaduto':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color sfondoStato(String stato) {
    switch (stato) {
      case 'Valido':
        return const Color(0xFFEAF7EE);
      case 'In scadenza':
        return const Color(0xFFFFF7E6);
      case 'Scaduto':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> rinnovaCorso(Map<String, dynamic> riga) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Rinnovo corso'),
          content: Text(
            'Vuoi creare un nuovo rinnovo per:\n\n'
            '${riga['discente']}\n'
            '${riga['corso']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Rinnova'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.rinnovaCorso(
      idDiscente: riga['id_discente'],
      idImpresa: riga['id_impresa'],
      idCorso: riga['id_corso'],
    );

    await caricaScadenze();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rinnovo creato correttamente')),
      );
    }
  }

  Future<void> apriSchedaDiscente(Map<String, dynamic> riga) async {
    final idDiscente = riga['id_discente'];

    if (idDiscente == null) return;

    final discente = await DatabaseService.instance.getDiscenteById(idDiscente);

    if (discente == null) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscenteSchedaPage(discente: discente)),
    );
  }

  List<Map<String, dynamic>> get scadenzeFiltrate {
    final testoRicerca = _cercaController.text.toLowerCase();

    return _scadenze.where((riga) {
      final stato = calcolaStato(riga);

      if (filtroStato == 'Scadute' && stato != 'Scaduto') {
        return false;
      }

      if (filtroStato == 'In scadenza' && stato != 'In scadenza') {
        return false;
      }

      if (filtroStato == 'Valide' && stato != 'Valido') {
        return false;
      }

      if (widget.filtro == 'scaduti' && stato != 'Scaduto') {
        return false;
      }

      if (widget.filtro == 'in_scadenza' && stato != 'In scadenza') {
        return false;
      }

      final discente = riga['discente']?.toString().toLowerCase() ?? '';

      final impresa = riga['impresa']?.toString().toLowerCase() ?? '';

      final corso = riga['corso']?.toString().toLowerCase() ?? '';

      if (testoRicerca.isNotEmpty &&
          !discente.contains(testoRicerca) &&
          !impresa.contains(testoRicerca) &&
          !corso.contains(testoRicerca)) {
        return false;
      }

      return true;
    }).toList();
  }

  String filtroStato = 'Tutte';

  @override
  Widget build(BuildContext context) {
    final scadute = _scadenze.where((s) => calcolaStato(s) == 'Scaduto').length;

    final inScadenza = _scadenze
        .where((s) => calcolaStato(s) == 'In scadenza')
        .length;

    final valide = _scadenze.where((s) => calcolaStato(s) == 'Valido').length;

    final totale = _scadenze.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scadenze',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ScadenzaCounterCard(
                titolo: 'Scadute',
                valore: scadute,
                colore: Color(0xFFDC2626),
                onTap: () {
                  setState(() {
                    filtroStato = 'Scadute';
                  });
                },
              ),

              _ScadenzaCounterCard(
                titolo: 'In scadenza',
                valore: inScadenza,
                colore: Color(0xFFF59E0B),
                onTap: () {
                  setState(() {
                    filtroStato = 'In scadenza';
                  });
                },
              ),

              _ScadenzaCounterCard(
                titolo: 'Valide',
                valore: valide,
                colore: Color(0xFF16A34A),
                onTap: () {
                  setState(() {
                    filtroStato = 'Valide';
                  });
                },
              ),

              _ScadenzaCounterCard(
                titolo: 'Totale',
                valore: totale,
                colore: Color(0xFF2563EB),
                onTap: () {
                  setState(() {
                    filtroStato = 'Tutte';
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _cercaController,
            decoration: InputDecoration(
              hintText: 'Cerca discente, impresa o corso',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FiltroScadenzaChip(
                label: 'Tutte',
                attivo: filtroStato == 'Tutte',
                onTap: () => setState(() => filtroStato = 'Tutte'),
              ),
              _FiltroScadenzaChip(
                label: 'Scadute',
                attivo: filtroStato == 'Scadute',
                onTap: () => setState(() => filtroStato = 'Scadute'),
              ),
              _FiltroScadenzaChip(
                label: 'In scadenza',
                attivo: filtroStato == 'In scadenza',
                onTap: () => setState(() => filtroStato = 'In scadenza'),
              ),
              _FiltroScadenzaChip(
                label: 'Valide',
                attivo: filtroStato == 'Valide',
                onTap: () => setState(() => filtroStato = 'Valide'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _caricamento
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      itemCount: scadenzeFiltrate.length,
                      itemBuilder: (context, index) {
                        final riga = scadenzeFiltrate[index];

                        final stato = calcolaStato(riga);

                        final colore = coloreStato(stato);

                        return InkWell(
                          onDoubleTap: () {
                            apriSchedaDiscente(riga);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    riga['discente']?.toString() ?? '-',
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    riga['impresa']?.toString() ?? '-',
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(riga['corso']?.toString() ?? '-'),
                                ),

                                Expanded(
                                  child: Text(formattaData(riga['data_corso'])),
                                ),

                                Expanded(
                                  child: Text(formattaData(riga['scadenza'])),
                                ),

                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colore.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      stato,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colore,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                IconButton(
                                  onPressed: () {
                                    rinnovaCorso(riga);
                                  },
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FiltroScadenzaChip extends StatelessWidget {
  final String label;
  final bool attivo;
  final VoidCallback onTap;

  const _FiltroScadenzaChip({
    required this.label,
    required this.attivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: attivo,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: attivo ? Colors.white : const Color(0xFF374151),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: attivo ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}

class _ScadenzaCounterCard extends StatelessWidget {
  final String titolo;
  final int valore;
  final Color colore;
  final VoidCallback onTap;

  const _ScadenzaCounterCard({
    required this.titolo,
    required this.valore,
    required this.colore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 10),
            Text(
              valore.toString(),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: colore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
