import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'registro_trattamenti_page.dart';
import 'registro_data_breach_page.dart';
import 'registro_consensi_privacy_page.dart';

import '../models/privacy_gdpr.dart';
import '../models/registro_trattamento.dart';
import '../models/data_breach.dart';

import '../services/app_database.dart';

import '../utils/pdf_azienda_helper.dart';
import '../widgets/app_action_button.dart';

class PrivacyGdprPage extends StatefulWidget {
  const PrivacyGdprPage({super.key});

  @override
  State<PrivacyGdprPage> createState() => _PrivacyGdprPageState();
}

class _PrivacyGdprPageState extends State<PrivacyGdprPage> {
  List<PrivacyGdpr> vociPrivacy = [];
  List<RegistroTrattamento> trattamentiAuditGdpr = [];
  List<DataBreach> dataBreachAuditGdpr = [];

  int totaleLogRegistroTrattamentiAudit = 0;
  int totaleLogDataBreachAudit = 0;

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
    caricaAuditGdpr();
  }

  Future<void> caricaAuditGdpr() async {
    final trattamenti = await AppDatabase.instance.getRegistroTrattamenti(
      soloAttivi: false,
    );
    final dataBreach = await AppDatabase.instance.getDataBreach();
    final logTrattamenti = await AppDatabase.instance
        .getRegistroTrattamentiLog();
    final logDataBreach = await AppDatabase.instance.getDataBreachLog();

    if (!mounted) return;

    setState(() {
      trattamentiAuditGdpr = trattamenti;
      dataBreachAuditGdpr = dataBreach;
      totaleLogRegistroTrattamentiAudit = logTrattamenti.length;
      totaleLogDataBreachAudit = logDataBreach.length;
    });
  }

  DateTime? parseDataAuditGdpr(String? valore) {
    if (valore == null || valore.trim().isEmpty) {
      return null;
    }

    final testo = valore.trim();

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(testo);
    } catch (_) {
      return DateTime.tryParse(testo);
    }
  }

  bool revisioneScadutaAuditGdpr(RegistroTrattamento trattamento) {
    final data = parseDataAuditGdpr(trattamento.dataRevisione);
    if (data == null) return false;

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final dataPulita = DateTime(data.year, data.month, data.day);

    return dataPulita.isBefore(oggiPulito);
  }

  bool revisioneInScadenzaAuditGdpr(RegistroTrattamento trattamento) {
    final data = parseDataAuditGdpr(trattamento.dataRevisione);
    if (data == null) return false;

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final dataPulita = DateTime(data.year, data.month, data.day);
    final limite = oggiPulito.add(const Duration(days: 60));

    return !dataPulita.isBefore(oggiPulito) && !dataPulita.isAfter(limite);
  }

  bool revisioneNonImpostataAuditGdpr(RegistroTrattamento trattamento) {
    return trattamento.dataRevisione == null ||
        trattamento.dataRevisione!.trim().isEmpty ||
        parseDataAuditGdpr(trattamento.dataRevisione) == null;
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

  Future<void> esportaPdfRiepilogoAuditGdpr() async {
    final pdf = pw.Document();
    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final now = DateTime.now();
    final dataGenerazione = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final trattamentiTotali = trattamentiAuditGdpr.length;
    final trattamentiAttivi = trattamentiAuditGdpr
        .where((elemento) => elemento.attivo)
        .length;
    final trattamentiNonAttivi = trattamentiTotali - trattamentiAttivi;

    final revisioniScadute = trattamentiAuditGdpr
        .where(revisioneScadutaAuditGdpr)
        .length;
    final revisioniInScadenza = trattamentiAuditGdpr
        .where(revisioneInScadenzaAuditGdpr)
        .length;
    final revisioniNonImpostate = trattamentiAuditGdpr
        .where(revisioneNonImpostataAuditGdpr)
        .length;

    final breachTotali = dataBreachAuditGdpr.length;
    final breachAperti = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('aperto'))
        .length;
    final breachInGestione = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('gestione'))
        .length;
    final breachChiusi = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('chiuso'))
        .length;
    final breachRischioAlto = dataBreachAuditGdpr
        .where((elemento) => elemento.rischio.toLowerCase().contains('alto'))
        .length;
    final notificheGarante = dataBreachAuditGdpr
        .where((elemento) => elemento.notificatoGarante)
        .length;
    final comunicazioniInteressati = dataBreachAuditGdpr
        .where((elemento) => elemento.comunicatoInteressati)
        .length;

    final totaleLog =
        totaleLogRegistroTrattamentiAudit + totaleLogDataBreachAudit;

    final criticita =
        revisioniScadute +
        revisioniInScadenza +
        revisioniNonImpostate +
        breachAperti +
        breachInGestione +
        breachRischioAlto;

    final auditOk = trattamentiTotali > 0 && totaleLog > 0 && criticita == 0;
    final statoAudit = auditOk ? 'Auditabile' : 'Da verificare';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
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
            pw.SizedBox(height: 14),
            pw.Text(
              'RIEPILOGO AUDIT GDPR',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generato il: $dataGenerazione',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: auditOk ? PdfColors.green50 : PdfColors.orange50,
                border: pw.Border.all(
                  color: auditOk ? PdfColors.green700 : PdfColors.orange700,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Stato audit: $statoAudit',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: auditOk ? PdfColors.green800 : PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    auditOk
                        ? 'Il riepilogo non evidenzia criticita principali nei dati attualmente registrati.'
                        : 'Il riepilogo evidenzia elementi da verificare prima di considerare completa la posizione GDPR.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Sintesi generale',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Area', 'Valore', 'Dettaglio'],
              data: [
                [
                  'Registro trattamenti',
                  '$trattamentiTotali',
                  '$trattamentiAttivi attivi, $trattamentiNonAttivi non attivi',
                ],
                [
                  'Revisioni',
                  '${revisioniScadute + revisioniInScadenza}',
                  '$revisioniScadute scadute, $revisioniInScadenza in scadenza, $revisioniNonImpostate non impostate',
                ],
                [
                  'Data breach',
                  '$breachTotali',
                  '$breachAperti aperti, $breachInGestione in gestione, $breachChiusi chiusi',
                ],
                [
                  'Rischio alto',
                  '$breachRischioAlto',
                  'Data breach classificati con rischio alto',
                ],
                [
                  'Notifiche GDPR',
                  '${notificheGarante + comunicazioniInteressati}',
                  '$notificheGarante notifiche al Garante, $comunicazioniInteressati comunicazioni agli interessati',
                ],
                [
                  'Log tracciabilita',
                  '$totaleLog',
                  '$totaleLogRegistroTrattamentiAudit log trattamenti, $totaleLogDataBreachAudit log data breach',
                ],
                [
                  'Criticita complessive',
                  '$criticita',
                  'Somma di revisioni critiche, breach aperti/in gestione e rischio alto',
                ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.7),
                1: const pw.FlexColumnWidth(0.8),
                2: const pw.FlexColumnWidth(3.2),
              },
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Elementi da verificare',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Voce', 'Quantita', 'Priorita'],
              data: [
                [
                  'Revisioni scadute',
                  '$revisioniScadute',
                  revisioniScadute > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Revisioni in scadenza',
                  '$revisioniInScadenza',
                  revisioniInScadenza > 0 ? 'Media' : 'Nessuna',
                ],
                [
                  'Revisioni non impostate',
                  '$revisioniNonImpostate',
                  revisioniNonImpostate > 0 ? 'Media' : 'Nessuna',
                ],
                [
                  'Data breach aperti',
                  '$breachAperti',
                  breachAperti > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Data breach in gestione',
                  '$breachInGestione',
                  breachInGestione > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Data breach rischio alto',
                  '$breachRischioAlto',
                  breachRischioAlto > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Log tracciabilita assenti',
                  totaleLog == 0 ? '1' : '0',
                  totaleLog == 0 ? 'Media' : 'Nessuna',
                ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(0.8),
                2: const pw.FlexColumnWidth(1.0),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'riepilogo_audit_gdpr_${DateFormat('yyyy_MM_dd_HHmm').format(now)}.pdf';

    final file = File('${directory.path}${Platform.pathSeparator}$nomeFile');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF riepilogo audit GDPR esportato correttamente: $statoAudit.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> stampaRiepilogoAuditGdpr() async {
    final pdf = pw.Document();
    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final now = DateTime.now();
    final dataGenerazione = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final trattamentiTotali = trattamentiAuditGdpr.length;
    final trattamentiAttivi = trattamentiAuditGdpr
        .where((elemento) => elemento.attivo)
        .length;
    final trattamentiNonAttivi = trattamentiTotali - trattamentiAttivi;

    final revisioniScadute = trattamentiAuditGdpr
        .where(revisioneScadutaAuditGdpr)
        .length;
    final revisioniInScadenza = trattamentiAuditGdpr
        .where(revisioneInScadenzaAuditGdpr)
        .length;
    final revisioniNonImpostate = trattamentiAuditGdpr
        .where(revisioneNonImpostataAuditGdpr)
        .length;

    final breachTotali = dataBreachAuditGdpr.length;
    final breachAperti = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('aperto'))
        .length;
    final breachInGestione = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('gestione'))
        .length;
    final breachChiusi = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('chiuso'))
        .length;
    final breachRischioAlto = dataBreachAuditGdpr
        .where((elemento) => elemento.rischio.toLowerCase().contains('alto'))
        .length;
    final notificheGarante = dataBreachAuditGdpr
        .where((elemento) => elemento.notificatoGarante)
        .length;
    final comunicazioniInteressati = dataBreachAuditGdpr
        .where((elemento) => elemento.comunicatoInteressati)
        .length;

    final totaleLog =
        totaleLogRegistroTrattamentiAudit + totaleLogDataBreachAudit;

    final criticita =
        revisioniScadute +
        revisioniInScadenza +
        revisioniNonImpostate +
        breachAperti +
        breachInGestione +
        breachRischioAlto;

    final auditOk = trattamentiTotali > 0 && totaleLog > 0 && criticita == 0;
    final statoAudit = auditOk ? 'Auditabile' : 'Da verificare';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
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
            pw.SizedBox(height: 14),
            pw.Text(
              'RIEPILOGO AUDIT GDPR',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generato il: $dataGenerazione',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: auditOk ? PdfColors.green50 : PdfColors.orange50,
                border: pw.Border.all(
                  color: auditOk ? PdfColors.green700 : PdfColors.orange700,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Stato audit: $statoAudit',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: auditOk ? PdfColors.green800 : PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    auditOk
                        ? 'Il riepilogo non evidenzia criticita principali nei dati attualmente registrati.'
                        : 'Il riepilogo evidenzia elementi da verificare prima di considerare completa la posizione GDPR.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Sintesi generale',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Area', 'Valore', 'Dettaglio'],
              data: [
                [
                  'Registro trattamenti',
                  '$trattamentiTotali',
                  '$trattamentiAttivi attivi, $trattamentiNonAttivi non attivi',
                ],
                [
                  'Revisioni',
                  '${revisioniScadute + revisioniInScadenza}',
                  '$revisioniScadute scadute, $revisioniInScadenza in scadenza, $revisioniNonImpostate non impostate',
                ],
                [
                  'Data breach',
                  '$breachTotali',
                  '$breachAperti aperti, $breachInGestione in gestione, $breachChiusi chiusi',
                ],
                [
                  'Rischio alto',
                  '$breachRischioAlto',
                  'Data breach classificati con rischio alto',
                ],
                [
                  'Notifiche GDPR',
                  '${notificheGarante + comunicazioniInteressati}',
                  '$notificheGarante notifiche al Garante, $comunicazioniInteressati comunicazioni agli interessati',
                ],
                [
                  'Log tracciabilita',
                  '$totaleLog',
                  '$totaleLogRegistroTrattamentiAudit log trattamenti, $totaleLogDataBreachAudit log data breach',
                ],
                [
                  'Criticita complessive',
                  '$criticita',
                  'Somma di revisioni critiche, breach aperti/in gestione e rischio alto',
                ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.7),
                1: const pw.FlexColumnWidth(0.8),
                2: const pw.FlexColumnWidth(3.2),
              },
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Elementi da verificare',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Voce', 'Quantita', 'Priorita'],
              data: [
                [
                  'Revisioni scadute',
                  '$revisioniScadute',
                  revisioniScadute > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Revisioni in scadenza',
                  '$revisioniInScadenza',
                  revisioniInScadenza > 0 ? 'Media' : 'Nessuna',
                ],
                [
                  'Revisioni non impostate',
                  '$revisioniNonImpostate',
                  revisioniNonImpostate > 0 ? 'Media' : 'Nessuna',
                ],
                [
                  'Data breach aperti',
                  '$breachAperti',
                  breachAperti > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Data breach in gestione',
                  '$breachInGestione',
                  breachInGestione > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Data breach rischio alto',
                  '$breachRischioAlto',
                  breachRischioAlto > 0 ? 'Alta' : 'Nessuna',
                ],
                [
                  'Log tracciabilita assenti',
                  totaleLog == 0 ? '1' : '0',
                  totaleLog == 0 ? 'Media' : 'Nessuna',
                ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(0.8),
                2: const pw.FlexColumnWidth(1.0),
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
        content: Text('Stampa riepilogo audit GDPR avviata: $statoAudit.'),
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

  Widget cardAuditGdpr({
    required IconData icona,
    required String titolo,
    required String valore,
    required String descrizione,
    required Color colore,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colore.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icona, color: colore),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valore,
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descrizione,
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget riepilogoAuditGdpr() {
    final trattamentiTotali = trattamentiAuditGdpr.length;
    final trattamentiAttivi = trattamentiAuditGdpr
        .where((elemento) => elemento.attivo)
        .length;
    final trattamentiNonAttivi = trattamentiTotali - trattamentiAttivi;

    final revisioniScadute = trattamentiAuditGdpr
        .where(revisioneScadutaAuditGdpr)
        .length;
    final revisioniInScadenza = trattamentiAuditGdpr
        .where(revisioneInScadenzaAuditGdpr)
        .length;
    final revisioniNonImpostate = trattamentiAuditGdpr
        .where(revisioneNonImpostataAuditGdpr)
        .length;

    final breachTotali = dataBreachAuditGdpr.length;
    final breachAperti = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('aperto'))
        .length;
    final breachInGestione = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('gestione'))
        .length;
    final breachChiusi = dataBreachAuditGdpr
        .where((elemento) => elemento.stato.toLowerCase().contains('chiuso'))
        .length;
    final breachRischioAlto = dataBreachAuditGdpr
        .where((elemento) => elemento.rischio.toLowerCase().contains('alto'))
        .length;
    final notificheGarante = dataBreachAuditGdpr
        .where((elemento) => elemento.notificatoGarante)
        .length;
    final comunicazioniInteressati = dataBreachAuditGdpr
        .where((elemento) => elemento.comunicatoInteressati)
        .length;

    final totaleLog =
        totaleLogRegistroTrattamentiAudit + totaleLogDataBreachAudit;

    final criticita =
        revisioniScadute +
        revisioniNonImpostate +
        breachAperti +
        breachInGestione +
        breachRischioAlto;

    final auditOk = trattamentiTotali > 0 && totaleLog > 0 && criticita == 0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  color: Colors.blueGrey.shade700,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riepilogo audit GDPR',
                        style: TextStyle(
                          color: Colors.blueGrey.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quadro sintetico di registri, data breach, revisioni e tracciabilità operativa.',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(
                    auditOk
                        ? Icons.verified_outlined
                        : Icons.warning_amber_rounded,
                    size: 18,
                  ),
                  label: Text(auditOk ? 'Auditabile' : 'Da verificare'),
                  backgroundColor: auditOk
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final larghezza = constraints.maxWidth;
                final cardWidth = larghezza < 720
                    ? larghezza
                    : (larghezza - 24) / 3;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: cardAuditGdpr(
                        icona: Icons.assignment_outlined,
                        titolo: 'Registro trattamenti',
                        valore: '$trattamentiTotali',
                        descrizione:
                            '$trattamentiAttivi attivi, $trattamentiNonAttivi non attivi',
                        colore: Colors.blueGrey.shade700,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: cardAuditGdpr(
                        icona: Icons.event_busy_outlined,
                        titolo: 'Revisioni',
                        valore: '${revisioniScadute + revisioniInScadenza}',
                        descrizione:
                            '$revisioniScadute scadute, $revisioniInScadenza in scadenza, $revisioniNonImpostate non impostate',
                        colore: revisioniScadute > 0
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: cardAuditGdpr(
                        icona: Icons.warning_amber_rounded,
                        titolo: 'Data breach',
                        valore: '$breachTotali',
                        descrizione:
                            '$breachAperti aperti, $breachInGestione in gestione, $breachChiusi chiusi',
                        colore: breachAperti > 0 || breachInGestione > 0
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: cardAuditGdpr(
                        icona: Icons.priority_high_outlined,
                        titolo: 'Rischio alto',
                        valore: '$breachRischioAlto',
                        descrizione: 'Eventi Data Breach con rischio alto',
                        colore: breachRischioAlto > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: cardAuditGdpr(
                        icona: Icons.outgoing_mail,
                        titolo: 'Notifiche',
                        valore:
                            '${notificheGarante + comunicazioniInteressati}',
                        descrizione:
                            '$notificheGarante Garante, $comunicazioniInteressati interessati',
                        colore: Colors.indigo.shade700,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: cardAuditGdpr(
                        icona: Icons.history,
                        titolo: 'Log tracciabilità',
                        valore: '$totaleLog',
                        descrizione:
                            '$totaleLogRegistroTrattamentiAudit log trattamenti, $totaleLogDataBreachAudit log data breach',
                        colore: totaleLog > 0
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
                AppActionButton(
                  type: AppActionButtonType.nuovo,
                  onPressed: mostraDialogNuovaVoce,
                  label: 'Nuova voce',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegistroTrattamentiPage(),
                                          ),
                                        );

                                        await caricaPrivacyGdpr();
                                        await caricaAuditGdpr();
                                      },
                                      icon: const Icon(
                                        Icons.assignment_outlined,
                                      ),
                                      label: const Text('Registro trattamenti'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegistroDataBreachPage(),
                                          ),
                                        );

                                        await caricaPrivacyGdpr();
                                        await caricaAuditGdpr();
                                      },
                                      icon: const Icon(
                                        Icons.warning_amber_rounded,
                                      ),
                                      label: const Text('Registro Data Breach'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final double larghezzaRicerca =
                                  constraints.maxWidth < 380
                                  ? constraints.maxWidth
                                  : 360;

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: larghezzaRicerca,
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
                                  AppActionButton(
                                    type: AppActionButtonType.excel,
                                    onPressed: vociPrivacyFiltrate.isEmpty
                                        ? null
                                        : esportaExcelPrivacyGdpr,
                                    label: 'Excel ($totaleFiltrato)',
                                  ),
                                  AppActionButton(
                                    type: AppActionButtonType.pdf,
                                    onPressed: vociPrivacyFiltrate.isEmpty
                                        ? null
                                        : esportaPdfPrivacyGdpr,
                                    label: 'PDF ($totaleFiltrato)',
                                  ),
                                  AppActionButton(
                                    type: AppActionButtonType.stampa,
                                    onPressed: vociPrivacyFiltrate.isEmpty
                                        ? null
                                        : stampaPrivacyGdpr,
                                    label: 'Stampa ($totaleFiltrato)',
                                  ),
                                  AppActionButton(
                                    type: AppActionButtonType.pdf,
                                    onPressed: esportaPdfRiepilogoAuditGdpr,
                                    label: 'PDF audit',
                                  ),
                                  AppActionButton(
                                    type: AppActionButtonType.stampa,
                                    onPressed: stampaRiepilogoAuditGdpr,
                                    label: 'Stampa audit',
                                  ),

                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text(
                                      'Registro consensi/privacy',
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegistroConsensiPrivacyPage(),
                                        ),
                                      );
                                    },
                                  ),

                                  AppActionButton(
                                    type: AppActionButtonType.nuovo,
                                    onPressed: mostraDialogNuovaVoce,
                                    label: 'Nuova voce',
                                  ),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.list_alt,
                                      size: 18,
                                    ),
                                    label: Text(
                                      ricercaAttiva
                                          ? '$totaleFiltrato voci trovate'
                                          : soloAttive
                                          ? '$totale voci attive'
                                          : '$totale voci totali',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    flex: 2,
                    child: SingleChildScrollView(child: riepilogoAuditGdpr()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 3,
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
