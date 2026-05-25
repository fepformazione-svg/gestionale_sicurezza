import 'package:flutter/material.dart';

import '../database/database_service.dart';

class DiarioPage extends StatefulWidget {
  final bool soloDaFatturare;

  const DiarioPage({
    super.key,
    this.soloDaFatturare = false,
  });

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

  setState(() {
  _diario = _soloDaFatturare
      ? dati.where((riga) => riga['da_fatturare'] == 1).toList()
      : dati;

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
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
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

  const DataColumn(
    label: Text('Data corso'),
  ),

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

  const DataColumn(
    label: Text('Stato'),
  ),

  const DataColumn(
    label: Text('Prot.'),
  ),

  const DataColumn(
    label: Text('Da fatturare'),
  ),

  const DataColumn(
    label: Text('Fattura'),
  ),

  const DataColumn(
    label: Text('PDF'),
  ),

  const DataColumn(
    label: Text('Rinnovo'),
  ),
],
                          rows: _diario.map((riga) {
                            final stato = statoScadenza(
                              riga['scadenza']?.toString(),
                            );

                            return DataRow(
                              cells: [
                                DataCell(Text('${testo(riga['cognome'])} ${testo(riga['nome'])}'.trim())),
                                DataCell(Text(testo(riga['impresa']))),
                                DataCell(Text(testo(riga['corso']))),
                                DataCell(Text(formattaData(riga['data']))),
                                DataCell(Text(formattaData(riga['scadenza']))),
                                DataCell(badge(stato)),
                                DataCell(Text(testo(riga['prot']))),
                                DataCell(
                                 Checkbox(
                                  value: riga['da_fatturare'] == 1,
                                  onChanged: (valore) async {
                                    await DatabaseService.instance.aggiornaDaFatturareDiario(
                                      id: riga['id'] as int,
                                      valore: valore ?? false,
                                    );

                                    await caricaDiario();                                 
                                  },
                                ),
                               ),
                                DataCell(Text(testo(riga['fattura']))),
                                DataCell(
                                  Icon(
                                    riga['percorso_pdf'] != null &&
                                            riga['percorso_pdf']
                                                .toString()
                                                .isNotEmpty
                                        ? Icons.picture_as_pdf
                                        : Icons.picture_as_pdf_outlined,
                                    color: riga['percorso_pdf'] != null &&
                                            riga['percorso_pdf']
                                                .toString()
                                                .isNotEmpty
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                const DataCell(
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.blueGrey,
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