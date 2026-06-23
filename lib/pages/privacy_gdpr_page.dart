import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/privacy_gdpr.dart';
import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

class PrivacyGdprPage extends StatefulWidget {
  const PrivacyGdprPage({super.key});

  @override
  State<PrivacyGdprPage> createState() => _PrivacyGdprPageState();
}

class _PrivacyGdprPageState extends State<PrivacyGdprPage> {
  List<PrivacyGdpr> vociPrivacy = [];
  bool caricamento = true;
  bool soloAttive = true;
  String ricerca = '';

  final TextEditingController ricercaController = TextEditingController();

  final ScrollController scrollOrizzontaleTabellaController =
      ScrollController();

  @override
  void initState() {
    super.initState();
    caricaPrivacyGdpr();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    scrollOrizzontaleTabellaController.dispose();
    super.dispose();
  }

  List<PrivacyGdpr> get vociPrivacyFiltrate {
    final testo = ricerca.trim().toLowerCase();

    if (testo.isEmpty) {
      return vociPrivacy;
    }

    return vociPrivacy.where((voce) {
      final stato = voce.attivo ? 'attiva' : 'non attiva';

      final campiRicerca = [
        voce.titolo,
        voce.titolareTrattamento ?? '',
        voce.referentePrivacy ?? '',
        voce.baseGiuridica ?? '',
        voce.finalitaTrattamento ?? '',
        voce.categorieDati ?? '',
        voce.periodoConservazione ?? '',
        voce.misureSicurezza ?? '',
        voce.note ?? '',
        stato,
      ].join(' ').toLowerCase();

      return campiRicerca.contains(testo);
    }).toList();
  }

  bool get ricercaAttiva => ricerca.trim().isNotEmpty;

  Future<void> caricaPrivacyGdpr() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getPrivacyGdpr(
      soloAttivi: soloAttive,
    );

    if (!mounted) return;

