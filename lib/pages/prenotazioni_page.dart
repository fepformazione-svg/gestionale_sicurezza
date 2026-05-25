import 'package:flutter/material.dart';

import '../database/database_service_old.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/prenotazione_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/table_status_badge.dart';

class PrenotazioniPage extends StatefulWidget {
  final String globalSearch;
  final String filtro;

  const PrenotazioniPage({
    super.key,
    required this.globalSearch,
    this.filtro = 'tutte',
  });

  @override
  State<PrenotazioniPage> createState() => _PrenotazioniPageState();
}
 
class _PrenotazioniPageState extends State<PrenotazioniPage> {
  List<Map<String, dynamic>> prenotazioni = [];
  List<Map<String, dynamic>> prenotazioniFiltrate = [];
List<Map<String, dynamic>> get prenotazioniVisibili {
  return prenotazioniFiltrate.where((p) {
    final stato = statoPrenotazione(p);

    if (widget.filtro == 'aperte') {
      return stato == 'Aperto';
    }

    if (widget.filtro == 'chiuse') {
      return stato == 'Chiuso';
    }

    return true;
  }).toList();
}
  bool loading = true;

  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    caricaPrenotazioni();
  }

  @override
void didUpdateWidget(
  covariant PrenotazioniPage oldWidget,
) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.globalSearch != widget.globalSearch ||
      oldWidget.filtro != widget.filtro) {
    cercaPrenotazioni(widget.globalSearch);
  }
}

  String testo(dynamic value) {
    return (value ?? '').toString();
  }

  String nomeDiscente(Map<String, dynamic> p) {
    final cognome = testo(p['discente_cognome']);
    final nome = testo(p['discente_nome']);

    return '$cognome $nome'.trim();
  }

  String statoPrenotazione(Map<String, dynamic> p) {
    final conferma = p['conferma'] == 1;
    final registro = p['registro'] == 1;
    final aperto = p['aperto'] == 1;

    if (conferma) return 'Chiuso';
    if (registro) return 'Registro';
    if (aperto) return 'Aperto';
    return 'Da fare';
  }

  Map<String, dynamic> normalizzaPrenotazione(
    Map<String, dynamic> dati,
  ) {
    return {
      'discente_id': dati['discente_id'],
      'impresa_id': dati['impresa_id'],
      'corso_id': dati['corso_id'],
      'data': testo(dati['data']).trim(),
      'prot': testo(dati['prot']).trim(),
      'aperto': dati['aperto'] == 1 ? 1 : 0,
      'conferma': dati['conferma'] == 1 ? 1 : 0,
      'registro': dati['registro'] == 1 ? 1 : 0,
    };
  }

  Future<void> caricaPrenotazioni() async {
    final dati = await DatabaseService.instance.getPrenotazioni();

    setState(() {
      prenotazioni = dati;
      prenotazioniFiltrate = dati;
      loading = false;
    });

    if (widget.globalSearch.trim().isNotEmpty) {
      cercaPrenotazioni(widget.globalSearch);
    }
  }

  void cercaPrenotazioni(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        prenotazioniFiltrate = prenotazioni;
        return;
      }

      prenotazioniFiltrate = prenotazioni.where((p) {
        final discente = nomeDiscente(p).toLowerCase();
        final impresa = testo(p['impresa_nome']).toLowerCase();
        final corso = testo(p['corso_nome']).toLowerCase();
        final data = testo(p['data']).toLowerCase();
        final prot = testo(p['prot']).toLowerCase();
        final stato = statoPrenotazione(p).toLowerCase();

        return discente.contains(query) ||
            impresa.contains(query) ||
            corso.contains(query) ||
            data.contains(query) ||
            prot.contains(query) ||
            stato.contains(query);
      }).toList();
    });
  }

  void ordina<T>(
    int columnIndex,
    bool ascending,
    Comparable<T> Function(Map<String, dynamic> p) getField,
  ) {
    prenotazioniFiltrate.sort((a, b) {
      if (!ascending) {
        final c = a;
        a = b;
        b = c;
      }

      final aValue = getField(a);
      final bValue = getField(b);

      return Comparable.compare(aValue, bValue);
    });

    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }

  Future<void> apriDialogNuovaPrenotazione() async {
    final nuovaPrenotazione = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return const PrenotazioneDialog();
      },
    );

    if (nuovaPrenotazione == null) return;

    try {
      final datiPuliti = normalizzaPrenotazione(nuovaPrenotazione);

      final nuovoId =
          await DatabaseService.instance.insertPrenotazione(datiPuliti);

            if (datiPuliti['conferma'] == 1) {
        await DatabaseService.instance
            .confermaPrenotazioneWorkflow(nuovoId);
      }

      await caricaPrenotazioni();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prenotazione salvata'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore salvataggio prenotazione: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> modificaPrenotazione(
    Map<String, dynamic> prenotazione,
  ) async {
    final prenotazioneModificata =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return PrenotazioneDialog(
          prenotazione: prenotazione,
        );
      },
    );

    if (prenotazioneModificata == null) return;

    try {
      final datiPuliti =
          normalizzaPrenotazione(prenotazioneModificata);

      await DatabaseService.instance.updatePrenotazione(
        prenotazione['id'],
        datiPuliti,
      );

            if (datiPuliti['conferma'] == 1) {
        await DatabaseService.instance
            .confermaPrenotazioneWorkflow(
          prenotazione['id'],
        );
      } else {
        await DatabaseService.instance
            .annullaConfermaPrenotazioneWorkflow(
          prenotazione['id'],
        );
      }

      await caricaPrenotazioni();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prenotazione aggiornata'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore modifica prenotazione: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> eliminaPrenotazione(
    Map<String, dynamic> prenotazione,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina prenotazione'),
          content: Text(
            'Eliminare ${nomeDiscente(prenotazione)}?',
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

    await DatabaseService.instance.deletePrenotazione(
      prenotazione['id'],
    );

    await caricaPrenotazioni();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Prenotazioni',
          subtitle: 'Gestione enterprise delle prenotazioni.',
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hintText: 'Ricerca nella pagina prenotazioni...',
                onChanged: cercaPrenotazioni,
              ),
            ),

            const SizedBox(width: 16),

            ElevatedButton.icon(
              onPressed: apriDialogNuovaPrenotazione,
              icon: const Icon(Icons.add),
              label: const Text('Nuova prenotazione'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Expanded(
          child: SectionCard(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'DataTable Enterprise',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Text(
                            '${prenotazioniVisibili.length} record',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.white,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                sortColumnIndex: sortColumnIndex,
                                sortAscending: sortAscending,
                                headingRowColor:
                                    WidgetStateProperty.all(
                                  const Color(0xFFF3F4F6),
                                ),
                                dataRowMinHeight: 64,
                                dataRowMaxHeight: 64,
                                columnSpacing: 28,
                                horizontalMargin: 20,
                                columns: [
                                  DataColumn(
                                    label: const Text('Discente'),
                                    onSort: (columnIndex, ascending) {
                                      ordina<String>(
                                        columnIndex,
                                        ascending,
                                        nomeDiscente,
                                      );
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Impresa'),
                                    onSort: (columnIndex, ascending) {
                                      ordina<String>(
                                        columnIndex,
                                        ascending,
                                        (p) => testo(p['impresa_nome']),
                                      );
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Corso'),
                                    onSort: (columnIndex, ascending) {
                                      ordina<String>(
                                        columnIndex,
                                        ascending,
                                        (p) => testo(p['corso_nome']),
                                      );
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Data'),
                                    onSort: (columnIndex, ascending) {
                                      ordina<String>(
                                        columnIndex,
                                        ascending,
                                        (p) => testo(p['data']),
                                      );
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Prot.'),
                                    onSort: (columnIndex, ascending) {
                                      ordina<String>(
                                        columnIndex,
                                        ascending,
                                        (p) => testo(p['prot']),
                                      );
                                    },
                                  ),
                                  DataColumn(
                                    label: const Text('Stato'),
                                    onSort: (columnIndex, ascending) {
                                      ordina<String>(
                                        columnIndex,
                                        ascending,
                                        statoPrenotazione,
                                      );
                                    },
                                  ),
                                  const DataColumn(
                                    label: Text('Azioni'),
                                  ),
                                ],
                                rows: prenotazioniVisibili.map((p) {
                                  return DataRow(
  color: WidgetStateProperty.resolveWith<Color?>(
    (states) {
      final stato = statoPrenotazione(p);

      if (stato == 'Chiuso') {
        return Colors.grey.shade100;
      }

      if (stato == 'Registro') {
        return Colors.orange.shade50;
      }

      if (stato == 'Aperto') {
        return Colors.green.shade50;
      }

      return null;
    },
  ),
                                    cells: [
                                      DataCell(
                                        Text(nomeDiscente(p)),
                                      ),
                                      DataCell(
                                        Text(testo(p['impresa_nome'])),
                                      ),
                                      DataCell(
                                        Text(testo(p['corso_nome'])),
                                      ),
                                      DataCell(
                                        Text(testo(p['data'])),
                                      ),
                                      DataCell(
                                        Text(testo(p['prot'])),
                                      ),
                                      DataCell(
                                        TableStatusBadge(
                                          status: statoPrenotazione(p),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              tooltip: 'Modifica',
                                              onPressed: () =>
                                                  modificaPrenotazione(p),
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Elimina',
                                              onPressed: () =>
                                                  eliminaPrenotazione(p),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
        ),
      ],
    );
  }
}