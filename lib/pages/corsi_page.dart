import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/corso.dart';
import '../services/database_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class CorsiPage extends StatefulWidget {
  const CorsiPage({super.key});

  @override
  State<CorsiPage> createState() => _CorsiPageState();
}

class _CorsiPageState extends State<CorsiPage> {
  List<Corso> corsi = [];
  List<Corso> corsiFiltrati = [];

  bool loading = true;
  String ricercaCorrente = '';

  @override
  void initState() {
    super.initState();
    caricaCorsi();
  }

  Future<void> caricaCorsi() async {
    final dati = await DatabaseService.instance.getCorsi();

    setState(() {
      corsi = dati;
      corsiFiltrati = dati;
      loading = false;
    });
  }

  void cercaCorsi(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      ricercaCorrente = valore.trim();

      corsiFiltrati = corsi.where((c) {
        return c.denominazione.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> esportaExcelCorsi() async {
    if (corsiFiltrati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun corso da esportare'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Corsi'];

    excel.delete('Sheet1');

    final ora = DateTime.now();
    final dataOraLeggibile = DateFormat('dd/MM/yyyy HH:mm').format(ora);
    final timestampFile = DateFormat('yyyy_MM_dd_HH\'h\'mm').format(ora);

    final vistaFiltrata = ricercaCorrente.trim().isNotEmpty;

    final nomeFile = vistaFiltrata
        ? 'corsi_export_filtrato_$timestampFile.xlsx'
        : 'corsi_export_$timestampFile.xlsx';

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xls.TextCellValue(
      vistaFiltrata
          ? 'Export corsi filtrato - ${corsiFiltrati.length} record - $dataOraLeggibile'
          : 'Export corsi completo - ${corsiFiltrati.length} record - $dataOraLeggibile',
    );

    final intestazioni = ['Denominazione', 'Durata ore', 'Validità anni'];

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      final cella = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 1),
      );

      cella.value = xls.TextCellValue(intestazioni[colonna]);
      cella.cellStyle = xls.CellStyle(bold: true);
    }

    for (var indice = 0; indice < corsiFiltrati.length; indice++) {
      final corso = corsiFiltrati[indice];
      final riga = indice + 2;

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: riga))
          .value = xls.TextCellValue(
        corso.denominazione,
      );

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: riga))
          .value = xls.IntCellValue(
        corso.durataOre,
      );

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: riga))
          .value = xls.IntCellValue(
        corso.validitaAnni,
      );
    }

    sheet.setColumnWidth(0, 48);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 18);

    final directory = await getApplicationDocumentsDirectory();

    final exportDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}Export',
    );

    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final bytes = excel.encode();

    if (bytes == null) return;

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$nomeFile',
    );

    await file.writeAsBytes(bytes, flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export Excel completato: ${corsiFiltrati.length} corsi esportati dalla vista filtrata'
              : 'Export Excel completato: ${corsiFiltrati.length} corsi esportati',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> esportaPdfCorsi() async {
    if (corsiFiltrati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun corso da esportare in PDF'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final pdf = pw.Document();

    final ora = DateTime.now();
    final dataOraLeggibile = DateFormat('dd/MM/yyyy HH:mm').format(ora);
    final timestampFile = DateFormat('yyyy_MM_dd_HH\'h\'mm').format(ora);

    final vistaFiltrata = ricercaCorrente.trim().isNotEmpty;

    final nomeFile = vistaFiltrata
        ? 'corsi_export_filtrato_$timestampFile.pdf'
        : 'corsi_export_$timestampFile.pdf';

    final titoloInfo = vistaFiltrata
        ? 'Export corsi filtrato - ${corsiFiltrati.length} record - $dataOraLeggibile'
        : 'Export corsi completo - ${corsiFiltrati.length} record - $dataOraLeggibile';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            pw.Text(
              'F&P Formazione e Prevenzione',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              'CORSI',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Text(
              titoloInfo,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),

            pw.SizedBox(height: 18),

            pw.TableHelper.fromTextArray(
              headers: const ['Denominazione', 'Durata ore', 'Validità anni'],
              data: corsiFiltrati.map((corso) {
                return [
                  corso.denominazione,
                  corso.durataOre.toString(),
                  corso.validitaAnni.toString(),
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey900,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.blueGrey100,
                    width: 0.5,
                  ),
                ),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(5),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.6),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final exportDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}Export',
    );

    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$nomeFile',
    );

    await file.writeAsBytes(await pdf.save(), flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export PDF completato: ${corsiFiltrati.length} corsi esportati dalla vista filtrata'
              : 'Export PDF completato: ${corsiFiltrati.length} corsi esportati',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> stampaCorsi() async {
    if (corsiFiltrati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun corso da stampare'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final ora = DateTime.now();
    final dataOraLeggibile = DateFormat('dd/MM/yyyy HH:mm').format(ora);
    final vistaFiltrata = ricercaCorrente.trim().isNotEmpty;

    final titoloInfo = vistaFiltrata
        ? 'Stampa corsi filtrata - ${corsiFiltrati.length} record - $dataOraLeggibile'
        : 'Stampa corsi completa - ${corsiFiltrati.length} record - $dataOraLeggibile';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            pw.Text(
              'F&P Formazione e Prevenzione',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              'CORSI',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Text(
              titoloInfo,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),

            pw.SizedBox(height: 18),

            pw.TableHelper.fromTextArray(
              headers: const ['Denominazione', 'Durata ore', 'Validità anni'],
              data: corsiFiltrati.map((corso) {
                return [
                  corso.denominazione,
                  corso.durataOre.toString(),
                  corso.validitaAnni.toString(),
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey900,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.blueGrey100,
                    width: 0.5,
                  ),
                ),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(5),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.6),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Stampa corsi avviata: ${corsiFiltrati.length} corsi dalla vista filtrata'
              : 'Stampa corsi avviata: ${corsiFiltrati.length} corsi',
        ),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Future<void> apriDialogNuovoCorso() async {
    final nomeController = TextEditingController();
    final durataController = TextEditingController();
    final validitaController = TextEditingController();

    final risultato = await showDialog<Corso>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuovo corso',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Inserisci i dati del corso.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Denominazione corso',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durataController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Durata ore',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: TextField(
                        controller: validitaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Validità anni',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),

                    const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        final nome = nomeController.text.trim();

                        if (nome.isEmpty) return;

                        final durata =
                            int.tryParse(durataController.text.trim()) ?? 0;

                        final validita =
                            int.tryParse(validitaController.text.trim()) ?? 0;

                        Navigator.pop(
                          context,
                          Corso(
                            denominazione: nome,
                            durataOre: durata,
                            validitaAnni: validita,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Salva corso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    nomeController.dispose();
    durataController.dispose();
    validitaController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance.insertCorso(risultato);

    await caricaCorsi();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Corso salvato nel database')));
  }

  @override
  Widget build(BuildContext context) {
    final exportDisabilitato = loading || corsiFiltrati.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Corsi',
            subtitle: 'Archivio corsi, formazione e configurazioni didattiche.',
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: 'Cerca corso...',
                  onChanged: cercaCorsi,
                ),
              ),

              const SizedBox(width: 16),

              Tooltip(
                message: exportDisabilitato
                    ? 'Nessun corso da esportare'
                    : 'Esporta ${corsiFiltrati.length} corsi in Excel',
                child: ElevatedButton.icon(
                  onPressed: exportDisabilitato ? null : esportaExcelCorsi,
                  icon: const Icon(Icons.table_view_rounded),
                  label: Text('Export Excel (${corsiFiltrati.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF94A3B8),
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
              ),

              const SizedBox(width: 16),

              Tooltip(
                message: exportDisabilitato
                    ? 'Nessun corso da esportare in PDF'
                    : 'Esporta ${corsiFiltrati.length} corsi in PDF',
                child: ElevatedButton.icon(
                  onPressed: exportDisabilitato ? null : esportaPdfCorsi,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text('Export PDF (${corsiFiltrati.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF94A3B8),
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
              ),

              const SizedBox(width: 16),

              Tooltip(
                message: exportDisabilitato
                    ? 'Nessun corso da stampare'
                    : 'Stampa ${corsiFiltrati.length} corsi',
                child: ElevatedButton.icon(
                  onPressed: exportDisabilitato ? null : stampaCorsi,
                  icon: const Icon(Icons.print_rounded),
                  label: Text('Stampa (${corsiFiltrati.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF475569),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF94A3B8),
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
              ),

              const SizedBox(width: 16),

              ElevatedButton.icon(
                onPressed: apriDialogNuovoCorso,
                icon: const Icon(Icons.add),
                label: const Text('Nuovo corso'),
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
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Elenco corsi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),

                            Text(
                              '${corsiFiltrati.length} record',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Expanded(
                          child: corsiFiltrati.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nessun corso presente',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: corsiFiltrati.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = corsiFiltrati[index];

                                    return Container(
                                      height: 72,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.school_outlined,
                                            color: Color(0xFF2563EB),
                                          ),

                                          const SizedBox(width: 14),

                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.denominazione,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xFF111827),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),

                                                const SizedBox(height: 4),

                                                Text(
                                                  'Durata: ${item.durataOre} h • Validità: ${item.validitaAnni} anni',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
