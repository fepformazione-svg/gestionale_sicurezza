import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/prenotazione_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/table_status_badge.dart';

import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> prenotazioni = [];
  List<Map<String, dynamic>> prenotazioniFiltrate = [];

  final int righePerPaginaDb = 50;
  int paginaDbCorrente = 0;
  bool fineArchivioPrenotazioni = false;
  bool caricamentoPaginaDb = false;

  int paginaCorrente = 0;
  final int righePerPagina = 10;

  String filtroLocale = '';

  List<Map<String, dynamic>> get prenotazioniVisibili {
  final filtroAttivo = filtroLocale.isNotEmpty ? filtroLocale : widget.filtro;

  return prenotazioniFiltrate.where((p) {
    final stato = statoPrenotazione(p);

    if (filtroAttivo == 'aperte') return stato == 'Aperto';
    if (filtroAttivo == 'registro') return stato == 'Registro';
    if (filtroAttivo == 'chiuse') return stato == 'Chiuso';
    if (filtroAttivo == 'da_fare') return stato == 'Da fare';

    return true;
  }).toList();
}

List<Map<String, dynamic>> get prenotazioniPaginata {
  final start = paginaCorrente * righePerPagina;
  final end = start + righePerPagina;

  if (start >= prenotazioniVisibili.length) {
    return [];
  }

  return prenotazioniVisibili.sublist(
  start,
  end > prenotazioniVisibili.length
      ? prenotazioniVisibili.length
      : end,
);
}

Future<void> caricaPrenotazioniIniziali() async {
  setState(() {
    loading = true;
    caricamentoPaginaDb = true;
    paginaDbCorrente = 0;
    fineArchivioPrenotazioni = false;

    prenotazioni.clear();
    prenotazioniFiltrate.clear();
  });

  try {
    final dati = await DatabaseService.instance.getPrenotazioniPaged(
      limit: righePerPaginaDb,
      offset: 0,
    );

    setState(() {
      prenotazioni = dati;
      prenotazioniFiltrate = dati;

      paginaDbCorrente = 1;

      if (dati.length < righePerPaginaDb) {
        fineArchivioPrenotazioni = true;
      }
    });
  } catch (e) {
    debugPrint('ERRORE caricaPrenotazioniIniziali: $e');
  } finally {
    setState(() {
      loading = false;
      caricamentoPaginaDb = false;
    });
  }
}

bool loading = true;

  int? sortColumnIndex;
  bool sortAscending = true;

  @override
void initState() {
  super.initState();

  caricaPrenotazioniIniziali();

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      caricaAltrePrenotazioni();
    }
  });
}

Future<void> caricaAltrePrenotazioni() async {
  if (caricamentoPaginaDb || fineArchivioPrenotazioni) return;

  setState(() {
    caricamentoPaginaDb = true;
  });

  final dati = await DatabaseService.instance.getPrenotazioniPaged(
    limit: righePerPaginaDb,
    offset: paginaDbCorrente * righePerPaginaDb,
  );

  setState(() {
    prenotazioni.addAll(dati);
    prenotazioniFiltrate = prenotazioni;

    paginaDbCorrente++;

    caricamentoPaginaDb = false;

    if (dati.length < righePerPaginaDb) {
      fineArchivioPrenotazioni = true;
    }
  });
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
  setState(() {
    loading = true;
    paginaDbCorrente = 0;
    fineArchivioPrenotazioni = false;
    prenotazioni = [];
    prenotazioniFiltrate = [];
  });

  await caricaPaginaPrenotazioni(reset: true);
}

