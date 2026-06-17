import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/pdf_azienda_helper.dart';

import '../models/prezzario.dart';
import '../services/database_service.dart';

class PrezzarioPage extends StatefulWidget {
  const PrezzarioPage({super.key});

  @override
  State<PrezzarioPage> createState() => _PrezzarioPageState();
}

class _PrezzarioPageState extends State<PrezzarioPage> {
  bool caricamento = true;
  List<Prezzario> vociPrezzario = [];
  List<Map<String, dynamic>> impreseLookup = [];
  List<Map<String, dynamic>> corsiLookup = [];

  final TextEditingController cercaController = TextEditingController();

  List<Prezzario> get vociPrezzarioFiltrate {
    final ricerca = cercaController.text.trim().toLowerCase();

    if (ricerca.isEmpty) {
      return vociPrezzario;
    }

    return vociPrezzario.where((voce) {
      final impresa = (voce.impresa ?? '').toLowerCase();
      final corso = (voce.corso ?? '').toLowerCase();
      final prezzo = formattaPrezzo(voce.prezzo).toLowerCase();
      final note = voce.note.toLowerCase();

      return impresa.contains(ricerca) ||
          corso.contains(ricerca) ||
          prezzo.contains(ricerca) ||
          note.contains(ricerca);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    caricaPrezzario();
  }

  @override
  void dispose() {
    cercaController.dispose();
    super.dispose();
  }

  Future<void> caricaPrezzario() async {
    setState(() {
      caricamento = true;
    });

    final dati = await DatabaseService.instance.getPrezzario();
    final imprese = await DatabaseService.instance.getImpreseLookup();
    final corsi = await DatabaseService.instance.getCorsiLookup();

    if (!mounted) return;

    setState(() {
      vociPrezzario = dati;
      impreseLookup = imprese;
      corsiLookup = corsi;
      caricamento = false;
    });
  }

  String formattaPrezzo(double valore) {
    return '€ ${valore.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> esportaExcelPrezzario() async {
    final vociDaEsportare = vociPrezzarioFiltrate;

    if (vociDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna voce di prezzario da esportare.'),
          backgroundColor: Color(0xFFF97316),
        ),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Prezzario'];

    excel.delete('Sheet1');

    final ricercaAttiva = cercaController.text.trim().isNotEmpty;
    final adesso = DateTime.now();

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final dataOra =
        '${dueCifre(adesso.day)}/${dueCifre(adesso.month)}/${adesso.year} '
        '${dueCifre(adesso.hour)}:${dueCifre(adesso.minute)}';

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xls.TextCellValue(
      ricercaAttiva
          ? 'Export prezzario filtrato - ${vociDaEsportare.length} voci - $dataOra'
          : 'Export prezzario completo - ${vociDaEsportare.length} voci - $dataOra',
    );

    final intestazioni = ['Impresa', 'Corso', 'Prezzo', 'Note'];

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      final cella = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 1),
      );

      cella.value = xls.TextCellValue(intestazioni[colonna]);
      cella.cellStyle = xls.CellStyle(bold: true);
    }

