import 'package:flutter/material.dart';

import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/pdf_azienda_helper.dart';
import 'package:printing/printing.dart';

import '../models/ente_attestato.dart';
import '../services/app_database.dart';

class EntiAttestatiPage extends StatefulWidget {
  const EntiAttestatiPage({super.key});

  @override
  State<EntiAttestatiPage> createState() => _EntiAttestatiPageState();
}

class _EntiAttestatiPageState extends State<EntiAttestatiPage> {
  List<EnteAttestato> entiAttestati = [];
  bool caricamento = true;

  final TextEditingController ricercaController = TextEditingController();
  String ricerca = '';
  bool soloAttivi = true;

  List<EnteAttestato> get entiFiltrati {
    final testo = ricerca.trim().toLowerCase();

    return entiAttestati.where((ente) {
      if (soloAttivi && ente.attivo != 1) {
        return false;
      }

      if (testo.isEmpty) {
        return true;
      }

      final valori = [
        ente.denominazione,
        ente.tipo,
        ente.codiceAccreditamento,
        ente.referente,
        ente.telefono,
        ente.email,
        ente.pec,
        ente.indirizzo,
        ente.comune,
        ente.note,
      ].map((v) => (v ?? '').toLowerCase()).join(' ');

      return valori.contains(testo);
    }).toList();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    caricaEntiAttestati();
  }

  Future<void> caricaEntiAttestati() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getEntiAttestati();

    if (!mounted) return;

