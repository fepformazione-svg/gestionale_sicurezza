import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/pdf_azienda_helper.dart';
import '../database/database_service.dart';
import '../dialogs/discente_dialog.dart';
import '../widgets/app_action_button.dart';
import 'discente_scheda_page.dart';

class ScadenzePage extends StatefulWidget {
  final String filtro;

  const ScadenzePage({super.key, this.filtro = 'tutte'});

  @override
  State<ScadenzePage> createState() => _ScadenzePageState();
}

class _ScadenzePageState extends State<ScadenzePage> {
  final TextEditingController _cercaController = TextEditingController();

  List<Map<String, dynamic>> _scadenze = [];
  bool _caricamento = true;

  static const int _scadenzePageSize = 120;
  int _totaleScadenzeFiltrate = 0;
  int _offsetScadenze = 0;
  bool _caricamentoAltre = false;
  Timer? _ricercaDebounce;

  int _conteggioTotale = 0;
  int _conteggioScadute = 0;
  int _conteggioInScadenza = 0;
  int _conteggioValide = 0;

  @override
  void initState() {
    super.initState();
    filtroStato = _filtroStatoDaFiltroWidget(widget.filtro);
    caricaScadenze();
  }

  String _filtroStatoDaFiltroWidget(String filtro) {
    switch (filtro) {
      case 'scaduti':
        return 'Scadute';
      case 'in_scadenza':
        return 'In scadenza';
      default:
        return 'Tutte';
    }
  }