    for (var indice = 0; indice < vociDaEsportare.length; indice++) {
      final voce = vociDaEsportare[indice];
      final riga = indice + 2;

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: riga))
          .value = xls.TextCellValue(
        voce.impresa ?? '-',
      );

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: riga))
          .value = xls.TextCellValue(
        voce.corso ?? '-',
      );

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: riga))
          .value = xls.TextCellValue(
        formattaPrezzo(voce.prezzo),
      );

      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: riga))
          .value = xls.TextCellValue(
        voce.note.isEmpty ? '-' : voce.note,
      );
    }

    sheet.setColumnWidth(0, 36);
    sheet.setColumnWidth(1, 42);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 40);

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'prezzario_export${ricercaAttiva ? '_filtrato' : ''}_'
        '${adesso.year}_${dueCifre(adesso.month)}_${dueCifre(adesso.day)}_'
        '${dueCifre(adesso.hour)}${dueCifre(adesso.minute)}.xlsx';

    final file = File('${directory.path}/$nomeFile');

    final bytes = excel.save();

    if (bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la creazione del file Excel.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    await file.writeAsBytes(bytes, flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ricercaAttiva
              ? 'Export Excel completato: ${vociDaEsportare.length} voci esportate dalla vista filtrata.'
              : 'Export Excel completato: ${vociDaEsportare.length} voci esportate.',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> esportaPdfPrezzario() async {
    final vociDaEsportare = vociPrezzarioFiltrate;

    if (vociDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna voce di prezzario da esportare.'),
          backgroundColor: Color(0xFFF97316),
        ),
      );
      return;
    }

    final ricercaAttiva = cercaController.text.trim().isNotEmpty;
    final adesso = DateTime.now();

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final dataOra =
        '${dueCifre(adesso.day)}/${dueCifre(adesso.month)}/${adesso.year} '
        '${dueCifre(adesso.hour)}:${dueCifre(adesso.minute)}';

    final pdf = pw.Document();

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          );
        },
        build: (context) {
          return [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 8),
            pw.Text(
              'PREZZARIO',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              ricercaAttiva
                  ? 'Export prezzario filtrato - ${vociDaEsportare.length} voci - $dataOra'
                  : 'Export prezzario completo - ${vociDaEsportare.length} voci - $dataOra',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const ['Impresa', 'Corso', 'Prezzo', 'Note'],
              data: vociDaEsportare.map((voce) {
                return [
                  voce.impresa ?? '-',
                  voce.corso ?? '-',
                  'EUR ${voce.prezzo.toStringAsFixed(2).replaceAll('.', ',')}',
                  voce.note.isEmpty ? '-' : voce.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey900,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(3),
              },
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'prezzario_export${ricercaAttiva ? '_filtrato' : ''}_'
        '${adesso.year}_${dueCifre(adesso.month)}_${dueCifre(adesso.day)}_'
        '${dueCifre(adesso.hour)}${dueCifre(adesso.minute)}.pdf';

    final file = File('${directory.path}/$nomeFile');

    await file.writeAsBytes(await pdf.save(), flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ricercaAttiva
              ? 'Export PDF completato: ${vociDaEsportare.length} voci esportate dalla vista filtrata.'
              : 'Export PDF completato: ${vociDaEsportare.length} voci esportate.',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> stampaPrezzario() async {
    final vociDaStampare = vociPrezzarioFiltrate;

    if (vociDaStampare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna voce prezzario da stampare.'),
          backgroundColor: Color(0xFF64748B),
        ),
      );
      return;
    }

    final pdf = pw.Document();

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    final ricercaAttiva = cercaController.text.trim().isNotEmpty;
    final dataStampa = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    String formattaPrezzoPdf(dynamic valore) {
      final numero = valore is num
          ? valore
          : num.tryParse(valore?.toString().replaceAll(',', '.') ?? '') ?? 0;

      return 'EUR ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          intestazioneAziendaPdfWidget(intestazioneAzienda),
          pw.SizedBox(height: 8),
          pw.Text(
            'PREZZARIO',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            ricercaAttiva
                ? 'Stampa filtrata - ${vociDaStampare.length} voci - $dataStampa'
                : 'Stampa completa - ${vociDaStampare.length} voci - $dataStampa',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blueGrey600,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Impresa', 'Corso', 'Prezzo', 'Note'],
            data: vociDaStampare.map((voce) {
              return [
                voce.impresa,
                voce.corso,
                formattaPrezzoPdf(voce.prezzo),
                voce.note,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5),
              ),
            ),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey50,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(3),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> apriDialogNuovaVoce() async {
    final salvato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _NuovaVocePrezzarioDialog(
          impreseLookup: impreseLookup,
          corsiLookup: corsiLookup,
        );
      },
    );

    if (salvato == true) {
      await caricaPrezzario();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voce prezzario salvata.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> apriDialogModificaVoce(Prezzario voce) async {
    final salvato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _ModificaVocePrezzarioDialog(
          voce: voce,
          impreseLookup: impreseLookup,
          corsiLookup: corsiLookup,
        );
      },
    );

    if (salvato == true) {
      await caricaPrezzario();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voce prezzario aggiornata.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> confermaEliminaVoce(Prezzario voce) async {
    if (voce.id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare voce prezzario?'),
          content: Text(
            'Vuoi eliminare la voce per "${voce.impresa ?? '-'}" - "${voce.corso ?? '-'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.deletePrezzario(voce.id!);

    await caricaPrezzario();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voce prezzario eliminata.'),
        backgroundColor: Color(0xFF475569),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.price_change_rounded,
              color: Color(0xFF0F172A),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Prezzario',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: vociPrezzarioFiltrate.isEmpty
                  ? null
                  : esportaExcelPrezzario,
              icon: const Icon(Icons.table_view_rounded, size: 18),
              label: Text('Esporta Excel (${vociPrezzarioFiltrate.length})'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: vociPrezzarioFiltrate.isEmpty
                  ? null
                  : esportaPdfPrezzario,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text('Esporta PDF (${vociPrezzarioFiltrate.length})'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: vociPrezzarioFiltrate.isEmpty ? null : stampaPrezzario,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text('Stampa (${vociPrezzarioFiltrate.length})'),
            ),
            FilledButton.icon(
              onPressed: apriDialogNuovaVoce,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuova voce'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: caricaPrezzario,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Aggiorna'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Prezzi personalizzati per impresa e corso.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
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
                : vociPrezzario.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.price_check_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nessuna voce di prezzario presente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Aggiungeremo inserimento e modifica nel prossimo step.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: cercaController,
                          decoration: InputDecoration(
                            hintText: 'Cerca impresa, corso, prezzo o note...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: cercaController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Azzera ricerca',
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      setState(() {
                                        cercaController.clear();
                                      });
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cercaController.text.trim().isEmpty
                              ? '${vociPrezzario.length} voci di prezzario'
                              : '${vociPrezzarioFiltrate.length} voci trovate',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (vociPrezzarioFiltrate.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 46,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Nessuna voce di prezzario trovata',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
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
                                      setState(() {
                                        cercaController.clear();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Azzera ricerca'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF1F5F9),
                            ),
                            columnSpacing: 18,
                            horizontalMargin: 16,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                            dataTextStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                            columns: const [
                              DataColumn(
                                label: SizedBox(
                                  width: 260,
                                  child: Text('Impresa'),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 300,
                                  child: Text('Corso'),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 95,
                                  child: Center(child: Text('Prezzo')),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 260,
                                  child: Text('Note'),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 95,
                                  child: Center(child: Text('Azioni')),
                                ),
                              ),
                            ],
                            rows: vociPrezzarioFiltrate.map((voce) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 260,
                                      child: Text(
                                        voce.impresa ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 300,
                                      child: Text(
                                        voce.corso ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 95,
                                      child: Center(
                                        child: Text(
                                          formattaPrezzo(voce.prezzo),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 260,
                                      child: Text(
                                        voce.note.isEmpty ? '-' : voce.note,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 95,
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip:
                                                  'Modifica voce prezzario',
                                              icon: const Icon(
                                                Icons.edit_rounded,
                                                size: 18,
                                              ),
                                              color: const Color(0xFF475569),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 34,
                                                minHeight: 34,
                                              ),
                                              onPressed: () {
                                                apriDialogModificaVoce(voce);
                                              },
                                            ),
                                            IconButton(
                                              tooltip: 'Elimina voce prezzario',
                                              icon: const Icon(
                                                Icons.delete_rounded,
                                                size: 18,
                                              ),
                                              color: const Color(0xFFDC2626),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 34,
                                                minHeight: 34,
                                              ),
                                              onPressed: () {
                                                confermaEliminaVoce(voce);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _NuovaVocePrezzarioDialog extends StatefulWidget {
  final List<Map<String, dynamic>> impreseLookup;
  final List<Map<String, dynamic>> corsiLookup;

  const _NuovaVocePrezzarioDialog({
    required this.impreseLookup,
    required this.corsiLookup,
  });

  @override
  State<_NuovaVocePrezzarioDialog> createState() =>
      _NuovaVocePrezzarioDialogState();
}

class _NuovaVocePrezzarioDialogState extends State<_NuovaVocePrezzarioDialog> {
  int? impresaId;
  int? corsoId;
  bool salvataggioInCorso = false;
  String? errore;

  final prezzoController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void dispose() {
    prezzoController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> salvaVoce() async {
    if (salvataggioInCorso) return;

    setState(() {
      errore = null;
    });

    if (impresaId == null || corsoId == null) {
      setState(() {
        errore = 'Seleziona impresa e corso.';
      });
      return;
    }

    final prezzo = double.tryParse(
      prezzoController.text.trim().replaceAll(',', '.'),
    );

    if (prezzo == null || prezzo < 0) {
      setState(() {
        errore = 'Inserisci un prezzo valido.';
      });
      return;
    }

    setState(() {
      salvataggioInCorso = true;
    });

    try {
      final esistente = await DatabaseService.instance
          .getPrezzarioByImpresaCorso(impresaId: impresaId!, corsoId: corsoId!);

      if (!mounted) return;

      if (esistente != null) {
        setState(() {
          errore = 'Esiste già una voce per questa impresa e questo corso.';
          salvataggioInCorso = false;
        });
        return;
      }

      await DatabaseService.instance.insertPrezzario(
        Prezzario(
          impresaId: impresaId!,
          corsoId: corsoId!,
          prezzo: prezzo,
          note: noteController.text.trim(),
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errore = 'Errore durante il salvataggio della voce prezzario.';
        salvataggioInCorso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova voce prezzario'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: impresaId,
              decoration: const InputDecoration(
                labelText: 'Impresa',
                border: OutlineInputBorder(),
              ),
              items: widget.impreseLookup.map((impresa) {
                return DropdownMenuItem<int>(
                  value: impresa['id'] as int,
                  child: Text(
                    (impresa['intestazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        impresaId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: corsoId,
              decoration: const InputDecoration(
                labelText: 'Corso',
                border: OutlineInputBorder(),
              ),
              items: widget.corsiLookup.map((corso) {
                return DropdownMenuItem<int>(
                  value: corso['id'] as int,
                  child: Text(
                    (corso['denominazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        corsoId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prezzoController,
              enabled: !salvataggioInCorso,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Prezzo',
                hintText: 'Es. 120,00',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              enabled: !salvataggioInCorso,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            if (errore != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errore!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvataggioInCorso
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: salvataggioInCorso ? null : salvaVoce,
          icon: salvataggioInCorso
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(salvataggioInCorso ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}

class _ModificaVocePrezzarioDialog extends StatefulWidget {
  final Prezzario voce;
  final List<Map<String, dynamic>> impreseLookup;
  final List<Map<String, dynamic>> corsiLookup;

  const _ModificaVocePrezzarioDialog({
    required this.voce,
    required this.impreseLookup,
    required this.corsiLookup,
  });

  @override
  State<_ModificaVocePrezzarioDialog> createState() =>
      _ModificaVocePrezzarioDialogState();
}

class _ModificaVocePrezzarioDialogState
    extends State<_ModificaVocePrezzarioDialog> {
  late int? impresaId;
  late int? corsoId;
  bool salvataggioInCorso = false;
  String? errore;

  late final TextEditingController prezzoController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    impresaId = widget.voce.impresaId;
    corsoId = widget.voce.corsoId;
    prezzoController = TextEditingController(
      text: widget.voce.prezzo.toStringAsFixed(2).replaceAll('.', ','),
    );
    noteController = TextEditingController(text: widget.voce.note);
  }

  @override
  void dispose() {
    prezzoController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> salvaVoce() async {
    if (salvataggioInCorso) return;

    setState(() {
      errore = null;
    });

    if (impresaId == null || corsoId == null) {
      setState(() {
        errore = 'Seleziona impresa e corso.';
      });
      return;
    }

    final prezzo = double.tryParse(
      prezzoController.text.trim().replaceAll(',', '.'),
    );

    if (prezzo == null || prezzo < 0) {
      setState(() {
        errore = 'Inserisci un prezzo valido.';
      });
      return;
    }

    setState(() {
      salvataggioInCorso = true;
    });

    try {
      final combinazioneCambiata =
          impresaId != widget.voce.impresaId || corsoId != widget.voce.corsoId;

      if (combinazioneCambiata) {
        final esistente = await DatabaseService.instance
            .getPrezzarioByImpresaCorso(
              impresaId: impresaId!,
              corsoId: corsoId!,
            );

        if (!mounted) return;

        if (esistente != null && esistente.id != widget.voce.id) {
          setState(() {
            errore = 'Esiste già una voce per questa impresa e questo corso.';
            salvataggioInCorso = false;
          });
          return;
        }
      }

      await DatabaseService.instance.updatePrezzario(
        widget.voce.copyWith(
          impresaId: impresaId,
          corsoId: corsoId,
          prezzo: prezzo,
          note: noteController.text.trim(),
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errore = 'Errore durante l’aggiornamento della voce prezzario.';
        salvataggioInCorso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica voce prezzario'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: impresaId,
              decoration: const InputDecoration(
                labelText: 'Impresa',
                border: OutlineInputBorder(),
              ),
              items: widget.impreseLookup.map((impresa) {
                return DropdownMenuItem<int>(
                  value: impresa['id'] as int,
                  child: Text(
                    (impresa['intestazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        impresaId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: corsoId,
              decoration: const InputDecoration(
                labelText: 'Corso',
                border: OutlineInputBorder(),
              ),
              items: widget.corsiLookup.map((corso) {
                return DropdownMenuItem<int>(
                  value: corso['id'] as int,
                  child: Text(
                    (corso['denominazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        corsoId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prezzoController,
              enabled: !salvataggioInCorso,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Prezzo',
                hintText: 'Es. 120,00',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              enabled: !salvataggioInCorso,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            if (errore != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errore!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvataggioInCorso
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: salvataggioInCorso ? null : salvaVoce,
          icon: salvataggioInCorso
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(salvataggioInCorso ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}
