import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../dialogs/discente_dialog.dart';
import 'discente_scheda_page.dart';

class DiarioPage extends StatefulWidget {
  final bool soloDaFatturare;

  const DiarioPage({super.key, this.soloDaFatturare = false});

  @override
  State<DiarioPage> createState() => _DiarioPageState();
}

class _DiarioPageState extends State<DiarioPage> {
  final TextEditingController _cercaController = TextEditingController();

  List<Map<String, dynamic>> _diario = [];
  bool _caricamento = true;
  bool _soloDaFatturare = false;

  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _soloDaFatturare = widget.soloDaFatturare;
    caricaDiario();
  }

  Future<void> caricaDiario() async {
    setState(() => _caricamento = true);

    final dati = await DatabaseService.instance.caricaDiario(
      ricerca: _cercaController.text.trim(),
    );

    final ricerca = _cercaController.text.trim().toLowerCase();

    final datiFiltrati = ricerca.isEmpty
        ? dati
        : dati.where((riga) {
            final discente = '${testo(riga['cognome'])} ${testo(riga['nome'])}'
                .toLowerCase();
            final impresa = testo(riga['impresa']).toLowerCase();
            final corso = testo(riga['corso']).toLowerCase();
            final prot = testo(riga['prot']).toLowerCase();
            final data = testo(riga['data']).toLowerCase();
            final scadenza = testo(riga['scadenza']).toLowerCase();

            return discente.contains(ricerca) ||
                impresa.contains(ricerca) ||
                corso.contains(ricerca) ||
                prot.contains(ricerca) ||
                data.contains(ricerca) ||
                scadenza.contains(ricerca);
          }).toList();

    if (!mounted) return;

    setState(() {
      _diario = _soloDaFatturare
          ? datiFiltrati.where((riga) => riga['da_fatturare'] == 1).toList()
          : datiFiltrati;

      _caricamento = false;
    });
  }

  void ordina<T>(
    Comparable<T> Function(Map<String, dynamic> riga) getField,
    int columnIndex,
    bool ascending,
  ) {
    _diario.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);

      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  String statoScadenza(String? dataScadenza) {
    if (dataScadenza == null || dataScadenza.isEmpty) {
      return 'N/D';
    }

    final oggi = DateTime.now();
    final scadenza = DateTime.tryParse(dataScadenza);

    if (scadenza == null) return 'N/D';

    final giorni = scadenza.difference(oggi).inDays;

    if (giorni < 0) return 'SCADUTO';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDO';
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'SCADUTO':
        return Colors.red;
      case 'IN SCADENZA':
        return Colors.orange;
      case 'VALIDO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget badge(String testo) {
    final colore = coloreStato(testo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colore.withValues(alpha: 0.45)),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: colore,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String testo(dynamic valore) {
    if (valore == null) return '';
    return valore.toString();
  }

  String formattaData(dynamic valore) {
    if (valore == null || valore.toString().trim().isEmpty) return '-';

    final testoData = valore.toString().trim();

    try {
      DateTime? data;

      if (testoData.contains('/')) {
        final parti = testoData.split('/');
        if (parti.length == 3) {
          data = DateTime(
            int.parse(parti[2]),
            int.parse(parti[1]),
            int.parse(parti[0]),
          );
        }
      } else {
        data = DateTime.tryParse(testoData);
      }

      if (data == null) return testoData;

      final giorno = data.day.toString().padLeft(2, '0');
      final mese = data.month.toString().padLeft(2, '0');
      final anno = data.year.toString();

      return '$giorno/$mese/$anno';
    } catch (_) {
      return testoData;
    }
  }

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  Future<void> apriSchedaDiscente(Map<String, dynamic> riga) async {
    final idDiscente = riga['discente_id'];

    if (idDiscente == null) return;

    final discente = await DatabaseService.instance.getDiscenteById(idDiscente);

    if (discente == null) return;
    if (!mounted) return;

    final risultato = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscenteSchedaPage(discente: discente)),
    );

    if (!mounted) return;

    if (risultato == 'modifica') {
      final salvato = await apriDialogDiscente(
        context: context,
        discente: discente,
      );

      if (salvato) {
        await caricaDiario();
      }

      return;
    }

    if (risultato == true) {
      await caricaDiario();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DIARIO CORSI',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _cercaController,
              onChanged: (_) => caricaDiario(),
              decoration: InputDecoration(
                hintText: 'Cerca discente, impresa, corso, protocollo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _cercaController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Azzera ricerca',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cercaController.clear();
                          caricaDiario();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                if (_cercaController.text.trim().isNotEmpty)
                  Tooltip(
                    message: 'Clicca per azzerare la ricerca',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        _cercaController.clear();
                        caricaDiario();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.manage_search_rounded,
                              size: 15,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ricerca attiva: ${_cercaController.text.trim()}',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _cercaController.text.trim().isNotEmpty
                            ? _diario.length == 1
                                  ? '1 corso trovato'
                                  : '${_diario.length} corsi trovati'
                            : _diario.length == 1
                            ? '1 corso visualizzato'
                            : '${_diario.length} corsi visualizzati',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _caricamento
                  ? const Center(child: CircularProgressIndicator())
                  : _diario.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 52,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _cercaController.text.trim().isNotEmpty
                                  ? 'Nessun corso trovato'
                                  : 'Nessun corso presente nel diario',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            if (_cercaController.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Prova a modificare o azzerare la ricerca.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _cercaController.clear();
                                  caricaDiario();
                                },
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                label: const Text('Azzera ricerca'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _sortAscending,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade100,
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: const Text('Discente'),
                                      onSort: (columnIndex, ascending) {
                                        ordina<String>(
                                          (riga) =>
                                              '${testo(riga['cognome'])} ${testo(riga['nome'])}',
                                          columnIndex,
                                          ascending,
                                        );
                                      },
                                    ),
                                    DataColumn(
                                      label: const Text('Impresa'),
                                      onSort: (columnIndex, ascending) {
                                        ordina<String>(
                                          (riga) => testo(riga['impresa']),
                                          columnIndex,
                                          ascending,
                                        );
                                      },
                                    ),
                                    DataColumn(
                                      label: const Text('Corso'),
                                      onSort: (columnIndex, ascending) {
                                        ordina<String>(
                                          (riga) => testo(riga['corso']),
                                          columnIndex,
                                          ascending,
                                        );
                                      },
                                    ),
                                    const DataColumn(label: Text('Data corso')),
                                    DataColumn(
                                      label: const Text('Scadenza'),
                                      onSort: (columnIndex, ascending) {
                                        ordina<String>(
                                          (riga) => testo(riga['scadenza']),
                                          columnIndex,
                                          ascending,
                                        );
                                      },
                                    ),
                                    const DataColumn(label: Text('Stato')),
                                    const DataColumn(label: Text('Prot.')),
                                    const DataColumn(
                                      label: Tooltip(
                                        message: 'Rinnova corso',
                                        child: SizedBox(
                                          width: 32,
                                          child: Center(
                                            child: Icon(
                                              Icons.refresh_rounded,
                                              size: 22,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: _diario.map((riga) {
                                    final stato = statoScadenza(
                                      riga['scadenza']?.toString(),
                                    );

                                    return DataRow(
                                      onSelectChanged: (_) {
                                        apriSchedaDiscente(riga);
                                      },
                                      cells: [
                                        DataCell(
                                          InkWell(
                                            onTap: () {
                                              apriSchedaDiscente(riga);
                                            },
                                            child: Text(
                                              '${testo(riga['cognome'])} ${testo(riga['nome'])}'
                                                  .trim(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(testo(riga['impresa']))),
                                        DataCell(Text(testo(riga['corso']))),
                                        DataCell(
                                          Text(formattaData(riga['data'])),
                                        ),
                                        DataCell(
                                          Text(formattaData(riga['scadenza'])),
                                        ),
                                        DataCell(badge(stato)),
                                        DataCell(Text(testo(riga['prot']))),
                                        DataCell(
                                          IconButton(
                                            tooltip: 'Rinnova corso',
                                            icon: const Icon(
                                              Icons.refresh,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed: () async {
                                              final confermato = await showDialog<bool>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (dialogContext) {
                                                  return AlertDialog(
                                                    title: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons.refresh_rounded,
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          'Conferma rinnovo corso',
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      'Vuoi creare un nuovo rinnovo per il corso '
                                                      '"${testo(riga['corso'])}" di '
                                                      '${testo(riga['cognome'])} ${testo(riga['nome'])}?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(false);
                                                        },
                                                        child: const Text(
                                                          'Annulla',
                                                        ),
                                                      ),
                                                      FilledButton.icon(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(true);
                                                        },
                                                        icon: const Icon(
                                                          Icons.refresh_rounded,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          'Rinnova',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (!mounted) return;
                                              if (confermato != true) return;

                                              final discenteId =
                                                  riga['discente_id'];
                                              final impresaId =
                                                  riga['impresa_id'];
                                              final corsoId = riga['corso_id'];

                                              if (discenteId == null ||
                                                  impresaId == null ||
                                                  corsoId == null) {
                                                ScaffoldMessenger.of(
                                                  this.context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Impossibile rinnovare: discente, impresa o corso mancanti.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              await DatabaseService.instance
                                                  .rinnovaCorso(
                                                    idDiscente:
                                                        discenteId as int,
                                                    idImpresa: impresaId as int,
                                                    idCorso: corsoId as int,
                                                  );

                                              await caricaDiario();

                                              if (!mounted) return;

                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Rinnovo creato correttamente.',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
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