  Future<void> caricaScadenze({bool append = false}) async {
    if (append) {
      if (_caricamentoAltre || _scadenze.length >= _totaleScadenzeFiltrate) {
        return;
      }

      setState(() => _caricamentoAltre = true);
    } else {
      setState(() {
        _caricamento = true;
        _offsetScadenze = 0;
      });
    }

    try {
      final ricerca = _cercaController.text.trim();
      final offset = append ? _offsetScadenze : 0;

      final riepilogo = append
          ? null
          : await DatabaseService.instance.contaScadenzeRiepilogo();

      final totaleFiltrato = append
          ? _totaleScadenzeFiltrate
          : await DatabaseService.instance.contaScadenzeFiltrate(
              ricerca: ricerca,
              filtroStato: filtroStato,
            );

      final dati = await DatabaseService.instance.caricaScadenzePaged(
        limit: _scadenzePageSize,
        offset: offset,
        ricerca: ricerca,
        filtroStato: filtroStato,
      );

      if (!mounted) return;

      setState(() {
        if (append) {
          _scadenze.addAll(dati);
        } else {
          _scadenze = dati;
          _totaleScadenzeFiltrate = totaleFiltrato;

          if (riepilogo != null) {
            _conteggioTotale = riepilogo['totale'] ?? 0;
            _conteggioScadute = riepilogo['scadute'] ?? 0;
            _conteggioInScadenza = riepilogo['in_scadenza'] ?? 0;
            _conteggioValide = riepilogo['valide'] ?? 0;
          }
        }

        _offsetScadenze = _scadenze.length;
        _caricamento = false;
        _caricamentoAltre = false;
      });
    } catch (e) {
      debugPrint('ERRORE CARICA SCADENZE: $e');

      if (!mounted) return;

      setState(() {
        if (!append) {
          _scadenze = [];
          _totaleScadenzeFiltrate = 0;
        }

        _caricamento = false;
        _caricamentoAltre = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore scadenze: $e')));
    }
  }

  void pianificaRicercaScadenze() {
    setState(() {});
    _ricercaDebounce?.cancel();
    _ricercaDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        caricaScadenze();
      }
    });
  }

  Future<void> esportaExcelScadenze() async {
    final righe = scadenzeFiltrate;

    if (righe.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna scadenza da esportare'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );

      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Scadenze'];

    excel.delete('Sheet1');

    final adesso = DateTime.now();

    final dataExport =
        '${adesso.day.toString().padLeft(2, '0')}/'
        '${adesso.month.toString().padLeft(2, '0')}/'
        '${adesso.year} '
        '${adesso.hour.toString().padLeft(2, '0')}:'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final vistaFiltrata =
        filtroStato != 'Tutte' || _cercaController.text.trim().isNotEmpty;

    sheet.appendRow([
      xls.TextCellValue(
        vistaFiltrata
            ? 'Export scadenze filtrato - ${righe.length} record - $dataExport'
            : 'Export scadenze completo - ${righe.length} record - $dataExport',
      ),
    ]);

    final intestazioni = [
      'Discente',
      'Impresa',
      'Corso',
      'Data corso',
      'Scadenza',
      'Stato',
    ];

    sheet.appendRow(
      intestazioni.map((testo) => xls.TextCellValue(testo)).toList(),
    );

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 1),
          )
          .cellStyle = xls.CellStyle(
        bold: true,
      );
    }

    for (final riga in righe) {
      final stato = calcolaStato(riga);

      sheet.appendRow([
        xls.TextCellValue(riga['discente']?.toString() ?? '-'),
        xls.TextCellValue(riga['impresa']?.toString() ?? '-'),
        xls.TextCellValue(riga['corso']?.toString() ?? '-'),
        xls.TextCellValue(formattaData(riga['data_corso'])),
        xls.TextCellValue(formattaData(riga['scadenza'])),
        xls.TextCellValue(stato),
      ]);
    }

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 36);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 18);

    final timestamp =
        '${adesso.year}_'
        '${adesso.month.toString().padLeft(2, '0')}_'
        '${adesso.day.toString().padLeft(2, '0')}_'
        '${adesso.hour.toString().padLeft(2, '0')}h'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final nomeFile = vistaFiltrata
        ? 'scadenze_export_filtrato_$timestamp.xlsx'
        : 'scadenze_export_$timestamp.xlsx';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$nomeFile');

    final bytes = excel.encode();

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
              ? 'Export Excel completato: ${righe.length} scadenze esportate dalla vista filtrata'
              : 'Export Excel completato: ${righe.length} scadenze esportate',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> esportaPdfScadenze() async {
    final righe = scadenzeFiltrate;

    if (righe.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna scadenza da esportare in PDF'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );

      return;
    }

    final pdf = pw.Document();
    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();
    final adesso = DateTime.now();

    final dataExport =
        '${adesso.day.toString().padLeft(2, '0')}/'
        '${adesso.month.toString().padLeft(2, '0')}/'
        '${adesso.year} '
        '${adesso.hour.toString().padLeft(2, '0')}:'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final vistaFiltrata =
        filtroStato != 'Tutte' || _cercaController.text.trim().isNotEmpty;

    final titoloVista = vistaFiltrata
        ? 'Export scadenze filtrato'
        : 'Export scadenze completo';

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
              'SCADENZE CORSI',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '$titoloVista - ${righe.length} record - $dataExport',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Discente',
                'Impresa',
                'Corso',
                'Data corso',
                'Scadenza',
                'Stato',
              ],
              data: righe.map((riga) {
                final stato = calcolaStato(riga);

                return [
                  riga['discente']?.toString() ?? '-',
                  riga['impresa']?.toString() ?? '-',
                  riga['corso']?.toString() ?? '-',
                  formattaData(riga['data_corso']),
                  formattaData(riga['scadenza']),
                  stato,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
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
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2.4),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.2),
              },
            ),
          ];
        },
      ),
    );

    final timestamp =
        '${adesso.year}_'
        '${adesso.month.toString().padLeft(2, '0')}_'
        '${adesso.day.toString().padLeft(2, '0')}_'
        '${adesso.hour.toString().padLeft(2, '0')}h'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final nomeFile = vistaFiltrata
        ? 'scadenze_export_filtrato_$timestamp.pdf'
        : 'scadenze_export_$timestamp.pdf';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$nomeFile');

    await file.writeAsBytes(await pdf.save(), flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export PDF completato: ${righe.length} scadenze esportate dalla vista filtrata'
              : 'Export PDF completato: ${righe.length} scadenze esportate',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> stampaScadenze() async {
    final righe = scadenzeFiltrate;

    if (righe.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna scadenza da stampare'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );

      return;
    }

    final adesso = DateTime.now();

    final dataExport =
        '${adesso.day.toString().padLeft(2, '0')}/'
        '${adesso.month.toString().padLeft(2, '0')}/'
        '${adesso.year} '
        '${adesso.hour.toString().padLeft(2, '0')}:'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final vistaFiltrata =
        filtroStato != 'Tutte' || _cercaController.text.trim().isNotEmpty;

    final titoloVista = vistaFiltrata
        ? 'Stampa scadenze filtrata'
        : 'Stampa scadenze completa';

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    await Printing.layoutPdf(
      name: 'scadenze_stampa',
      format: PdfPageFormat.a4.landscape,
      onLayout: (format) async {
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
                intestazioneAziendaPdfWidget(intestazioneAzienda),
                pw.SizedBox(height: 8),
                pw.Text(
                  'SCADENZE CORSI',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '$titoloVista - ${righe.length} record - $dataExport',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.blueGrey700,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'Discente',
                    'Impresa',
                    'Corso',
                    'Data corso',
                    'Scadenza',
                    'Stato',
                  ],
                  data: righe.map((riga) {
                    final stato = calcolaStato(riga);

                    return [
                      riga['discente']?.toString() ?? '-',
                      riga['impresa']?.toString() ?? '-',
                      riga['corso']?.toString() ?? '-',
                      formattaData(riga['data_corso']),
                      formattaData(riga['scadenza']),
                      stato,
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.centerLeft,
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
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2.4),
                    3: const pw.FlexColumnWidth(1.2),
                    4: const pw.FlexColumnWidth(1.2),
                    5: const pw.FlexColumnWidth(1.2),
                  },
                ),
              ];
            },
          ),
        );

        return pdf.save();
      },
    );
  }

  String formattaData(dynamic valore) {
    if (valore == null || valore.toString().isEmpty) {
      return '-';
    }

    try {
      final testo = valore.toString();

      DateTime data;

      // SQLITE YYYY-MM-DD
      if (testo.contains('-')) {
        data = DateTime.parse(testo);
      } else {
        return testo;
      }

      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    } catch (_) {
      return valore.toString();
    }
  }

  String calcolaStato(Map<String, dynamic> riga) {
    final statoDb = riga['stato']?.toString().toUpperCase();

    if (statoDb == 'RINNOVATO') {
      return 'Rinnovato';
    }

    if (statoDb == 'SCADUTO') {
      return 'Scaduto';
    }

    if (statoDb == 'IN SCADENZA') {
      return 'In scadenza';
    }

    if (statoDb == 'VALIDO') {
      return 'Valido';
    }

    final valore = riga['scadenza'];

    if (valore == null || valore.toString().isEmpty) {
      return 'Senza scadenza';
    }

    final scadenza = DateTime.tryParse(valore.toString());

    if (scadenza == null) {
      return 'Senza scadenza';
    }

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);

    final scadenzaPulita = DateTime(
      scadenza.year,
      scadenza.month,
      scadenza.day,
    );

    final differenza = scadenzaPulita.difference(oggiPulito).inDays;

    if (differenza < 0) {
      return 'Scaduto';
    }

    if (differenza <= 60) {
      return 'In scadenza';
    }

    return 'Valido';
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'Valido':
        return const Color(0xFF16A34A);
      case 'In scadenza':
        return const Color(0xFFF59E0B);
      case 'Scaduto':
        return const Color(0xFFDC2626);
      case 'Rinnovato':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color sfondoStato(String stato) {
    switch (stato) {
      case 'Valido':
        return const Color(0xFFEAF7EE);
      case 'In scadenza':
        return const Color(0xFFFFF7E6);
      case 'Scaduto':
        return const Color(0xFFFEE2E2);
      case 'Rinnovato':
        return const Color(0xFFEFF6FF);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> rinnovaCorso(Map<String, dynamic> riga) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Rinnovo corso'),
          content: Text(
            'Vuoi creare un nuovo rinnovo per:\n\n'
            '${riga['discente']}\n'
            '${riga['corso']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Rinnova'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.rinnovaCorso(
      idDiscente: riga['id_discente'],
      idImpresa: riga['id_impresa'],
      idCorso: riga['id_corso'],
      idDiarioOrigine: riga['diario_id'],
    );

    await caricaScadenze();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rinnovo creato correttamente')),
      );
    }
  }

  Future<void> apriSchedaDiscente(Map<String, dynamic> riga) async {
    final idDiscente = riga['id_discente'];

    if (idDiscente == null) return;

    final discente = await DatabaseService.instance.getDiscenteById(idDiscente);

    if (discente == null) return;
    if (!mounted) return;

    final risultato = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscenteSchedaPage(discente: discente)),
    );

    if (!mounted) return;

    if (risultato == 'modifica') {
      final salvato = await apriDialogDiscente(
        context: context,
        discente: discente,
      );

      if (salvato) {
        await caricaScadenze();
      }

      return;
    }

    if (risultato == true) {
      await caricaScadenze();
    }
  }

  List<Map<String, dynamic>> get scadenzeFiltrate => _scadenze;

  String filtroStato = 'Tutte';

  @override
  Widget build(BuildContext context) {
    final scadenzeVisibili = scadenzeFiltrate;
    final exportDisabilitato = scadenzeVisibili.isEmpty;

    final scadute = _conteggioScadute;
    final inScadenza = _conteggioInScadenza;
    final valide = _conteggioValide;
    final totale = _conteggioTotale;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scadenze',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ScadenzaCounterCard(
                titolo: 'Scadute',
                valore: scadute,
                colore: Color(0xFFDC2626),
                onTap: () {
                  setState(() => filtroStato = 'Scadute');
                  caricaScadenze();
                },
              ),

              _ScadenzaCounterCard(
                titolo: 'In scadenza',
                valore: inScadenza,
                colore: Color(0xFFF59E0B),
                onTap: () {
                  setState(() => filtroStato = 'In scadenza');
                  caricaScadenze();
                },
              ),

              _ScadenzaCounterCard(
                titolo: 'Valide',
                valore: valide,
                colore: Color(0xFF16A34A),
                onTap: () {
                  setState(() => filtroStato = 'Valide');
                  caricaScadenze();
                },
              ),

              _ScadenzaCounterCard(
                titolo: 'Totale',
                valore: totale,
                colore: Color(0xFF2563EB),
                onTap: () {
                  setState(() => filtroStato = 'Tutte');
                  caricaScadenze();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _cercaController,
            decoration: InputDecoration(
              hintText: 'Cerca discente, impresa o corso',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _cercaController.text.trim().isNotEmpty
                  ? IconButton(
                      tooltip: 'Pulisci ricerca',
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _cercaController.clear();
                        caricaScadenze();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => pianificaRicercaScadenze(),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FiltroScadenzaChip(
                label: 'Tutte',
                attivo: filtroStato == 'Tutte',
                onTap: () {
                  setState(() => filtroStato = 'Tutte');
                  caricaScadenze();
                },
              ),
              _FiltroScadenzaChip(
                label: 'Scadute',
                attivo: filtroStato == 'Scadute',
                onTap: () {
                  setState(() => filtroStato = 'Scadute');
                  caricaScadenze();
                },
              ),
              _FiltroScadenzaChip(
                label: 'In scadenza',
                attivo: filtroStato == 'In scadenza',
                onTap: () {
                  setState(() => filtroStato = 'In scadenza');
                  caricaScadenze();
                },
              ),
              _FiltroScadenzaChip(
                label: 'Valide',
                attivo: filtroStato == 'Valide',
                onTap: () {
                  setState(() => filtroStato = 'Valide');
                  caricaScadenze();
                },
              ),
              Tooltip(
                message: exportDisabilitato
                    ? 'Nessuna scadenza da esportare'
                    : 'Esporta ${scadenzeVisibili.length} scadenze in Excel',
                child: AppActionButton(
                  type: AppActionButtonType.excel,
                  onPressed: exportDisabilitato ? null : esportaExcelScadenze,
                  label: 'Excel (${scadenzeVisibili.length})',
                  compact: true,
                ),
              ),
              Tooltip(
                message: exportDisabilitato
                    ? 'Nessuna scadenza da esportare in PDF'
                    : 'Esporta ${scadenzeVisibili.length} scadenze in PDF',
                child: AppActionButton(
                  type: AppActionButtonType.pdf,
                  onPressed: exportDisabilitato ? null : esportaPdfScadenze,
                  label: 'PDF (${scadenzeVisibili.length})',
                  compact: true,
                ),
              ),
              Tooltip(
                message: exportDisabilitato
                    ? 'Nessuna scadenza da stampare'
                    : 'Stampa ${scadenzeVisibili.length} scadenze',
                child: AppActionButton(
                  type: AppActionButtonType.stampa,
                  onPressed: exportDisabilitato ? null : stampaScadenze,
                  label: 'Stampa (${scadenzeVisibili.length})',
                  compact: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (!_caricamento && _totaleScadenzeFiltrate > 0)
            Row(
              children: [
                Text(
                  _scadenze.length >= _totaleScadenzeFiltrate
                      ? 'Tutte le $_totaleScadenzeFiltrate scadenze sono visualizzate'
                      : 'Visualizzate ${_scadenze.length} di $_totaleScadenzeFiltrate scadenze',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_scadenze.length < _totaleScadenzeFiltrate)
                  OutlinedButton.icon(
                    onPressed: _caricamentoAltre
                        ? null
                        : () => caricaScadenze(append: true),
                    icon: _caricamentoAltre
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded, size: 18),
                    label: Text(
                      _caricamentoAltre ? 'Caricamento...' : 'Carica altri',
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 12),

          Expanded(
            child: _caricamento
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      itemCount: scadenzeVisibili.length,
                      itemBuilder: (context, index) {
                        final riga = scadenzeVisibili[index];

                        final stato = calcolaStato(riga);

                        final colore = coloreStato(stato);

                        return InkWell(
                          onDoubleTap: () {
                            apriSchedaDiscente(riga);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    riga['discente']?.toString() ?? '-',
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    riga['impresa']?.toString() ?? '-',
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(riga['corso']?.toString() ?? '-'),
                                ),

                                Expanded(
                                  child: Text(formattaData(riga['data_corso'])),
                                ),

                                Expanded(
                                  child: Text(formattaData(riga['scadenza'])),
                                ),

                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colore.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      stato,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colore,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                IconButton(
                                  onPressed: () {
                                    rinnovaCorso(riga);
                                  },
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FiltroScadenzaChip extends StatelessWidget {
  final String label;
  final bool attivo;
  final VoidCallback onTap;

  const _FiltroScadenzaChip({
    required this.label,
    required this.attivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: attivo,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: attivo ? Colors.white : const Color(0xFF374151),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: attivo ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}

class _ScadenzaCounterCard extends StatelessWidget {
  final String titolo;
  final int valore;
  final Color colore;
  final VoidCallback onTap;

  const _ScadenzaCounterCard({
    required this.titolo,
    required this.valore,
    required this.colore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 10),
            Text(
              valore.toString(),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: colore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
