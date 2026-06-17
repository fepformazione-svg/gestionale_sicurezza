import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/pdf_azienda_helper.dart';

import 'impresa_scheda_page.dart';

import '../models/impresa.dart';
import '../services/database_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class ImpresePage extends StatefulWidget {
  const ImpresePage({super.key});

  @override
  State<ImpresePage> createState() => _ImpresePageState();
}

class _ImpresePageState extends State<ImpresePage> {
  List<Impresa> imprese = [];
  List<Impresa> impreseFiltrate = [];

  String ricercaAttiva = '';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    caricaImprese();
  }

  Future<void> caricaImprese() async {
    final dati = await DatabaseService.instance.getImprese();

    setState(() {
      imprese = dati;
      impreseFiltrate = dati;
      loading = false;
    });
  }

  void cercaImprese(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      ricercaAttiva = valore.trim();

      impreseFiltrate = imprese.where((i) {
        return i.intestazione.toLowerCase().contains(query) ||
            (i.partitaIva ?? '').toLowerCase().contains(query) ||
            (i.codiceFiscale ?? '').toLowerCase().contains(query) ||
            (i.telefono ?? '').toLowerCase().contains(query) ||
            (i.referente ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> esportaExcelImprese() async {
    if (impreseFiltrate.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna impresa da esportare'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Imprese'];

    excel.delete('Sheet1');

    final ora = DateTime.now();
    final vistaFiltrata = ricercaAttiva.trim().isNotEmpty;

    final dataOra =
        '${ora.day.toString().padLeft(2, '0')}/'
        '${ora.month.toString().padLeft(2, '0')}/'
        '${ora.year} '
        '${ora.hour.toString().padLeft(2, '0')}:'
        '${ora.minute.toString().padLeft(2, '0')}';

    final infoExport = vistaFiltrata
        ? 'Export imprese filtrato - ${impreseFiltrate.length} record - $dataOra'
        : 'Export imprese - ${impreseFiltrate.length} record - $dataOra';

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xls.TextCellValue(
      infoExport,
    );

    final intestazioni = [
      'Ragione sociale',
      'Partita IVA',
      'Codice fiscale',
      'Indirizzo',
      'Telefono',
      'Referente',
    ];

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      final cella = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 2),
      );

      cella.value = xls.TextCellValue(intestazioni[colonna]);
      cella.cellStyle = xls.CellStyle(bold: true);
    }

    for (var indice = 0; indice < impreseFiltrate.length; indice++) {
      final impresa = impreseFiltrate[indice];
      final riga = indice + 3;

      final valori = [
        impresa.intestazione,
        impresa.partitaIva ?? '',
        impresa.codiceFiscale ?? '',
        impresa.indirizzo ?? '',
        impresa.telefono ?? '',
        impresa.referente ?? '',
      ];

      for (var colonna = 0; colonna < valori.length; colonna++) {
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: colonna,
                rowIndex: riga,
              ),
            )
            .value = xls.TextCellValue(
          valori[colonna],
        );
      }
    }

    sheet.setColumnWidth(0, 38);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 38);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 28);

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'imprese_export${vistaFiltrata ? '_filtrato' : ''}_'
        '${ora.year}_'
        '${ora.month.toString().padLeft(2, '0')}_'
        '${ora.day.toString().padLeft(2, '0')}_'
        '${ora.hour.toString().padLeft(2, '0')}'
        '${ora.minute.toString().padLeft(2, '0')}.xlsx';

    final file = File('${directory.path}/$nomeFile');

    final bytes = excel.save();

    if (bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la creazione del file Excel'),
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
          vistaFiltrata
              ? 'Export Excel completato: ${impreseFiltrate.length} imprese esportate dalla vista filtrata'
              : 'Export Excel completato: ${impreseFiltrate.length} imprese esportate',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> esportaPdfImprese() async {
    if (impreseFiltrate.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna impresa da esportare'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final pdf = pw.Document();
    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();
    final ora = DateTime.now();
    final vistaFiltrata = ricercaAttiva.trim().isNotEmpty;

    final dataOra =
        '${ora.day.toString().padLeft(2, '0')}/'
        '${ora.month.toString().padLeft(2, '0')}/'
        '${ora.year} '
        '${ora.hour.toString().padLeft(2, '0')}:'
        '${ora.minute.toString().padLeft(2, '0')}';

    final infoExport = vistaFiltrata
        ? 'Export imprese filtrato - ${impreseFiltrate.length} record - $dataOra'
        : 'Export imprese - ${impreseFiltrate.length} record - $dataOra';

    final datiTabella = impreseFiltrate.map((impresa) {
      return [
        impresa.intestazione,
        impresa.partitaIva ?? '',
        impresa.codiceFiscale ?? '',
        impresa.indirizzo ?? '',
        impresa.telefono ?? '',
        impresa.referente ?? '',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
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
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 8),
            pw.Text(
              'IMPRESE',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              infoExport,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Ragione sociale',
                'Partita IVA',
                'Codice fiscale',
                'Indirizzo',
                'Telefono',
                'Referente',
              ],
              data: datiTabella,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey900,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              border: pw.TableBorder.all(
                color: PdfColors.blueGrey200,
                width: 0.4,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(2.4),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(1.4),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'imprese_export${vistaFiltrata ? '_filtrato' : ''}_'
        '${ora.year}_'
        '${ora.month.toString().padLeft(2, '0')}_'
        '${ora.day.toString().padLeft(2, '0')}_'
        '${ora.hour.toString().padLeft(2, '0')}'
        '${ora.minute.toString().padLeft(2, '0')}.pdf';

    final file = File('${directory.path}/$nomeFile');

    await file.writeAsBytes(await pdf.save(), flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export PDF completato: ${impreseFiltrate.length} imprese esportate dalla vista filtrata'
              : 'Export PDF completato: ${impreseFiltrate.length} imprese esportate',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> stampaImprese() async {
    if (impreseFiltrate.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna impresa da stampare'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final ora = DateTime.now();
    final vistaFiltrata = ricercaAttiva.trim().isNotEmpty;

    final dataOra =
        '${ora.day.toString().padLeft(2, '0')}/'
        '${ora.month.toString().padLeft(2, '0')}/'
        '${ora.year} '
        '${ora.hour.toString().padLeft(2, '0')}:'
        '${ora.minute.toString().padLeft(2, '0')}';

    final infoExport = vistaFiltrata
        ? 'Stampa imprese filtrata - ${impreseFiltrate.length} record - $dataOra'
        : 'Stampa imprese - ${impreseFiltrate.length} record - $dataOra';

    final datiTabella = impreseFiltrate.map((impresa) {
      return [
        impresa.intestazione,
        impresa.partitaIva ?? '',
        impresa.codiceFiscale ?? '',
        impresa.indirizzo ?? '',
        impresa.telefono ?? '',
        impresa.referente ?? '',
      ];
    }).toList();

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
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 8),
            pw.Text(
              'IMPRESE',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              infoExport,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Ragione sociale',
                'Partita IVA',
                'Codice fiscale',
                'Indirizzo',
                'Telefono',
                'Referente',
              ],
              data: datiTabella,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey900,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              border: pw.TableBorder.all(
                color: PdfColors.blueGrey200,
                width: 0.4,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(2.4),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(1.4),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> apriDialogNuovaImpresa() async {
    final ragioneSocialeController = TextEditingController();
    final partitaIvaController = TextEditingController();
    final codiceFiscaleController = TextEditingController();
    final indirizzoController = TextEditingController();
    final telefonoController = TextEditingController();
    final referenteController = TextEditingController();

    final risultato = await showDialog<Impresa>(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nuova impresa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Inserisci i dati dell’impresa.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: ragioneSocialeController,
                    decoration: InputDecoration(
                      labelText: 'Ragione sociale *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: partitaIvaController,
                    decoration: InputDecoration(
                      labelText: 'Partita IVA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: codiceFiscaleController,
                    decoration: InputDecoration(
                      labelText: 'Codice fiscale',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: indirizzoController,
                    decoration: InputDecoration(
                      labelText: 'Indirizzo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(
                      labelText: 'Telefono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: referenteController,
                    decoration: InputDecoration(
                      labelText: 'Referente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
                          final nome = ragioneSocialeController.text.trim();

                          if (nome.isEmpty) return;

                          Navigator.pop(
                            context,
                            Impresa(
                              intestazione: nome,
                              partitaIva: partitaIvaController.text.trim(),
                              codiceFiscale: codiceFiscaleController.text
                                  .trim(),
                              indirizzo: indirizzoController.text.trim(),
                              telefono: telefonoController.text.trim(),
                              referente: referenteController.text.trim(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Salva impresa'),
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
          ),
        );
      },
    );

    ragioneSocialeController.dispose();
    partitaIvaController.dispose();
    codiceFiscaleController.dispose();
    indirizzoController.dispose();
    telefonoController.dispose();
    referenteController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance.insertImpresa(risultato);
    await caricaImprese();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impresa salvata nel database')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Imprese',
            subtitle: 'Archivio aziende, clienti e anagrafiche operative.',
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: 'Cerca impresa...',
                  onChanged: cercaImprese,
                ),
              ),

              const SizedBox(width: 16),

              OutlinedButton.icon(
                onPressed: impreseFiltrate.isEmpty ? null : esportaExcelImprese,
                icon: const Icon(Icons.table_chart_outlined),
                label: Text('Export Excel (${impreseFiltrate.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              OutlinedButton.icon(
                onPressed: impreseFiltrate.isEmpty ? null : esportaPdfImprese,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text('PDF (${impreseFiltrate.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              OutlinedButton.icon(
                onPressed: impreseFiltrate.isEmpty ? null : stampaImprese,
                icon: const Icon(Icons.print_outlined),
                label: Text('Stampa (${impreseFiltrate.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: apriDialogNuovaImpresa,
                icon: const Icon(Icons.add),
                label: const Text('Nuova impresa'),
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
                                'Elenco imprese',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),

                            Text(
                              '${impreseFiltrate.length} record',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Expanded(
                          child: impreseFiltrate.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nessuna impresa presente',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: impreseFiltrate.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = impreseFiltrate[index];

                                    return InkWell(
                                      onDoubleTap: () async {
                                        final risultato = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ImpresaSchedaPage(
                                              impresa: item,
                                            ),
                                          ),
                                        );

                                        if (risultato == 'eliminata') {
                                          await caricaImprese();
                                        }

                                        if (risultato == 'modifica') {
                                          await apriDialogModificaImpresa(item);
                                          await caricaImprese();
                                        }
                                      },
                                      child: Container(
                                        height: 72,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.business_outlined,
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
                                                    item.intestazione,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Color(0xFF111827),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 4),

                                                  Text(
                                                    [
                                                      if ((item.partitaIva ??
                                                              '')
                                                          .isNotEmpty)
                                                        'P.IVA: ${item.partitaIva}',
                                                      if ((item.codiceFiscale ??
                                                              '')
                                                          .isNotEmpty)
                                                        'CF: ${item.codiceFiscale}',
                                                      if ((item.telefono ?? '')
                                                          .isNotEmpty)
                                                        'Tel: ${item.telefono}',
                                                    ].join('   •   '),
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

  Future<void> apriDialogModificaImpresa(Impresa impresa) async {
    final ragioneSocialeController = TextEditingController(
      text: impresa.intestazione,
    );
    final partitaIvaController = TextEditingController(
      text: impresa.partitaIva ?? '',
    );
    final codiceFiscaleController = TextEditingController(
      text: impresa.codiceFiscale ?? '',
    );
    final indirizzoController = TextEditingController(
      text: impresa.indirizzo ?? '',
    );
    final telefonoController = TextEditingController(
      text: impresa.telefono ?? '',
    );
    final referenteController = TextEditingController(
      text: impresa.referente ?? '',
    );

    final risultato = await showDialog<Impresa>(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modifica impresa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Aggiorna i dati dell’impresa.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: ragioneSocialeController,
                    decoration: InputDecoration(
                      labelText: 'Ragione sociale *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: partitaIvaController,
                    decoration: InputDecoration(
                      labelText: 'Partita IVA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: codiceFiscaleController,
                    decoration: InputDecoration(
                      labelText: 'Codice fiscale',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: indirizzoController,
                    decoration: InputDecoration(
                      labelText: 'Indirizzo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(
                      labelText: 'Telefono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: referenteController,
                    decoration: InputDecoration(
                      labelText: 'Referente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
                          final nome = ragioneSocialeController.text.trim();

                          if (nome.isEmpty) return;

                          Navigator.pop(
                            context,
                            Impresa(
                              id: impresa.id,
                              intestazione: nome,
                              partitaIva: partitaIvaController.text.trim(),
                              codiceFiscale: codiceFiscaleController.text
                                  .trim(),
                              indirizzo: indirizzoController.text.trim(),
                              telefono: telefonoController.text.trim(),
                              referente: referenteController.text.trim(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Salva modifiche'),
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
          ),
        );
      },
    );

    ragioneSocialeController.dispose();
    partitaIvaController.dispose();
    codiceFiscaleController.dispose();
    indirizzoController.dispose();
    telefonoController.dispose();
    referenteController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance.updateImpresa(risultato);
    await caricaImprese();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impresa modificata correttamente')),
    );
  }
}