Future<void> caricaPaginaPrenotazioni({bool reset = false}) async {
  if (caricamentoPaginaDb || fineArchivioPrenotazioni) return;

  setState(() {
    caricamentoPaginaDb = true;
  });

  try {
    final offset = paginaDbCorrente * righePerPaginaDb;

    final dati = await DatabaseService.instance.getPrenotazioniPaged(
      limit: righePerPaginaDb,
      offset: offset,
    );

    setState(() {
      if (reset) {
        prenotazioni.clear();
      }

      prenotazioni.addAll(dati);
      prenotazioniFiltrate = List.from(prenotazioni);

      paginaDbCorrente++;

      if (dati.length < righePerPaginaDb) {
        fineArchivioPrenotazioni = true;
      }

      caricamentoPaginaDb = false;
      loading = false;
    });

    if (widget.globalSearch.trim().isNotEmpty) {
      cercaPrenotazioni(widget.globalSearch);
    }
  } catch (e) {
    setState(() {
      caricamentoPaginaDb = false;
      loading = false;
    });

    debugPrint('Errore caricamento prenotazioni paged: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore caricamento prenotazioni: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
Widget filtroChip({
  required String titolo,
  required String filtro,
  required Color colore,
}) {
  final attivo =
    (filtroLocale.isNotEmpty
        ? filtroLocale
        : widget.filtro) == filtro;

  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
  setState(() {
    filtroLocale = filtro;
    paginaCorrente = 0;
  });
},
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: attivo ? colore.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: attivo ? colore : Colors.grey.shade300,
          width: attivo ? 1.8 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colore,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titolo,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: attivo ? colore : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    ),
  );
}
Widget compactKpiCard({
  required String titolo,
  required String valore,
  required Color colore,
  required String filtro,
}) {
  final attivo =
      (filtroLocale.isNotEmpty
          ? filtroLocale
          : widget.filtro) == filtro;

  return InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () {
      setState(() {
        filtroLocale = filtro;
        paginaCorrente = 0;
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: attivo
              ? colore
              : Colors.grey.shade300,
          width: attivo ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colore,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            valore,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colore,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            titolo,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
Future<void> exportPrenotazioniExcel() async {
  final excel = Excel.createExcel();

  final sheet = excel['Prenotazioni'];

  // HEADER
  sheet.appendRow([
    TextCellValue('Discente'),
    TextCellValue('Impresa'),
    TextCellValue('Corso'),
    TextCellValue('Data'),
    TextCellValue('Protocollo'),
    TextCellValue('Stato'),
  ]);

  // DATI
  for (final p in prenotazioniVisibili) {
    sheet.appendRow([
      TextCellValue(nomeDiscente(p)),
      TextCellValue(testo(p['impresa_nome'])),
      TextCellValue(testo(p['corso_nome'])),
      TextCellValue(testo(p['data'])),
      TextCellValue(testo(p['prot'])),
      TextCellValue(statoPrenotazione(p)),
    ]);
  }

  final directory = await getApplicationDocumentsDirectory();

  final path =
      '${directory.path}/prenotazioni_export.xlsx';

  final fileBytes = excel.encode();

  if (fileBytes == null) return;

  final file = File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes);

  await OpenFile.open(file.path);
}
Future<void> esportaPdf() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Text(
          'PRENOTAZIONI',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Table.fromTextArray(
          headers: [
            'Discente',
            'Impresa',
            'Corso',
            'Data',
            'Prot.',
            'Stato',
          ],

          data: prenotazioniVisibili.map((p) {
            return [
              nomeDiscente(p),
              testo(p['impresa_nome']),
              testo(p['corso_nome']),
              testo(p['data']),
              testo(p['prot']),
              statoPrenotazione(p),
            ];
          }).toList(),
        ),
      ],
    ),
  );

  final directory = await getApplicationDocumentsDirectory();

  final file = File(
    '${directory.path}/prenotazioni.pdf',
  );

  await file.writeAsBytes(
    await pdf.save(),
  );

  await OpenFile.open(file.path);
}
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

final ultraWide = width > 1800;
final desktop = width > 1400;
final tablet = width < 1100;
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
  onPressed: exportPrenotazioniExcel,
  icon: const Icon(Icons.table_view_outlined),
  label: const Text('Export Excel'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF2563EB),
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 18,
    ),
    shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
  side: BorderSide(
    color: Colors.grey.shade300,
  ),
),
    elevation: 0,
  ),
),

const SizedBox(width: 12),

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
                      Wrap(
  spacing: 14,
  runSpacing: 10,
  children: [

    compactKpiCard(
      titolo: 'Totale',
      valore: prenotazioniFiltrate.length.toString(),
      colore: const Color(0xFF2563EB),
      filtro: '',
    ),

    compactKpiCard(
      titolo: 'Aperte',
      valore: prenotazioniFiltrate
          .where((p) => statoPrenotazione(p) == 'Aperto')
          .length
          .toString(),
      colore: Colors.green,
      filtro: 'aperte',
    ),

    compactKpiCard(
      titolo: 'Registro',
      valore: prenotazioniFiltrate
          .where((p) => statoPrenotazione(p) == 'Registro')
          .length
          .toString(),
      colore: Colors.orange,
      filtro: 'registro',
    ),

    compactKpiCard(
      titolo: 'Chiuse',
      valore: prenotazioniFiltrate
          .where((p) => statoPrenotazione(p) == 'Chiuso')
          .length
          .toString(),
      colore: Colors.grey,
      filtro: 'chiuse',
    ),

    compactKpiCard(
      titolo: 'Da fare',
      valore: prenotazioniFiltrate
          .where((p) => statoPrenotazione(p) == 'Da fare')
          .length
          .toString(),
      colore: Colors.red,
      filtro: 'da_fare',
    ),
  ],
),

