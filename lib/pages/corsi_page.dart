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

import '../models/corso.dart';
import '../models/corso_piattaforma.dart';
import '../services/database_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/corso_piattaforme_dialog.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/app_action_button.dart';

class CorsiPage extends StatefulWidget {
  const CorsiPage({super.key});

  @override
  State<CorsiPage> createState() => _CorsiPageState();
}

class _CorsiPageState extends State<CorsiPage> {
  List<Corso> corsi = [];
  List<Corso> corsiFiltrati = [];
  Map<int, List<CorsoPiattaforma>> piattaformePerCorso = {};

  bool loading = true;
  String ricercaCorrente = '';

  @override
  void initState() {
    super.initState();
    caricaCorsi();
  }

  Future<void> caricaCorsi() async {
    final dati = await DatabaseService.instance.getCorsi();
    final collegamenti = await DatabaseService.instance.getCorsoPiattaforme(
      soloAttive: true,
    );

    final raggruppati = <int, List<CorsoPiattaforma>>{};

    for (final collegamento in collegamenti) {
      raggruppati.putIfAbsent(collegamento.corsoId, () => []).add(collegamento);
    }

    if (!mounted) return;

    setState(() {
      corsi = dati;
      piattaformePerCorso = raggruppati;
      corsiFiltrati = filtraCorsi(dati, ricercaCorrente);
      loading = false;
    });
  }

  List<Corso> filtraCorsi(List<Corso> elenco, String valore) {
    final query = valore.toLowerCase().trim();

    if (query.isEmpty) {
      return List<Corso>.from(elenco);
    }

    return elenco.where((corso) {
      if (corso.denominazione.toLowerCase().contains(query)) {
        return true;
      }

      final id = corso.id;

      if (id == null) return false;

      final collegamenti =
          piattaformePerCorso[id] ?? const <CorsoPiattaforma>[];

      return collegamenti.any((collegamento) {
        return collegamento.piattaforma.toLowerCase().contains(query) ||
            collegamento.codice.toLowerCase().contains(query) ||
            (collegamento.note ?? '').toLowerCase().contains(query);
      });
    }).toList();
  }

  void cercaCorsi(String valore) {
    setState(() {
      ricercaCorrente = valore.trim();
      corsiFiltrati = filtraCorsi(corsi, ricercaCorrente);
    });
  }

  List<CorsoPiattaforma> codiciPiattaformaCorso(Corso corso) {
    final id = corso.id;

    if (id == null) {
      return const <CorsoPiattaforma>[];
    }

    return piattaformePerCorso[id] ?? const <CorsoPiattaforma>[];
  }

  int numeroCodiciPiattaforma(Corso corso) {
    return codiciPiattaformaCorso(corso).length;
  }

  String riepilogoCodiciPiattaforma(Corso corso) {
    final codici = codiciPiattaformaCorso(corso);

    if (codici.isEmpty) {
      return 'Nessun codice configurato';
    }

    final voci = codici.take(2).map((collegamento) {
      final stato = collegamento.attivo ? '' : ' (non attivo)';

      return '${collegamento.piattaforma}: '
          '${collegamento.codice}$stato';
    }).toList();

    final rimanenti = codici.length - voci.length;

    if (rimanenti > 0) {
      voci.add('+$rimanenti');
    }

    return voci.join(' | ');
  }

