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
  List<Map<String, dynamic>> discenti = [];
  List<Map<String, dynamic>> mediciStrutture = [];
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
    final elencoDiscenti = await AppDatabase.instance
        .getDiscentiPerVisiteMediche();
    final elencoMediciStrutture = await AppDatabase.instance
        .getMediciStrutture();

    if (!mounted) return;

    setState(() {
      visite = dati;
      discenti = elencoDiscenti;
      mediciStrutture = elencoMediciStrutture
          .where((voce) => voce['attivo']?.toString() != '0')
          .toList();
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

  Future<void> apriDialogNuovaVisita() async {
    if (discenti.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun discente disponibile per creare una visita.'),
        ),
      );
      return;
    }

    if (mediciStrutture.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun medico o struttura attiva disponibile. Aggiungine una da Impostazioni.',
          ),
        ),
      );
      return;
    }

    int? discenteSelezionatoId;
    int? medicoStrutturaSelezionatoId;

    final dataVisitaController = TextEditingController();
    final dataScadenzaController = TextEditingController();
    final esitoController = TextEditingController();
    final giudizioController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova visita medica'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: discenteSelezionatoId,
                        decoration: const InputDecoration(
                          labelText: 'Discente',
                          border: OutlineInputBorder(),
                        ),
                        items: discenti.map((discente) {
                          final id = discente['id'] as int;
                          final nome = discente['nome']?.toString() ?? '';
                          final cognome = discente['cognome']?.toString() ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$cognome $nome'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            discenteSelezionatoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: medicoStrutturaSelezionatoId,
                        decoration: const InputDecoration(
                          labelText: 'Medico / Struttura',
                          border: OutlineInputBorder(),
                        ),
                        items: mediciStrutture.map((voce) {
                          final id = voce['id'] as int;
                          final tipo = voce['tipo']?.toString() ?? '';
                          final denominazione =
                              voce['denominazione']?.toString() ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$tipo - $denominazione'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            medicoStrutturaSelezionatoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataVisitaController,
                        decoration: const InputDecoration(
                          labelText: 'Data visita',
                          hintText: 'Es. 17/06/2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataScadenzaController,
                        decoration: const InputDecoration(
                          labelText: 'Data scadenza',
                          hintText: 'Es. 17/06/2027',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: esitoController,
                        decoration: const InputDecoration(
                          labelText: 'Esito',
                          hintText: 'Es. Idoneo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: giudizioController,
                        decoration: const InputDecoration(
                          labelText: 'Giudizio',
                          hintText: 'Es. Idoneità alla mansione',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    if (discenteSelezionatoId == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Seleziona un discente.')),
                      );
                      return;
                    }

                    if (medicoStrutturaSelezionatoId == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Seleziona un medico o una struttura.'),
                        ),
                      );
                      return;
                    }

                    await AppDatabase.instance.inserisciVisitaMedica(
                      discenteId: discenteSelezionatoId!,
                      medicoStrutturaId: medicoStrutturaSelezionatoId,
                      dataVisita: dataVisitaController.text.trim(),
                      dataScadenza: dataScadenzaController.text.trim(),
                      esito: esitoController.text.trim(),
                      giudizio: giudizioController.text.trim(),
                      note: noteController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    await caricaVisite();

                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Visita medica salvata.')),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );

    dataVisitaController.dispose();
    dataScadenzaController.dispose();
    esitoController.dispose();
    giudizioController.dispose();
    noteController.dispose();
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
                  onPressed: apriDialogNuovaVisita,
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