const SizedBox(height: 12),
Wrap(
  spacing: 10,
  runSpacing: 10,
  children: [
    filtroChip(
      titolo: 'Tutte (${prenotazioniFiltrate.length})',
      filtro: '',
      colore: Colors.blue,
    ),

    filtroChip(
      titolo: 'Aperte (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Aperto').length})',
      filtro: 'aperte',
      colore: Colors.green,
    ),

    filtroChip(
      titolo: 'Registro (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Registro').length})',
      filtro: 'registro',
      colore: Colors.orange,
    ),

    filtroChip(
      titolo: 'Chiuse (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Chiuso').length})',
      filtro: 'chiuse',
      colore: Colors.grey,
    ),

    filtroChip(
      titolo: 'Da fare (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Da fare').length})',
      filtro: 'da_fare',
      colore: Colors.red,
    ),
  ],
),

const SizedBox(height: 10),
                      Expanded(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: ultraWide
              ? MediaQuery.of(context).size.width - 320
              : desktop
                  ? MediaQuery.of(context).size.width - 280
                  : 1100,
          child: Column(
            children: [
              DataTable(
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF3F4F6),
                ),
                dataRowMinHeight: 0,
                dataRowMaxHeight: 0,
                columnSpacing: ultraWide
                    ? 42
                    : desktop
                        ? 32
                        : tablet
                            ? 18
                            : 24,
                horizontalMargin: tablet ? 12 : 20,
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
                rows: const [],
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: DataTable(
                    headingRowHeight: 0,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    columnSpacing: ultraWide
                        ? 42
                        : desktop
                            ? 32
                            : tablet
                                ? 18
                                : 24,
                    horizontalMargin: tablet ? 12 : 20,
                    columns: const [
                      DataColumn(label: SizedBox(width: 150, child: Text('Discente'))),
                      DataColumn(label: SizedBox(width: 130, child: Text('Impresa'))),
                      DataColumn(label: SizedBox(width: 180, child: Text('Corso'))),
                      DataColumn(label: SizedBox(width: 100, child: Text('Data'))),
                      DataColumn(label: SizedBox(width: 80, child: Text('Prot.'))),
                      DataColumn(label: SizedBox(width: 120, child: Text('Stato'))),
                      DataColumn(label: SizedBox(width: 120, child: Text('Azioni'))),
                    ],
                    rows: prenotazioniPaginata.map((p) {
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
  DataCell(SizedBox(width: 150, child: Text(nomeDiscente(p)))),
  DataCell(SizedBox(width: 130, child: Text(testo(p['impresa_nome'])))),
  DataCell(SizedBox(width: 180, child: Text(testo(p['corso_nome'])))),
  DataCell(SizedBox(width: 100, child: Text(testo(p['data'])))),
  DataCell(SizedBox(width: 80, child: Text(testo(p['prot'])))),
  DataCell(
    SizedBox(
      width: 120,
      child: TableStatusBadge(
        status: statoPrenotazione(p),
      ),
    ),
  ),
  DataCell(
    SizedBox(
      width: 120,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Modifica',
            onPressed: () => modificaPrenotazione(p),
            icon: const Icon(
              Icons.edit,
              color: Color(0xFF2563EB),
            ),
          ),
          IconButton(
  tooltip: 'Elimina',
  onPressed: () => eliminaPrenotazione(p),
  icon: const Icon(
    Icons.delete_outline,
    color: Color(0xFFDC2626),
  ),
),
],
      ),
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
  ),
),
                      const SizedBox(height: 10),

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  ),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.grey.shade300,
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      Text(
        'Totale record: ${prenotazioniVisibili.length}',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),

      Row(
        children: [

          IconButton(
            onPressed: paginaCorrente > 0
                ? () {
                    setState(() {
                      paginaCorrente--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Pagina ${paginaCorrente + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed:
                (paginaCorrente + 1) * righePerPagina <
                        prenotazioniVisibili.length
                    ? () {
                        setState(() {
                          paginaCorrente++;
                        });
                      }
                    : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ],
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