  Future<void> apriDialogCodiciPiattaforma(Corso corso) async {
    if (corso.id == null) return;

    final modificato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CorsoPiattaformeDialog(corso: corso);
      },
    );

    if (modificato == true) {
      await caricaCorsi();
    }
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
    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();
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
            intestazioneAziendaPdfWidget(intestazioneAzienda),
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
    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

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
            intestazioneAziendaPdfWidget(intestazioneAzienda),

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

  Future<void> apriDialogModificaCorso(Corso corso) async {
    final nomeController = TextEditingController(text: corso.denominazione);
    final durataController = TextEditingController(
      text: corso.durataOre.toString(),
    );
    final validitaController = TextEditingController(
      text: corso.validitaAnni.toString(),
    );

    final risultato = await showDialog<Corso>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 680,
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
                  'Modifica corso',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Modifica i dati del corso e gestisci i codici delle piattaforme.',
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

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_outlined, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Piattaforme e codici',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Associa uno o pi? codici utilizzati sulle piattaforme formative.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: corso.id == null
                            ? null
                            : () async {
                                await apriDialogCodiciPiattaforma(corso);
                              },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Gestisci codici'),
                      ),
                    ],
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
                        final nome = nomeController.text.trim();

                        if (nome.isEmpty) return;

                        final durata =
                            int.tryParse(durataController.text.trim()) ?? 0;

                        final validita =
                            int.tryParse(validitaController.text.trim()) ?? 0;

                        Navigator.pop(
                          context,
                          Corso(
                            id: corso.id,
                            denominazione: nome,
                            durataOre: durata,
                            validitaAnni: validita,
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
        );
      },
    );

    nomeController.dispose();
    durataController.dispose();
    validitaController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance.updateCorso(risultato);

    await caricaCorsi();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Corso aggiornato correttamente'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> eliminaCorso(Corso corso) async {
    final id = corso.id;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile eliminare: ID corso mancante'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final collegamenti = await DatabaseService.instance.contaCollegamentiCorso(
      id,
    );

    if (!mounted) return;

    final totaleCollegamenti = collegamenti.values.fold<int>(
      0,
      (totale, valore) => totale + valore,
    );

    if (totaleCollegamenti > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Corso non eliminabile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Il corso "${corso.denominazione}" è collegato ad altri dati '
                  'del gestionale e non può essere eliminato.',
                ),
                const SizedBox(height: 16),
                Text('Prenotazioni: ${collegamenti['prenotazioni'] ?? 0}'),
                Text('Diario: ${collegamenti['diario'] ?? 0}'),
                Text('Scadenze: ${collegamenti['scadenze'] ?? 0}'),
                const SizedBox(height: 16),
                const Text(
                  'Per sicurezza non viene eseguita nessuna eliminazione a cascata.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi'),
              ),
            ],
          );
        },
      );

      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminare il corso?'),
          content: Text(
            'Vuoi eliminare definitivamente il corso "${corso.denominazione}"?\n\n'
            'L’operazione non può essere annullata.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.deleteCorso(id);
    await caricaCorsi();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Corso eliminato: ${corso.denominazione}'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
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
                  hintText: 'Cerca corso, piattaforma o codice...',
                  onChanged: cercaCorsi,
                ),
              ),
              const SizedBox(width: 16),
              Tooltip(
                message: exportDisabilitato
                    ? 'Nessun corso da esportare'
                    : 'Esporta ${corsiFiltrati.length} corsi in Excel',
                child: AppActionButton(
                  type: AppActionButtonType.excel,
                  onPressed: exportDisabilitato ? null : esportaExcelCorsi,
                  label: 'Excel (${corsiFiltrati.length})',
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: exportDisabilitato
                    ? 'Nessun corso da esportare in PDF'
                    : 'Esporta ${corsiFiltrati.length} corsi in PDF',
                child: AppActionButton(
                  type: AppActionButtonType.pdf,
                  onPressed: exportDisabilitato ? null : esportaPdfCorsi,
                  label: 'PDF (${corsiFiltrati.length})',
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: exportDisabilitato
                    ? 'Nessun corso da stampare'
                    : 'Stampa ${corsiFiltrati.length} corsi',
                child: AppActionButton(
                  type: AppActionButtonType.stampa,
                  onPressed: exportDisabilitato ? null : stampaCorsi,
                  label: 'Stampa (${corsiFiltrati.length})',
                ),
              ),
              const SizedBox(width: 12),
              AppActionButton(
                type: AppActionButtonType.nuovo,
                onPressed: apriDialogNuovoCorso,
                label: 'Nuovo corso',
              ),
            ],
          ),
          const SizedBox(height: 24),

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

                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 38),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Corso',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Piattaforme / codici',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              SizedBox(
                                width: 164,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Azioni',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

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
                                    final numeroCodici =
                                        numeroCodiciPiattaforma(item);

                                    return InkWell(
                                      onDoubleTap: () =>
                                          apriDialogModificaCorso(item),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        height: 80,
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
                                              flex: 3,
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                            const SizedBox(width: 12),

                                            Expanded(
                                              flex: 2,
                                              child: Tooltip(
                                                message:
                                                    riepilogoCodiciPiattaforma(
                                                      item,
                                                    ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      riepilogoCodiciPiattaforma(
                                                        item,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: numeroCodici == 0
                                                            ? const Color(
                                                                0xFF9CA3AF,
                                                              )
                                                            : const Color(
                                                                0xFF334155,
                                                              ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      numeroCodici == 1
                                                          ? '1 codice'
                                                          : '$numeroCodici codici',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            Tooltip(
                                              message:
                                                  'Gestisci codici piattaforma',
                                              child: IconButton(
                                                onPressed: () =>
                                                    apriDialogCodiciPiattaforma(
                                                      item,
                                                    ),
                                                icon: const Icon(
                                                  Icons.hub_outlined,
                                                ),
                                                color: const Color(0xFF0F766E),
                                              ),
                                            ),

                                            const SizedBox(width: 4),

                                            Tooltip(
                                              message: 'Modifica corso',
                                              child: IconButton(
                                                onPressed: () =>
                                                    apriDialogModificaCorso(
                                                      item,
                                                    ),
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                ),
                                                color: const Color(0xFF2563EB),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Tooltip(
                                              message: 'Elimina corso',
                                              child: IconButton(
                                                onPressed: () =>
                                                    eliminaCorso(item),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                color: const Color(0xFFDC2626),
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
}
