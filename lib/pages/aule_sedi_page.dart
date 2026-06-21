import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/pdf_azienda_helper.dart';

import 'dart:io';

import '../models/aula_sede.dart';
import '../services/app_database.dart';

class AuleSediPage extends StatefulWidget {
  const AuleSediPage({super.key});

  @override
  State<AuleSediPage> createState() => _AuleSediPageState();
}

class _AuleSediPageState extends State<AuleSediPage> {
  List<AulaSede> auleSedi = [];
  bool caricamento = true;

  final cercaController = TextEditingController();
  bool soloAttive = true;

  @override
  void initState() {
    super.initState();
    caricaAuleSedi();
  }

  @override
  void dispose() {
    cercaController.dispose();
    super.dispose();
  }

  Future<void> caricaAuleSedi() async {
    setState(() => caricamento = true);

    final dati = await AppDatabase.instance.getAuleSedi();

    if (!mounted) return;

    setState(() {
      auleSedi = dati;
      caricamento = false;
    });
  }

  List<AulaSede> get auleSediFiltrate {
    final ricerca = cercaController.text.trim().toLowerCase();

    final filtratePerStato = soloAttive
        ? auleSedi.where((aulaSede) => aulaSede.attiva).toList()
        : auleSedi;

    if (ricerca.isEmpty) return filtratePerStato;

    return filtratePerStato.where((aulaSede) {
      final stato = aulaSede.attiva ? 'attiva' : 'non attiva';
      final capienza = aulaSede.capienza?.toString() ?? '';

      final testo = [
        aulaSede.denominazione,
        aulaSede.tipo,
        aulaSede.indirizzo,
        aulaSede.comune,
        capienza,
        aulaSede.note,
        stato,
      ].join(' ').toLowerCase();

      return testo.contains(ricerca);
    }).toList();
  }