    setState(() {
      entiAttestati = dati;
      caricamento = false;
    });
  }

  Future<void> cambiaStatoEnte(EnteAttestato ente) async {
    final nuovoStato = ente.attivo == 1 ? 0 : 1;

    await AppDatabase.instance.aggiornaStatoEnteAttestato(
      id: ente.id!,
      attivo: nuovoStato,
    );

    await caricaEntiAttestati();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuovoStato == 1
              ? 'Ente rilascio attestati riattivato correttamente.'
              : 'Ente rilascio attestati disattivato correttamente.',
        ),
        backgroundColor: nuovoStato == 1 ? Colors.green : Colors.grey,
      ),
    );
  }

  Future<void> mostraDialogEnte({EnteAttestato? ente}) async {
    final formKey = GlobalKey<FormState>();
    final inModifica = ente != null;

    final denominazioneController = TextEditingController(
      text: ente?.denominazione ?? '',
    );
    final tipoController = TextEditingController(text: ente?.tipo ?? 'Ente');
    final codiceAccreditamentoController = TextEditingController(
      text: ente?.codiceAccreditamento ?? '',
    );
    final referenteController = TextEditingController(
      text: ente?.referente ?? '',
    );
    final telefonoController = TextEditingController(
      text: ente?.telefono ?? '',
    );
    final emailController = TextEditingController(text: ente?.email ?? '');
    final pecController = TextEditingController(text: ente?.pec ?? '');
    final indirizzoController = TextEditingController(
      text: ente?.indirizzo ?? '',
    );
    final comuneController = TextEditingController(text: ente?.comune ?? '');
    final noteController = TextEditingController(text: ente?.note ?? '');

    bool attivo = ente?.attivo == 1 || ente == null;

    String? valoreOpzionale(TextEditingController controller) {
      final valore = controller.text.trim();
      return valore.isEmpty ? null : valore;
    }

    try {
      final confermato = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.account_balance),
                    const SizedBox(width: 8),
                    Text(
                      inModifica
                          ? 'Modifica ente attestati'
                          : 'Nuova voce ente attestati',
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 680,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: denominazioneController,
                            decoration: const InputDecoration(
                              labelText: 'Denominazione *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Inserisci la denominazione';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: tipoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                    hintText: 'Es. Ente, Organismo, Regione',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: codiceAccreditamentoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Codice accreditamento',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: referenteController,
                            decoration: const InputDecoration(
                              labelText: 'Referente',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: telefonoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefono',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: pecController,
                            decoration: const InputDecoration(
                              labelText: 'PEC',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: indirizzoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Indirizzo',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: comuneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Comune',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Voce attiva'),
                            value: attivo,
                            onChanged: (value) {
                              setDialogState(() {
                                attivo = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annulla'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(true);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Salva'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confermato != true) return;

      if (inModifica) {
        await AppDatabase.instance.aggiornaEnteAttestato(
          id: ente.id!,
          denominazione: denominazioneController.text.trim(),
          tipo: tipoController.text.trim().isEmpty
              ? 'Ente'
              : tipoController.text.trim(),
          codiceAccreditamento: valoreOpzionale(codiceAccreditamentoController),
          referente: valoreOpzionale(referenteController),
          telefono: valoreOpzionale(telefonoController),
          email: valoreOpzionale(emailController),
          pec: valoreOpzionale(pecController),
          indirizzo: valoreOpzionale(indirizzoController),
          comune: valoreOpzionale(comuneController),
          note: valoreOpzionale(noteController),
          attivo: attivo ? 1 : 0,
        );
      } else {
        await AppDatabase.instance.inserisciEnteAttestato(
          denominazione: denominazioneController.text.trim(),
          tipo: tipoController.text.trim().isEmpty
              ? 'Ente'
              : tipoController.text.trim(),
          codiceAccreditamento: valoreOpzionale(codiceAccreditamentoController),
          referente: valoreOpzionale(referenteController),
          telefono: valoreOpzionale(telefonoController),
          email: valoreOpzionale(emailController),
          pec: valoreOpzionale(pecController),
          indirizzo: valoreOpzionale(indirizzoController),
          comune: valoreOpzionale(comuneController),
          note: valoreOpzionale(noteController),
          attivo: attivo ? 1 : 0,
        );
      }

      await caricaEntiAttestati();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inModifica
                ? 'Ente rilascio attestati aggiornato correttamente.'
                : 'Ente rilascio attestati salvato correttamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      denominazioneController.dispose();
      tipoController.dispose();
      codiceAccreditamentoController.dispose();
      referenteController.dispose();
      telefonoController.dispose();
      emailController.dispose();
      pecController.dispose();
      indirizzoController.dispose();
      comuneController.dispose();
      noteController.dispose();
    }
  }

  Future<void> esportaExcelEntiAttestati() async {
    final entiDaEsportare = entiFiltrati;

    if (entiDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun ente da esportare.')),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Enti attestati'];

    excel.delete('Sheet1');

    final ora = DateTime.now();
    final dataOra = DateFormat('dd/MM/yyyy HH:mm').format(ora);

    final filtroAttivi = soloAttivi ? 'Solo attivi' : 'Tutti';
    final ricercaAttiva = ricerca.trim().isNotEmpty
        ? ' - Ricerca: "${ricerca.trim()}"'
        : '';

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xls.TextCellValue(
      'Export enti attestati - $filtroAttivi$ricercaAttiva - '
      '${entiDaEsportare.length} record - $dataOra',
    );

    final intestazioni = [
      'Denominazione',
      'Tipo',
      'Codice accreditamento',
      'Referente',
      'Telefono',
      'Email',
      'PEC',
      'Indirizzo',
      'Comune',
      'Stato',
      'Note',
    ];

    final stileIntestazione = xls.CellStyle(bold: true);

    for (var i = 0; i < intestazioni.length; i++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );

      cell.value = xls.TextCellValue(intestazioni[i]);
      cell.cellStyle = stileIntestazione;
    }

    for (var i = 0; i < entiDaEsportare.length; i++) {
      final ente = entiDaEsportare[i];
      final rowIndex = i + 2;

      final valori = [
        ente.denominazione,
        ente.tipo,
        ente.codiceAccreditamento,
        ente.referente,
        ente.telefono,
        ente.email,
        ente.pec,
        ente.indirizzo,
        ente.comune,
        ente.attivo == 1 ? 'Attivo' : 'Non attivo',
        ente.note,
      ];

      for (var colIndex = 0; colIndex < valori.length; colIndex++) {
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = xls.TextCellValue(
          valori[colIndex] ?? '',
        );
      }
    }

    sheet.setColumnWidth(0, 24); // Denominazione
    sheet.setColumnWidth(1, 12); // Tipo
    sheet.setColumnWidth(2, 20); // Codice accreditamento
    sheet.setColumnWidth(3, 18); // Referente
    sheet.setColumnWidth(4, 14); // Telefono
    sheet.setColumnWidth(5, 28); // Email
    sheet.setColumnWidth(6, 28); // PEC
    sheet.setColumnWidth(7, 26); // Indirizzo
    sheet.setColumnWidth(8, 18); // Comune
    sheet.setColumnWidth(9, 12); // Stato
    sheet.setColumnWidth(10, 32); // Note

    final directory = await getApplicationDocumentsDirectory();

    final nomeFileData = DateFormat('yyyy_MM_dd_HHmm').format(ora);
    final nomeFile = ricerca.trim().isNotEmpty || !soloAttivi
        ? 'enti_attestati_export_filtrato_$nomeFileData.xlsx'
        : 'enti_attestati_export_$nomeFileData.xlsx';

    final file = File('${directory.path}${Platform.pathSeparator}$nomeFile');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Errore durante la generazione del file Excel.');
    }

    await file.writeAsBytes(bytes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export Excel creato correttamente: ${entiDaEsportare.length} '
          '${entiDaEsportare.length == 1 ? 'ente' : 'enti'}.',
        ),
        backgroundColor: Colors.green,
      ),
    );

    await OpenFile.open(file.path);
  }

  Future<void> esportaPdfEntiAttestati() async {
    final entiDaEsportare = entiFiltrati;

    if (entiDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun ente da esportare in PDF.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final now = DateTime.now();
    final dataGenerazione = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final filtroAttivo = soloAttivi ? 'Solo attivi' : 'Tutti';
    final ricercaAttiva = ricerca.trim().isEmpty ? 'Nessuna' : ricerca.trim();

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
            intestazioneAziendaPdfWidget(intestazionePdf),
            pw.SizedBox(height: 12),

            pw.Text(
              'ENTI RILASCIO ATTESTATI',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Text(
              'Filtro: $filtroAttivo | Ricerca: $ricercaAttiva | '
              'Record esportati: ${entiDaEsportare.length} | '
              'Generato il: $dataGenerazione',
              style: const pw.TextStyle(fontSize: 10),
            ),

            pw.SizedBox(height: 14),

            pw.TableHelper.fromTextArray(
              headers: const [
                'Denominazione',
                'Tipo',
                'Codice accr.',
                'Referente',
                'Telefono',
                'Email',
                'PEC',
                'Comune',
                'Stato',
                'Note',
              ],
              data: entiDaEsportare.map((ente) {
                return [
                  ente.denominazione,
                  ente.tipo,
                  ente.codiceAccreditamento,
                  ente.referente,
                  ente.telefono,
                  ente.email,
                  ente.pec,
                  ente.comune,
                  ente.attivo == 1 ? 'Attivo' : 'Non attivo',
                  ente.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 8,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.8),
                6: const pw.FlexColumnWidth(1.6),
                7: const pw.FlexColumnWidth(1.1),
                8: const pw.FlexColumnWidth(0.9),
                9: const pw.FlexColumnWidth(1.8),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final suffixFiltro = ricerca.trim().isEmpty && soloAttivi
        ? ''
        : '_filtrato';

    final nomeFile =
        'enti_attestati_export_pdf$suffixFiltro'
        '_${DateFormat('yyyy_MM_dd_HHmm').format(now)}.pdf';

    final file = File('${directory.path}/$nomeFile');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF Enti rilascio attestati esportato: ${entiDaEsportare.length} '
          '${entiDaEsportare.length == 1 ? 'record' : 'record'}.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> stampaEntiAttestati() async {
    final entiDaStampare = entiFiltrati;

    if (entiDaStampare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun ente da stampare.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final now = DateTime.now();
    final dataGenerazione = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final filtroAttivo = soloAttivi ? 'Solo attivi' : 'Tutti';
    final ricercaAttiva = ricerca.trim().isEmpty ? 'Nessuna' : ricerca.trim();

    final pdf = pw.Document();

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
            intestazioneAziendaPdfWidget(intestazionePdf),
            pw.SizedBox(height: 12),

            pw.Text(
              'ENTI RILASCIO ATTESTATI',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Text(
              'Filtro: $filtroAttivo | Ricerca: $ricercaAttiva | '
              'Record stampati: ${entiDaStampare.length} | '
              'Generato il: $dataGenerazione',
              style: const pw.TextStyle(fontSize: 10),
            ),

            pw.SizedBox(height: 14),

            pw.TableHelper.fromTextArray(
              headers: const [
                'Denominazione',
                'Tipo',
                'Codice accr.',
                'Referente',
                'Telefono',
                'Email',
                'PEC',
                'Comune',
                'Stato',
                'Note',
              ],
              data: entiDaStampare.map((ente) {
                return [
                  ente.denominazione,
                  ente.tipo,
                  ente.codiceAccreditamento,
                  ente.referente,
                  ente.telefono,
                  ente.email,
                  ente.pec,
                  ente.comune,
                  ente.attivo == 1 ? 'Attivo' : 'Non attivo',
                  ente.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 8,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.8),
                6: const pw.FlexColumnWidth(1.6),
                7: const pw.FlexColumnWidth(1.1),
                8: const pw.FlexColumnWidth(0.9),
                9: const pw.FlexColumnWidth(1.8),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stampa Enti rilascio attestati avviata: '
          '${entiDaStampare.length} record.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enti rilascio attestati'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => mostraDialogEnte(),
              icon: const Icon(Icons.add),
              label: const Text('Nuova voce'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, size: 32),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 190,
                      child: Text(
                        ricerca.trim().isEmpty
                            ? soloAttivi
                                  ? '${entiFiltrati.length} enti attivi'
                                  : '${entiFiltrati.length} enti presenti'
                            : '${entiFiltrati.length} enti trovati',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: const Text('Solo attivi'),
                      selected: soloAttivi,
                      onSelected: (_) {
                        setState(() {
                          soloAttivi = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Tutti'),
                      selected: !soloAttivi,
                      onSelected: (_) {
                        setState(() {
                          soloAttivi = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: entiFiltrati.isEmpty
                          ? null
                          : esportaExcelEntiAttestati,
                      icon: const Icon(Icons.table_chart),
                      label: Text('Excel (${entiFiltrati.length})'),
                    ),
                    const SizedBox(width: 8),

                    ElevatedButton.icon(
                      onPressed: entiFiltrati.isEmpty
                          ? null
                          : esportaPdfEntiAttestati,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text('PDF (${entiFiltrati.length})'),
                    ),
                    const SizedBox(width: 8),

                    ElevatedButton.icon(
                      onPressed: entiFiltrati.isEmpty
                          ? null
                          : stampaEntiAttestati,
                      icon: const Icon(Icons.print),
                      label: Text('Stampa (${entiFiltrati.length})'),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: TextField(
                        controller: ricercaController,
                        decoration: InputDecoration(
                          labelText: 'Cerca ente rilascio attestati',
                          hintText:
                              'Cerca per denominazione, tipo, codice, referente, email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: ricerca.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Svuota ricerca',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    ricercaController.clear();
                                    setState(() {
                                      ricerca = '';
                                    });
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (valore) {
                          setState(() {
                            ricerca = valore;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Aggiorna elenco',
                      onPressed: caricaEntiAttestati,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: caricamento
                  ? const Center(child: CircularProgressIndicator())
                  : entiFiltrati.isEmpty
                  ? Center(
                      child: Text(
                        ricerca.trim().isEmpty
                            ? 'Nessun ente rilascio attestati presente.'
                            : 'Nessun ente trovato con la ricerca corrente.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 28,
                            horizontalMargin: 28,
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text('Denominazione')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Codice accreditamento')),
                              DataColumn(label: Text('Referente')),
                              DataColumn(label: Text('Telefono')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Stato')),
                              DataColumn(label: Text('Azioni')),
                            ],
                            rows: entiFiltrati.map((ente) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 230,
                                      child: Text(
                                        ente.denominazione,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        ente.tipo,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 145,
                                      child: Text(
                                        ente.codiceAccreditamento ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        ente.referente ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 125,
                                      child: Text(
                                        ente.telefono ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 190,
                                      child: Text(
                                        ente.email ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 82,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: ente.attivo == 1
                                            ? Colors.green[100]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        ente.attivo == 1
                                            ? 'ATTIVO'
                                            : 'NON ATT.',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: ente.attivo == 1
                                              ? Colors.green[800]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip:
                                                'Modifica ente rilascio attestati',
                                            onPressed: () =>
                                                mostraDialogEnte(ente: ente),
                                            icon: const Icon(Icons.edit),
                                          ),
                                          IconButton(
                                            tooltip: ente.attivo == 1
                                                ? 'Disattiva ente rilascio attestati'
                                                : 'Riattiva ente rilascio attestati',
                                            onPressed: () =>
                                                cambiaStatoEnte(ente),
                                            icon: Icon(
                                              ente.attivo == 1
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
