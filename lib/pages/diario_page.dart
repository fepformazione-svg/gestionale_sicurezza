import 'package:flutter/material.dart';

import '../database/database_service.dart';
import 'discente_scheda_page.dart';

import '../models/discente.dart';
import '../models/impresa.dart';

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
        color: colore.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colore.withOpacity(0.45)),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Future<bool> apriDialogModificaDiscente(Discente discente) async {
    final imprese = await DatabaseService.instance.getImprese();

    final nomeController = TextEditingController(text: discente.nome);
    final cognomeController = TextEditingController(text: discente.cognome);
    final luogoController = TextEditingController(text: discente.luogoNascita ?? '');
    final dataController = TextEditingController(text: discente.dataNascita ?? '');
    final cfController = TextEditingController(text: discente.codiceFiscale ?? '');
    final dataVisitaController = TextEditingController(
      text: discente.dataVisitaMedica ?? '',
    );
    final scadenzaVisitaController = TextEditingController(
      text: discente.scadenzaVisitaMedica ?? '',
    );

    bool visitaMedicaSvolta = discente.visitaMedicaSvolta == 1;
    int? impresaId = discente.impresaId;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica discente'),
              content: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cognomeController,
                              decoration: _inputDecoration('Cognome *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: nomeController,
                              decoration: _inputDecoration('Nome *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: luogoController,
                              decoration: _inputDecoration('Luogo nascita'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: dataController,
                              decoration: _inputDecoration('Data nascita'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cfController,
                        decoration: _inputDecoration('Codice fiscale'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: impresaId,
                        decoration: _inputDecoration('Impresa'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Nessuna impresa'),
                          ),
                          ...imprese.map(
                            (impresa) => DropdownMenuItem<int?>(
                              value: impresa.id,
                              child: Text(impresa.nome),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            impresaId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: visitaMedicaSvolta,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visita medica svolta'),
                        onChanged: (value) {
                          setDialogState(() {
                            visitaMedicaSvolta = value ?? false;
                          });
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dataVisitaController,
                              decoration: _inputDecoration('Data visita'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: scadenzaVisitaController,
                              decoration: _inputDecoration('Scadenza visita'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                  onPressed: () async {
                    final nome = nomeController.text.trim();
                    final cognome = cognomeController.text.trim();

                    if (nome.isEmpty || cognome.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nome e cognome sono obbligatori'),
                        ),
                      );
                      return;
                    }

                    final aggiornato = Discente(
                      id: discente.id,
                      nome: nome,
                      cognome: cognome,
                      luogoNascita: luogoController.text.trim(),
                      dataNascita: dataController.text.trim(),
                      codiceFiscale: cfController.text.trim(),
                      impresaId: impresaId,
                      visitaMedicaSvolta: visitaMedicaSvolta ? 1 : 0,
                      dataVisitaMedica: dataVisitaController.text.trim(),
                      scadenzaVisitaMedica: scadenzaVisitaController.text.trim(),
                    );

                    await DatabaseService.instance.updateDiscente(aggiornato);

                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    cognomeController.dispose();
    luogoController.dispose();
    dataController.dispose();
    cfController.dispose();
    dataVisitaController.dispose();
    scadenzaVisitaController.dispose();

    return salvato == true;
  }

  Future<void> apriSchedaDiscente(
    Map<String, dynamic> riga,
  ) async {
    final idDiscente = riga['discente_id'];

    if (idDiscente == null) return;

    final discente =
        await DatabaseService.instance.getDiscenteById(
          idDiscente,
        );

    if (discente == null) return;
    if (!mounted) return;

    final risultato = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscenteSchedaPage(
          discente: discente,
        ),
      ),
    );

    if (risultato == 'modifica') {
      final salvato = await apriDialogModificaDiscente(discente);

      if (salvato) {
        await caricaDiario();
      }

      return;
    }

    if (risultato == true) {
      await caricaDiario();
    }

    if (risultato == true || risultato == 'modifica') {
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
            const SizedBox(height: 20),
            Expanded(
              child: _caricamento
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
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
                              const DataColumn(label: Text('↻')),
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
                                        '${testo(riga['cognome'])} ${testo(riga['nome'])}'.trim(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(testo(riga['impresa']))),
                                  DataCell(Text(testo(riga['corso']))),
                                  DataCell(Text(formattaData(riga['data']))),
                                  DataCell(Text(formattaData(riga['scadenza']))),
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
                                        final discenteId = riga['discente_id'];
                                        final impresaId = riga['impresa_id'];
                                        final corsoId = riga['corso_id'];

                                        if (discenteId == null || impresaId == null || corsoId == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Impossibile rinnovare: discente, impresa o corso mancanti.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        await DatabaseService.instance.rinnovaCorso(
                                          idDiscente: discenteId as int,
                                          idImpresa: impresaId as int,
                                          idCorso: corsoId as int,
                                        );

                                        await caricaDiario();

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Rinnovo creato correttamente.'),
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