  Future<void> apriDialogNuovaAulaSede() async {
    final formKey = GlobalKey<FormState>();

    final denominazioneController = TextEditingController();
    final indirizzoController = TextEditingController();
    final comuneController = TextEditingController();
    final capienzaController = TextEditingController();
    final noteController = TextEditingController();

    String tipoSelezionato = 'Aula';
    bool attiva = true;

    final salvata = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova aula / sede formativa'),
              content: SizedBox(
                width: 520,
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
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSelezionato,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Aula',
                              child: Text('Aula'),
                            ),
                            DropdownMenuItem(
                              value: 'Campo prove',
                              child: Text('Campo prove'),
                            ),
                            DropdownMenuItem(
                              value: 'Sede cliente',
                              child: Text('Sede cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'Altro',
                              child: Text('Altro'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => tipoSelezionato = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: indirizzoController,
                          decoration: const InputDecoration(
                            labelText: 'Indirizzo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: comuneController,
                          decoration: const InputDecoration(
                            labelText: 'Comune',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: capienzaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capienza',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final testo = value?.trim() ?? '';
                            if (testo.isEmpty) return null;

                            final numero = int.tryParse(testo);
                            if (numero == null || numero < 0) {
                              return 'Inserisci un numero valido';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          value: attiva,
                          onChanged: (value) {
                            setDialogState(() => attiva = value);
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final capienzaTesto = capienzaController.text.trim();

                    final aulaSede = AulaSede(
                      denominazione: denominazioneController.text.trim(),
                      tipo: tipoSelezionato,
                      indirizzo: indirizzoController.text.trim(),
                      comune: comuneController.text.trim(),
                      capienza: capienzaTesto.isEmpty
                          ? null
                          : int.tryParse(capienzaTesto),
                      note: noteController.text.trim(),
                      attiva: attiva,
                    );

                    await AppDatabase.instance.inserisciAulaSede(aulaSede);

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    denominazioneController.dispose();
    indirizzoController.dispose();
    comuneController.dispose();
    capienzaController.dispose();
    noteController.dispose();

    if (salvata == true) {
      await caricaAuleSedi();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aula / sede formativa salvata.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> cambiaStatoAulaSede(AulaSede aulaSede) async {
    final nuovaAttiva = !aulaSede.attiva;

    final aulaSedeAggiornata = aulaSede.copyWith(attiva: nuovaAttiva);

    await AppDatabase.instance.aggiornaAulaSede(aulaSedeAggiornata);

    await caricaAuleSedi();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuovaAttiva
              ? 'Aula / sede formativa riattivata.'
              : 'Aula / sede formativa disattivata.',
        ),
        backgroundColor: nuovaAttiva ? Colors.green : Colors.blueGrey,
      ),
    );
  }

  Future<void> esportaExcelAuleSedi() async {
    final datiExport = auleSediFiltrate;

    if (datiExport.isEmpty) return;

    final excel = xls.Excel.createExcel();
    final sheet = excel['AuleSedi'];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final now = DateTime.now();

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final dataExport =
        '${dueCifre(now.day)}/${dueCifre(now.month)}/${now.year} '
        '${dueCifre(now.hour)}:${dueCifre(now.minute)}';

    final ricerca = cercaController.text.trim();

    final infoFiltro = [
      soloAttive ? 'Solo attive' : 'Tutte',
      if (ricerca.isNotEmpty) 'Ricerca: "$ricerca"',
      '${datiExport.length} voci esportate',
      'Export: $dataExport',
    ].join(' - ');

    sheet.cell(xls.CellIndex.indexByString('A1')).value = xls.TextCellValue(
      infoFiltro,
    );

    final intestazioni = [
      'Denominazione',
      'Tipo',
      'Indirizzo',
      'Comune',
      'Capienza',
      'Stato',
      'Note',
    ];

    for (var i = 0; i < intestazioni.length; i++) {
      final cella = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
      );
      cella.value = xls.TextCellValue(intestazioni[i]);
      cella.cellStyle = xls.CellStyle(bold: true);
    }

    for (var i = 0; i < datiExport.length; i++) {
      final aulaSede = datiExport[i];
      final rowIndex = i + 3;

      final valori = [
        aulaSede.denominazione,
        aulaSede.tipo,
        aulaSede.indirizzo,
        aulaSede.comune,
        aulaSede.capienza?.toString() ?? '',
        aulaSede.attiva ? 'Attiva' : 'Non attiva',
        aulaSede.note,
      ];

      for (var col = 0; col < valori.length; col++) {
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: rowIndex,
              ),
            )
            .value = xls.TextCellValue(
          valori[col],
        );
      }
    }

    sheet.setColumnWidth(0, 34);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 36);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 42);

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${directory.path}/Gestionale Sicurezza/Export',
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final nomeFile =
        'aule_sedi_export_${soloAttive ? 'attive' : 'tutte'}_'
        '${now.year}_${dueCifre(now.month)}_${dueCifre(now.day)}_'
        '${dueCifre(now.hour)}${dueCifre(now.minute)}.xlsx';

    final file = File('${exportDir.path}/$nomeFile');

    final bytes = excel.encode();

    if (bytes == null) return;

    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export Excel creato: ${datiExport.length} voci.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> esportaPdfAuleSedi() async {
    final datiExport = auleSediFiltrate;

    if (datiExport.isEmpty) return;

    final pdf = pw.Document();
    final now = DateTime.now();

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final dataExport =
        '${dueCifre(now.day)}/${dueCifre(now.month)}/${now.year} '
        '${dueCifre(now.hour)}:${dueCifre(now.minute)}';

    final ricerca = cercaController.text.trim();

    final descrizioneFiltro = [
      soloAttive ? 'Solo attive' : 'Tutte',
      if (ricerca.isNotEmpty) 'Ricerca: "$ricerca"',
      '${datiExport.length} voci',
      'Export: $dataExport',
    ].join(' - ');

    final intestazionePdf = await caricaIntestazioneAziendaPdf();
    final intestazioneAzienda = intestazioneAziendaPdfWidget(intestazionePdf);

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
            intestazioneAzienda,
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                dataExport,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'AULE / SEDI FORMATIVE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              descrizioneFiltro,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey700),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Denominazione',
                'Tipo',
                'Indirizzo',
                'Comune',
                'Capienza',
                'Stato',
                'Note',
              ],
              data: datiExport.map((aulaSede) {
                return [
                  aulaSede.denominazione,
                  aulaSede.tipo,
                  aulaSede.indirizzo,
                  aulaSede.comune,
                  aulaSede.capienza?.toString() ?? '',
                  aulaSede.attiva ? 'Attiva' : 'Non attiva',
                  aulaSede.note,
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2.4),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(1.0),
                6: const pw.FlexColumnWidth(2.4),
              },
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
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${directory.path}/Gestionale Sicurezza/Export',
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final nomeFile =
        'aule_sedi_export_${soloAttive ? 'attive' : 'tutte'}_'
        '${now.year}_${dueCifre(now.month)}_${dueCifre(now.day)}_'
        '${dueCifre(now.hour)}${dueCifre(now.minute)}.pdf';

    final file = File('${exportDir.path}/$nomeFile');

    await file.writeAsBytes(await pdf.save(), flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export PDF creato: ${datiExport.length} voci.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> stampaAuleSedi() async {
    final dati = auleSediFiltrate;
    final testoRicerca = cercaController.text.trim();

    if (dati.isEmpty) {
      return;
    }

    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final pdf = pw.Document();

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
          intestazioneAziendaPdfWidget(intestazionePdf),
          pw.SizedBox(height: 14),
          pw.Text(
            'AULE / SEDI FORMATIVE',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${soloAttive ? 'Solo attive' : 'Tutte'}'
            '${testoRicerca.isNotEmpty ? ' - Ricerca: "$testoRicerca"' : ''}'
            ' - ${dati.length} ${dati.length == 1 ? 'voce' : 'voci'}'
            ' - Stampa del ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Denominazione',
              'Tipo',
              'Indirizzo',
              'Comune',
              'Capienza',
              'Stato',
              'Note',
            ],
            data: dati.map((aula) {
              return [
                aula.denominazione,
                aula.tipo,
                aula.indirizzo,
                aula.comune,
                aula.capienza?.toString() ?? '',
                aula.attiva ? 'ATTIVA' : 'NON ATTIVA',
                aula.note,
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
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(1.1),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(0.8),
              5: pw.FlexColumnWidth(1.0),
              6: pw.FlexColumnWidth(2.4),
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> apriDialogModificaAulaSede(AulaSede aulaSede) async {
    final formKey = GlobalKey<FormState>();

    final denominazioneController = TextEditingController(
      text: aulaSede.denominazione,
    );
    final indirizzoController = TextEditingController(text: aulaSede.indirizzo);
    final comuneController = TextEditingController(text: aulaSede.comune);
    final capienzaController = TextEditingController(
      text: aulaSede.capienza == null ? '' : aulaSede.capienza.toString(),
    );
    final noteController = TextEditingController(text: aulaSede.note);

    String tipoSelezionato = aulaSede.tipo;
    bool attiva = aulaSede.attiva;

    final salvata = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica aula / sede formativa'),
              content: SizedBox(
                width: 520,
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
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSelezionato,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Aula',
                              child: Text('Aula'),
                            ),
                            DropdownMenuItem(
                              value: 'Campo prove',
                              child: Text('Campo prove'),
                            ),
                            DropdownMenuItem(
                              value: 'Sede cliente',
                              child: Text('Sede cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'Altro',
                              child: Text('Altro'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => tipoSelezionato = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: indirizzoController,
                          decoration: const InputDecoration(
                            labelText: 'Indirizzo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: comuneController,
                          decoration: const InputDecoration(
                            labelText: 'Comune',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: capienzaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capienza',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final testo = value?.trim() ?? '';
                            if (testo.isEmpty) return null;

                            final numero = int.tryParse(testo);
                            if (numero == null || numero < 0) {
                              return 'Inserisci un numero valido';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          value: attiva,
                          onChanged: (value) {
                            setDialogState(() => attiva = value);
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final capienzaTesto = capienzaController.text.trim();

                    final aulaSedeAggiornata = aulaSede.copyWith(
                      denominazione: denominazioneController.text.trim(),
                      tipo: tipoSelezionato,
                      indirizzo: indirizzoController.text.trim(),
                      comune: comuneController.text.trim(),
                      capienza: capienzaTesto.isEmpty
                          ? null
                          : int.tryParse(capienzaTesto),
                      note: noteController.text.trim(),
                      attiva: attiva,
                    );

                    await AppDatabase.instance.aggiornaAulaSede(
                      aulaSedeAggiornata,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    denominazioneController.dispose();
    indirizzoController.dispose();
    comuneController.dispose();
    capienzaController.dispose();
    noteController.dispose();

    if (salvata == true) {
      await caricaAuleSedi();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aula / sede formativa aggiornata.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String testoCapienza(AulaSede aulaSede) {
    if (aulaSede.capienza == null) return '-';
    if (aulaSede.capienza! <= 0) return '-';
    return aulaSede.capienza.toString();
  }

  Widget badgeTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          color: Colors.blueGrey.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget badgeStato(bool attiva) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: attiva ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: attiva ? Colors.green.shade200 : Colors.grey.shade400,
        ),
      ),
      child: Text(
        attiva ? 'Attiva' : 'Non attiva',
        style: TextStyle(
          color: attiva ? Colors.green.shade800 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Torna alla Dashboard',
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 12),
                Icon(Icons.meeting_room, color: Colors.blueGrey.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Aule / Sedi formative',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: apriDialogNuovaAulaSede,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova voce'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: auleSediFiltrate.isEmpty
                      ? null
                      : esportaExcelAuleSedi,
                  icon: const Icon(Icons.table_chart),
                  label: Text('Esporta Excel (${auleSediFiltrate.length})'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: auleSediFiltrate.isEmpty
                      ? null
                      : esportaPdfAuleSedi,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text('Esporta PDF (${auleSediFiltrate.length})'),
                ),
                ElevatedButton.icon(
                  onPressed: auleSediFiltrate.isEmpty ? null : stampaAuleSedi,
                  icon: const Icon(Icons.print_rounded),
                  label: Text('Stampa (${auleSediFiltrate.length})'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: caricaAuleSedi,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Aggiorna'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gestione di aule, campi prova e sedi utilizzabili per corsi e sessioni formative.',
              style: TextStyle(color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cercaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: cercaController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Pulisci ricerca',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                cercaController.clear();
                                setState(() {});
                              },
                            ),
                      labelText: 'Cerca aula, sede, tipo, comune o note...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                FilterChip(
                  selected: soloAttive,
                  label: const Text('Solo attive'),
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  onSelected: (_) {
                    setState(() => soloAttive = true);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: !soloAttive,
                  label: const Text('Tutte'),
                  avatar: const Icon(Icons.list_alt_rounded, size: 18),
                  onSelected: (_) {
                    setState(() => soloAttive = false);
                  },
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  child: Text(
                    cercaController.text.trim().isEmpty
                        ? soloAttive
                              ? '${auleSediFiltrate.length} voci attive'
                              : '${auleSediFiltrate.length} voci presenti'
                        : '${auleSediFiltrate.length} risultati',
                    style: TextStyle(
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.blueGrey.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: caricamento
                      ? const Center(child: CircularProgressIndicator())
                      : auleSediFiltrate.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cercaController.text.trim().isEmpty
                                    ? Icons.meeting_room_outlined
                                    : Icons.search_off_rounded,
                                size: 54,
                                color: Colors.blueGrey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                cercaController.text.trim().isEmpty
                                    ? 'Nessuna aula o sede formativa presente'
                                    : 'Nessuna aula o sede formativa trovata',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cercaController.text.trim().isEmpty
                                    ? 'Qui saranno elencate le aule, i campi prova e le sedi cliente.'
                                    : 'Modifica o azzera la ricerca per visualizzare altre voci.',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                              if (cercaController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    cercaController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Azzera ricerca'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              Colors.blueGrey.shade50,
                            ),
                            columns: const [
                              DataColumn(label: Text('Denominazione')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('Indirizzo')),
                              DataColumn(label: Text('Comune')),
                              DataColumn(label: Text('Capienza')),
                              DataColumn(label: Text('Stato')),
                              DataColumn(label: Text('Note')),
                              DataColumn(label: Text('Azioni')),
                            ],
                            rows: auleSediFiltrate.map((aulaSede) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      aulaSede.denominazione,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(badgeTipo(aulaSede.tipo)),
                                  DataCell(Text(aulaSede.indirizzo)),
                                  DataCell(Text(aulaSede.comune)),
                                  DataCell(Text(testoCapienza(aulaSede))),
                                  DataCell(badgeStato(aulaSede.attiva)),
                                  DataCell(Text(aulaSede.note)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Builder(
                                          builder: (cellContext) {
                                            return IconButton(
                                              tooltip: 'Modifica aula / sede',
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.blueGrey.shade700,
                                              ),
                                              onPressed: () {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      if (!mounted) return;
                                                      apriDialogModificaAulaSede(
                                                        aulaSede,
                                                      );
                                                    });
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          tooltip: aulaSede.attiva
                                              ? 'Disattiva aula / sede'
                                              : 'Riattiva aula / sede',
                                          icon: Icon(
                                            aulaSede.attiva
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: aulaSede.attiva
                                                ? Colors.orange.shade700
                                                : Colors.green.shade700,
                                          ),
                                          onPressed: () =>
                                              cambiaStatoAulaSede(aulaSede),
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
    );
  }
}