    setState(() {
      vociPrivacy = dati.map((mappa) => PrivacyGdpr.fromMap(mappa)).toList();
      caricamento = false;
    });
  }

  Future<void> mostraDialogNuovaVoce() async {
    final formKey = GlobalKey<FormState>();

    final titoloController = TextEditingController();
    final titolareController = TextEditingController();
    final referenteController = TextEditingController();
    final baseGiuridicaController = TextEditingController();
    final finalitaController = TextEditingController();
    final categorieDatiController = TextEditingController();
    final periodoConservazioneController = TextEditingController();
    final misureSicurezzaController = TextEditingController();
    final noteController = TextEditingController();

    bool voceAttiva = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova voce Privacy/GDPR'),
              content: SizedBox(
                width: 760,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titoloController,
                          decoration: const InputDecoration(
                            labelText: 'Titolo *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valore) {
                            if (valore == null || valore.trim().isEmpty) {
                              return 'Inserisci il titolo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titolareController,
                          decoration: const InputDecoration(
                            labelText: 'Titolare trattamento',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: referenteController,
                          decoration: const InputDecoration(
                            labelText: 'Referente privacy',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: baseGiuridicaController,
                          decoration: const InputDecoration(
                            labelText: 'Base giuridica',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: finalitaController,
                          decoration: const InputDecoration(
                            labelText: 'Finalità trattamento',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: categorieDatiController,
                          decoration: const InputDecoration(
                            labelText: 'Categorie dati',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: periodoConservazioneController,
                          decoration: const InputDecoration(
                            labelText: 'Periodo conservazione',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: misureSicurezzaController,
                          decoration: const InputDecoration(
                            labelText: 'Misure sicurezza',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          subtitle: const Text(
                            'Le voci non attive restano archiviate ma vengono nascoste dal filtro Solo attive.',
                          ),
                          value: voceAttiva,
                          onChanged: (valore) {
                            setDialogState(() {
                              voceAttiva = valore;
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annulla'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    await AppDatabase.instance.insertPrivacyGdpr(
                      titolo: titoloController.text,
                      titolareTrattamento: titolareController.text,
                      referentePrivacy: referenteController.text,
                      baseGiuridica: baseGiuridicaController.text,
                      finalitaTrattamento: finalitaController.text,
                      categorieDati: categorieDatiController.text,
                      periodoConservazione: periodoConservazioneController.text,
                      misureSicurezza: misureSicurezzaController.text,
                      note: noteController.text,
                      attivo: voceAttiva,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    await caricaPrivacyGdpr();

                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Voce Privacy/GDPR salvata.'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
  }

  Future<void> mostraDialogModificaVoce(PrivacyGdpr voce) async {
    final idVoce = voce.id;
    if (idVoce == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();

    final titoloController = TextEditingController(text: voce.titolo);
    final titolareController = TextEditingController(
      text: voce.titolareTrattamento ?? '',
    );
    final referenteController = TextEditingController(
      text: voce.referentePrivacy ?? '',
    );
    final baseGiuridicaController = TextEditingController(
      text: voce.baseGiuridica ?? '',
    );
    final finalitaController = TextEditingController(
      text: voce.finalitaTrattamento ?? '',
    );
    final categorieDatiController = TextEditingController(
      text: voce.categorieDati ?? '',
    );
    final periodoConservazioneController = TextEditingController(
      text: voce.periodoConservazione ?? '',
    );
    final misureSicurezzaController = TextEditingController(
      text: voce.misureSicurezza ?? '',
    );
    final noteController = TextEditingController(text: voce.note ?? '');

    bool voceAttiva = voce.attivo;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica voce Privacy/GDPR'),
              content: SizedBox(
                width: 760,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titoloController,
                          decoration: const InputDecoration(
                            labelText: 'Titolo *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valore) {
                            if (valore == null || valore.trim().isEmpty) {
                              return 'Inserisci il titolo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titolareController,
                          decoration: const InputDecoration(
                            labelText: 'Titolare trattamento',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: referenteController,
                          decoration: const InputDecoration(
                            labelText: 'Referente privacy',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: baseGiuridicaController,
                          decoration: const InputDecoration(
                            labelText: 'Base giuridica',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: finalitaController,
                          decoration: const InputDecoration(
                            labelText: 'Finalità trattamento',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: categorieDatiController,
                          decoration: const InputDecoration(
                            labelText: 'Categorie dati',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: periodoConservazioneController,
                          decoration: const InputDecoration(
                            labelText: 'Periodo conservazione',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: misureSicurezzaController,
                          decoration: const InputDecoration(
                            labelText: 'Misure sicurezza',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          subtitle: const Text(
                            'Le voci non attive restano archiviate ma vengono nascoste dal filtro Solo attive.',
                          ),
                          value: voceAttiva,
                          onChanged: (valore) {
                            setDialogState(() {
                              voceAttiva = valore;
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annulla'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    await AppDatabase.instance.aggiornaPrivacyGdpr(
                      id: idVoce,
                      titolo: titoloController.text,
                      titolareTrattamento: titolareController.text,
                      referentePrivacy: referenteController.text,
                      baseGiuridica: baseGiuridicaController.text,
                      finalitaTrattamento: finalitaController.text,
                      categorieDati: categorieDatiController.text,
                      periodoConservazione: periodoConservazioneController.text,
                      misureSicurezza: misureSicurezzaController.text,
                      note: noteController.text,
                      attivo: voceAttiva,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    await caricaPrivacyGdpr();

                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Voce Privacy/GDPR aggiornata.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salva modifiche'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> esportaExcelPrivacyGdpr() async {
    final vociDaEsportare = vociPrivacyFiltrate;

    if (vociDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna voce Privacy/GDPR da esportare.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Privacy GDPR'];

    excel.delete('Sheet1');

    final ora = DateTime.now();
    final dataOra = DateFormat('dd/MM/yyyy HH:mm').format(ora);

    final filtroAttive = soloAttive ? 'Solo attive' : 'Tutte';
    final ricercaCorrente = ricerca.trim().isNotEmpty
        ? ' - Ricerca: "${ricerca.trim()}"'
        : '';

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xls.TextCellValue(
      'Export Privacy/GDPR - $filtroAttive$ricercaCorrente - '
      '${vociDaEsportare.length} record - $dataOra',
    );

    final intestazioni = [
      'Titolo',
      'Titolare trattamento',
      'Referente privacy',
      'Base giuridica',
      'Finalità trattamento',
      'Categorie dati',
      'Periodo conservazione',
      'Misure sicurezza',
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

    for (var i = 0; i < vociDaEsportare.length; i++) {
      final voce = vociDaEsportare[i];
      final rowIndex = i + 2;

      final valori = [
        voce.titolo,
        voce.titolareTrattamento ?? '',
        voce.referentePrivacy ?? '',
        voce.baseGiuridica ?? '',
        voce.finalitaTrattamento ?? '',
        voce.categorieDati ?? '',
        voce.periodoConservazione ?? '',
        voce.misureSicurezza ?? '',
        voce.attivo ? 'Attiva' : 'Non attiva',
        voce.note ?? '',
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
          valori[colIndex],
        );
      }
    }

    final larghezze = <int, double>{
      0: 28, // Titolo
      1: 24, // Titolare trattamento
      2: 22, // Referente privacy
      3: 30, // Base giuridica
      4: 30, // Finalità trattamento
      5: 26, // Categorie dati
      6: 24, // Periodo conservazione
      7: 28, // Misure sicurezza
      8: 14, // Stato
      9: 32, // Note
    };

    larghezze.forEach((colonna, larghezza) {
      sheet.setColumnWidth(colonna, larghezza);
    });

    final directory = await getApplicationDocumentsDirectory();

    final suffissoFiltro = ricerca.trim().isNotEmpty || !soloAttive
        ? '_filtrato'
        : '_attive';

    final nomeFile =
        'privacy_gdpr_export$suffissoFiltro'
        '_${DateFormat('yyyy_MM_dd_HHmm').format(ora)}.xlsx';

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
          'Export Excel creato correttamente: ${vociDaEsportare.length} '
          '${vociDaEsportare.length == 1 ? 'voce' : 'voci'} Privacy/GDPR.',
        ),
        backgroundColor: Colors.green,
      ),
    );

    await OpenFile.open(file.path);
  }

  Future<void> esportaPdfPrivacyGdpr() async {
    final vociDaEsportare = vociPrivacyFiltrate;

    if (vociDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna voce Privacy/GDPR da esportare in PDF.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final now = DateTime.now();
    final dataGenerazione = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final filtroAttivo = soloAttive ? 'Solo attive' : 'Tutte';
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
              'PRIVACY / GDPR 679/2016',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Filtro: $filtroAttivo | Ricerca: $ricercaAttiva | '
              'Record esportati: ${vociDaEsportare.length} | '
              'Generato il: $dataGenerazione',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Titolo',
                'Titolare',
                'Referente',
                'Base giuridica',
                'Finalità',
                'Categorie dati',
                'Conservazione',
                'Stato',
                'Note',
              ],
              data: vociDaEsportare.map((voce) {
                return [
                  voce.titolo,
                  voce.titolareTrattamento ?? '',
                  voce.referentePrivacy ?? '',
                  voce.baseGiuridica ?? '',
                  voce.finalitaTrattamento ?? '',
                  voce.categorieDati ?? '',
                  voce.periodoConservazione ?? '',
                  voce.attivo ? 'Attiva' : 'Non attiva',
                  voce.note ?? '',
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
                0: const pw.FlexColumnWidth(2.0),
                1: const pw.FlexColumnWidth(1.6),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(2.0),
                4: const pw.FlexColumnWidth(2.0),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FlexColumnWidth(1.4),
                7: const pw.FlexColumnWidth(0.9),
                8: const pw.FlexColumnWidth(1.8),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final suffixFiltro = ricerca.trim().isEmpty && soloAttive
        ? ''
        : '_filtrato';

    final nomeFile =
        'privacy_gdpr_export_pdf$suffixFiltro'
        '_${DateFormat('yyyy_MM_dd_HHmm').format(now)}.pdf';

    final file = File('${directory.path}${Platform.pathSeparator}$nomeFile');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF Privacy/GDPR esportato: ${vociDaEsportare.length} '
          '${vociDaEsportare.length == 1 ? 'voce' : 'voci'}.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> stampaPrivacyGdpr() async {
    final vociDaStampare = vociPrivacyFiltrate;

    if (vociDaStampare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna voce Privacy/GDPR da stampare.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final now = DateTime.now();
    final dataGenerazione = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final filtroAttivo = soloAttive ? 'Solo attive' : 'Tutte';
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
              'PRIVACY / GDPR 679/2016',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Filtro: $filtroAttivo | Ricerca: $ricercaAttiva | '
              'Record stampati: ${vociDaStampare.length} | '
              'Generato il: $dataGenerazione',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Titolo',
                'Titolare',
                'Referente',
                'Base giuridica',
                'Finalità',
                'Categorie dati',
                'Conservazione',
                'Stato',
                'Note',
              ],
              data: vociDaStampare.map((voce) {
                return [
                  voce.titolo,
                  voce.titolareTrattamento ?? '',
                  voce.referentePrivacy ?? '',
                  voce.baseGiuridica ?? '',
                  voce.finalitaTrattamento ?? '',
                  voce.categorieDati ?? '',
                  voce.periodoConservazione ?? '',
                  voce.attivo ? 'Attiva' : 'Non attiva',
                  voce.note ?? '',
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
                0: const pw.FlexColumnWidth(2.0),
                1: const pw.FlexColumnWidth(1.6),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(2.0),
                4: const pw.FlexColumnWidth(2.0),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FlexColumnWidth(1.4),
                7: const pw.FlexColumnWidth(0.9),
                8: const pw.FlexColumnWidth(1.8),
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
          'Stampa Privacy/GDPR avviata: ${vociDaStampare.length} '
          '${vociDaStampare.length == 1 ? 'voce' : 'voci'}.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color coloreStato(bool attivo) {
    return attivo ? Colors.green.shade700 : Colors.grey.shade600;
  }

  Widget badgeStato(bool attivo) {
    final testo = attivo ? 'Attiva' : 'Non attiva';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: attivo ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coloreStato(attivo)),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: coloreStato(attivo),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget statoVuoto() {
    return Center(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 56,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Privacy / GDPR 679/2016',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ricercaAttiva
                    ? 'Nessuna voce Privacy/GDPR trovata per la ricerca corrente.'
                    : soloAttive
                    ? 'Nessuna voce privacy/GDPR attiva inserita.'
                    : 'Nessuna voce privacy/GDPR inserita.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 16),
              if (ricercaAttiva)
                OutlinedButton.icon(
                  onPressed: () {
                    ricercaController.clear();
                    setState(() {
                      ricerca = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Azzera ricerca'),
                )
              else
                FilledButton.icon(
                  onPressed: mostraDialogNuovaVoce,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova voce'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tabellaPrivacy() {
    return Card(
      elevation: 1,
      child: Scrollbar(
        controller: scrollOrizzontaleTabellaController,
        thumbVisibility: true,
        trackVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: scrollOrizzontaleTabellaController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(label: Text('Titolo')),
              DataColumn(label: Text('Titolare trattamento')),
              DataColumn(label: Text('Referente privacy')),
              DataColumn(label: Text('Base giuridica')),
              DataColumn(label: Text('Periodo conservazione')),
              DataColumn(label: Text('Stato')),
              DataColumn(label: Text('Azioni')),
            ],
            rows: vociPrivacyFiltrate.map((voce) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(voce.titolo, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        voce.titolareTrattamento ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Text(
                        voce.referentePrivacy ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        voce.baseGiuridica ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        voce.periodoConservazione ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(width: 115, child: badgeStato(voce.attivo)),
                  ),
                  DataCell(
                    SizedBox(
                      width: 70,
                      child: IconButton(
                        tooltip: 'Modifica voce Privacy/GDPR',
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () {
                          mostraDialogModificaVoce(voce);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totale = vociPrivacy.length;
    final totaleFiltrato = vociPrivacyFiltrate.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy / GDPR 679/2016'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Text('Solo attive'),
                Switch(
                  value: soloAttive,
                  onChanged: (valore) {
                    setState(() {
                      soloAttive = valore;
                    });
                    caricaPrivacyGdpr();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: caricamento
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            color: Colors.blueGrey.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestione Privacy / GDPR 679/2016',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Archivio interno per informative, basi giuridiche, finalità, categorie dati, conservazione e misure di sicurezza.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 360,
                            child: TextField(
                              controller: ricercaController,
                              decoration: InputDecoration(
                                labelText: 'Cerca Privacy/GDPR',
                                hintText:
                                    'Titolo, titolare, referente, base giuridica...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: ricercaAttiva
                                    ? IconButton(
                                        tooltip: 'Azzera ricerca',
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
                                isDense: true,
                              ),
                              onChanged: (valore) {
                                setState(() {
                                  ricerca = valore;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: vociPrivacyFiltrate.isEmpty
                                ? null
                                : esportaExcelPrivacyGdpr,
                            icon: const Icon(Icons.table_chart),
                            label: Text('Excel ($totaleFiltrato)'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: vociPrivacyFiltrate.isEmpty
                                ? null
                                : esportaPdfPrivacyGdpr,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text('PDF ($totaleFiltrato)'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: vociPrivacyFiltrate.isEmpty
                                ? null
                                : stampaPrivacyGdpr,
                            icon: const Icon(Icons.print),
                            label: Text('Stampa ($totaleFiltrato)'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: mostraDialogNuovaVoce,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuova voce'),
                          ),
                          const SizedBox(width: 12),
                          Chip(
                            avatar: const Icon(Icons.list_alt, size: 18),
                            label: Text(
                              ricercaAttiva
                                  ? '$totaleFiltrato voci trovate'
                                  : soloAttive
                                  ? '$totale voci attive'
                                  : '$totale voci totali',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: vociPrivacyFiltrate.isEmpty
                        ? statoVuoto()
                        : tabellaPrivacy(),
                  ),
                ],
              ),
      ),
    );
  }
}
