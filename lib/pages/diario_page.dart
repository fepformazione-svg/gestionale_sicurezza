import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/pdf_azienda_helper.dart';

import '../database/database_service.dart';
import '../dialogs/discente_dialog.dart';
import 'discente_scheda_page.dart';
import '../widgets/app_action_button.dart';

class DiarioPage extends StatefulWidget {
  final bool soloDaFatturare;

  const DiarioPage({super.key, this.soloDaFatturare = false});

  @override
  State<DiarioPage> createState() => _DiarioPageState();
}

class _DiarioPageState extends State<DiarioPage> {
  int? rinnovoInCorsoId;
  int? invioInCorsoId;

  final TextEditingController _cercaController = TextEditingController();
  final ScrollController diarioHorizontalController = ScrollController();
  final ScrollController diarioVerticalController = ScrollController();

  List<Map<String, dynamic>> _diario = [];
  bool _caricamento = true;
  bool _soloDaFatturare = false;

  static const int _diarioPageSize = 120;
  int _totaleDiario = 0;
  int _offsetDiario = 0;
  bool _caricamentoAltri = false;
  Timer? _ricercaDebounce;

  int? _sortColumnIndex;
  bool _sortAscending = true;

  static const double wDiscente = 220;
  static const double wImpresa = 225;
  static const double wCorso = 190;
  static const double wDataCorso = 130;
  static const double wScadenza = 130;
  static const double wStato = 115;
  static const double wProt = 100;
  static const double wFattura = 125;
  static const double wInvio = 110;
  static const double wDaFatturare = 155;
  static const double wRinnova = 75;

  static const double larghezzaDiarioTabella =
      wDiscente +
      wImpresa +
      wCorso +
      wDataCorso +
      wScadenza +
      wStato +
      wProt +
      wFattura +
      wInvio +
      wDaFatturare +
      wRinnova;

  @override
  void initState() {
    super.initState();
    _soloDaFatturare = widget.soloDaFatturare;
    caricaDiario();
  }

  @override
  void didUpdateWidget(covariant DiarioPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.soloDaFatturare != widget.soloDaFatturare) {
      _soloDaFatturare = widget.soloDaFatturare;
      caricaDiario();
    }
  }

  Future<void> caricaDiario({bool append = false}) async {
    if (append) {
      if (_caricamentoAltri || _diario.length >= _totaleDiario) {
        return;
      }

      setState(() => _caricamentoAltri = true);
    } else {
      setState(() {
        _caricamento = true;
        _offsetDiario = 0;
      });
    }

    final ricerca = _cercaController.text.trim();
    final offset = append ? _offsetDiario : 0;

    final totale = append
        ? _totaleDiario
        : await DatabaseService.instance.contaDiario(
            ricerca: ricerca,
            soloDaFatturare: _soloDaFatturare,
          );

    final dati = await DatabaseService.instance.caricaDiarioPaged(
      limit: _diarioPageSize,
      offset: offset,
      ricerca: ricerca,
      soloDaFatturare: _soloDaFatturare,
    );

    if (!mounted) return;

    setState(() {
      if (append) {
        _diario.addAll(dati);
      } else {
        _diario = dati;
        _totaleDiario = totale;
      }

      _offsetDiario = _diario.length;
      _caricamento = false;
      _caricamentoAltri = false;
    });

    if (!append && diarioVerticalController.hasClients) {
      diarioVerticalController.jumpTo(0);
    }
  }

  void pianificaRicercaDiario() {
    _ricercaDebounce?.cancel();
    _ricercaDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        caricaDiario();
      }
    });
  }

  void ordina<T>(
    Comparable<T> Function(Map<String, dynamic> riga) getField,
    int columnIndex,
    bool ascending,
  ) {
    _diario.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);

      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void ordinaDaHeader<T>(
    int columnIndex,
    Comparable<T> Function(Map<String, dynamic> riga) getField,
  ) {
    final nuovaDirezione = _sortColumnIndex == columnIndex
        ? !_sortAscending
        : true;

    ordina<T>(getField, columnIndex, nuovaDirezione);
  }

  Widget cellaHeaderDiario({
    required double width,
    required Widget child,
    bool centrato = false,
    String? tooltip,
    VoidCallback? onTap,
    int? columnIndex,
  }) {
    Widget contenuto = SizedBox(
      width: width,
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: centrato ? Alignment.center : Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(centrato ? -10 : 0, 0),
            child: child,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      contenuto = Tooltip(message: tooltip, child: contenuto);
    }

    if (onTap != null) {
      contenuto = InkWell(onTap: onTap, child: contenuto);
    }

    return contenuto;
  }

  Widget headerDiarioManuale() {
    const stileHeader = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: Color(0xFF334155),
    );

    return Container(
      width: larghezzaDiarioTabella,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          cellaHeaderDiario(
            width: wDiscente,
            child: const Text(
              'Discente',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wImpresa,
            child: const Text(
              'Impresa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wCorso,
            child: const Text(
              'Corso',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wDataCorso,
            centrato: true,
            child: const Text(
              'Data corso',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wScadenza,
            centrato: true,
            child: const Text(
              'Scadenza',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wStato,
            centrato: true,
            child: const Text(
              'Stato',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wProt,
            centrato: true,
            child: const Text(
              'Prot.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: stileHeader,
            ),
          ),
          cellaHeaderDiario(
            width: wFattura,
            centrato: true,
            tooltip: 'Numero o riferimento fattura',
            child: Transform.translate(
              offset: const Offset(-3, 0),
              child: const Text(
                'Fattura',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: stileHeader,
              ),
            ),
          ),
          cellaHeaderDiario(
            width: wInvio,
            centrato: true,
            tooltip: 'Stato invio documentazione',
            child: Transform.translate(
              offset: const Offset(-6, 0),
              child: const Text(
                'Invio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: stileHeader,
              ),
            ),
          ),
          cellaHeaderDiario(
            width: wDaFatturare,
            centrato: true,
            tooltip: 'Stato da fatturare',
            child: Transform.translate(
              offset: const Offset(-12, 0),
              child: const Text(
                'Da fatturare',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: stileHeader,
              ),
            ),
          ),
          cellaHeaderDiario(
            width: wRinnova,
            centrato: true,
            tooltip: 'Rinnova corso',
            child: Transform.translate(
              offset: const Offset(1, 0),
              child: const Icon(
                Icons.refresh_rounded,
                size: 22,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? parseDataDiario(String? valore) {
    if (valore == null) return null;

    final testoData = valore.trim();
    if (testoData.isEmpty) return null;

    final iso = DateTime.tryParse(testoData);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final soloData = testoData.split(' ').first;
    final parti = soloData.split('/');

    if (parti.length != 3) return null;

    final giorno = int.tryParse(parti[0]);
    final mese = int.tryParse(parti[1]);
    final anno = int.tryParse(parti[2]);

    if (giorno == null || mese == null || anno == null) return null;

    return DateTime(anno, mese, giorno);
  }

  String statoScadenza(String? dataScadenza) {
    final scadenza = parseDataDiario(dataScadenza);

    if (scadenza == null) return 'N/D';

    final oggiBase = DateTime.now();
    final oggi = DateTime(oggiBase.year, oggiBase.month, oggiBase.day);
    final giorni = scadenza.difference(oggi).inDays;

    if (giorni < 0) return 'SCADUTO';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDO';
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'SCADUTO':
        return Colors.red;
      case 'IN SCADENZA':
        return Colors.orange;
      case 'VALIDO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<DataColumn> colonneDiarioRighe() {
    DataColumn colonnaVuota(double width) {
      return DataColumn(label: SizedBox(width: width, height: 0));
    }

    return [
      colonnaVuota(wDiscente),
      colonnaVuota(wImpresa),
      colonnaVuota(wCorso),
      colonnaVuota(wDataCorso),
      colonnaVuota(wScadenza),
      colonnaVuota(wStato),
      colonnaVuota(wProt),
      colonnaVuota(wFattura),
      colonnaVuota(wInvio),
      colonnaVuota(wDaFatturare),
      colonnaVuota(wRinnova),
    ];
  }

  Widget badge(String testo) {
    final colore = coloreStato(testo);

    return Container(
      width: 86,
      height: 28,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colore.withValues(alpha: 0.45)),
      ),
      child: Text(
        testo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colore,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget badgeDaFatturare(bool valore, {bool bloccato = false}) {
    return Tooltip(
      message: bloccato
          ? 'Fattura giÃ  inserita. Svuota prima il riferimento fattura per modificare Da fatturare'
          : valore
          ? 'Da fatturare'
          : 'Non da fatturare',
      child: Container(
        width: 98,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bloccato
              ? const Color(0xFFF1F5F9)
              : valore
              ? const Color(0xFFFFEDD5)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: bloccato
                ? const Color(0xFFCBD5E1)
                : valore
                ? const Color(0xFFF97316)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bloccato
                  ? Icons.lock_rounded
                  : valore
                  ? Icons.receipt_long_rounded
                  : Icons.check_circle_outline_rounded,
              size: 15,
              color: bloccato
                  ? const Color(0xFF94A3B8)
                  : valore
                  ? const Color(0xFFC2410C)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              valore ? 'DA FATT' : 'OK',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: bloccato
                    ? const Color(0xFF94A3B8)
                    : valore
                    ? const Color(0xFFC2410C)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String testo(dynamic valore) {
    if (valore == null) return '';
    return valore.toString();
  }

  String formattaData(dynamic valore) {
    if (valore == null || valore.toString().trim().isEmpty) return '-';

    final testoData = valore.toString().trim();

    try {
      DateTime? data;

      if (testoData.contains('/')) {
        final parti = testoData.split('/');
        if (parti.length == 3) {
          data = DateTime(
            int.parse(parti[2]),
            int.parse(parti[1]),
            int.parse(parti[0]),
          );
        }
      } else {
        data = DateTime.tryParse(testoData);
      }

      if (data == null) return testoData;

      final giorno = data.day.toString().padLeft(2, '0');
      final mese = data.month.toString().padLeft(2, '0');
      final anno = data.year.toString();

      return '$giorno/$mese/$anno';
    } catch (_) {
      return testoData;
    }
  }

  Future<void> esportaExcelDiario() async {
    if (_diario.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun corso da esportare'),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 3),
        ),
      );

      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Diario'];

    excel.delete('Sheet1');

    final adesso = DateTime.now();
    final dataExport =
        '${adesso.day.toString().padLeft(2, '0')}/'
        '${adesso.month.toString().padLeft(2, '0')}/'
        '${adesso.year} '
        '${adesso.hour.toString().padLeft(2, '0')}:'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final vistaFiltrata =
        _cercaController.text.trim().isNotEmpty || _soloDaFatturare;

    sheet.appendRow([
      xls.TextCellValue(
        vistaFiltrata
            ? 'Export diario filtrato - ${_diario.length} record - $dataExport'
            : 'Export diario - ${_diario.length} record - $dataExport',
      ),
    ]);

    sheet.appendRow([]);

    final intestazioni = [
      'Discente',
      'Impresa',
      'Corso',
      'Data corso',
      'Scadenza',
      'Stato',
      'Prot.',
      'Fattura',
      'Invio',
      'Da fatturare',
      'Rinnovo',
    ];

    sheet.appendRow(
      intestazioni.map((testo) => xls.TextCellValue(testo)).toList(),
    );

    for (final riga in _diario) {
      final discente = '${testo(riga['cognome'])} ${testo(riga['nome'])}'
          .trim();

      final stato = statoScadenza(riga['scadenza']?.toString());

      sheet.appendRow([
        xls.TextCellValue(discente),
        xls.TextCellValue(testo(riga['impresa'])),
        xls.TextCellValue(testo(riga['corso'])),
        xls.TextCellValue(formattaData(riga['data'])),
        xls.TextCellValue(formattaData(riga['scadenza'])),
        xls.TextCellValue(stato),
        xls.TextCellValue(testo(riga['prot'])),
        xls.TextCellValue(
          testo(riga['fattura']).trim().isEmpty
              ? ''
              : testo(riga['fattura']).trim(),
        ),
        xls.TextCellValue(riga['invio']?.toString() == '1' ? 'INVIATO' : 'NO'),
        xls.TextCellValue(riga['da_fatturare'] == 1 ? 'DA FATTURARE' : 'NO'),
        xls.TextCellValue(riga['rinnovo'] == 1 ? 'RINNOVATO' : ''),
      ]);
    }

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 1),
          )
          .cellStyle = xls.CellStyle(
        bold: true,
      );
    }

    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 34);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 18);
    sheet.setColumnWidth(8, 14);
    sheet.setColumnWidth(9, 18);
    sheet.setColumnWidth(10, 14);

    final bytes = excel.encode();

    if (bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la creazione del file Excel'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 3),
        ),
      );

      return;
    }

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'diario_export${vistaFiltrata ? '_filtrato' : ''}_'
        '${adesso.year}_'
        '${adesso.month.toString().padLeft(2, '0')}_'
        '${adesso.day.toString().padLeft(2, '0')}_'
        '${adesso.hour.toString().padLeft(2, '0')}'
        '${adesso.minute.toString().padLeft(2, '0')}.xlsx';

    final file = File('${directory.path}\\$nomeFile');

    await file.writeAsBytes(bytes, flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export Excel completato: ${_diario.length} corsi esportati dalla vista filtrata'
              : 'Export Excel completato: ${_diario.length} corsi esportati',
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> esportaPdfDiario() async {
    if (_diario.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun corso da esportare in PDF'),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 3),
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
        _cercaController.text.trim().isNotEmpty || _soloDaFatturare;

    final righe = _diario.map((riga) {
      final discente = '${testo(riga['cognome'])} ${testo(riga['nome'])}'
          .trim();

      final stato = statoScadenza(riga['scadenza']?.toString());

      return [
        discente,
        testo(riga['impresa']),
        testo(riga['corso']),
        formattaData(riga['data']),
        formattaData(riga['scadenza']),
        stato,
        testo(riga['prot']),
        testo(riga['fattura']).trim().isEmpty
            ? '-'
            : testo(riga['fattura']).trim(),
        riga['invio']?.toString() == '1' ? 'INVIATO' : 'NO',
        riga['da_fatturare'] == 1 ? 'DA FATT.' : 'NO',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 4),
            pw.Text(
              'DIARIO FORMAZIONE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              vistaFiltrata
                  ? 'Export diario filtrato - ${_diario.length} record - $dataExport'
                  : 'Export diario - ${_diario.length} record - $dataExport',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Discente',
                'Impresa',
                'Corso',
                'Data',
                'Scadenza',
                'Stato',
                'Prot.',
                'Fattura',
                'Invio',
                'Da fatt.',
              ],
              data: righe,
              border: pw.TableBorder.all(
                color: PdfColors.blueGrey200,
                width: 0.4,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.blueGrey900,
              ),
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
                0: const pw.FlexColumnWidth(1.7),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(1.9),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(0.8),
                6: const pw.FlexColumnWidth(0.7),
                7: const pw.FlexColumnWidth(0.8),
                8: const pw.FlexColumnWidth(0.8),
                9: const pw.FlexColumnWidth(0.8),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final nomeFile =
        'diario_export${vistaFiltrata ? '_filtrato' : ''}_'
        '${adesso.year}_'
        '${adesso.month.toString().padLeft(2, '0')}_'
        '${adesso.day.toString().padLeft(2, '0')}_'
        '${adesso.hour.toString().padLeft(2, '0')}'
        '${adesso.minute.toString().padLeft(2, '0')}.pdf';

    final file = File('${directory.path}\\$nomeFile');

    await file.writeAsBytes(await pdf.save(), flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export PDF completato: ${_diario.length} corsi esportati dalla vista filtrata'
              : 'Export PDF completato: ${_diario.length} corsi esportati',
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> stampaDiario() async {
    Tooltip.dismissAllToolTips();
    FocusManager.instance.primaryFocus?.unfocus();

    if (_diario.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun corso da stampare'),
          backgroundColor: Color(0xFFF97316),
        ),
      );

      return;
    }

    final adesso = DateTime.now();

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    String formattaDataOra(DateTime data) {
      return '${dueCifre(data.day)}/${dueCifre(data.month)}/${data.year} '
          '${dueCifre(data.hour)}:${dueCifre(data.minute)}';
    }

    String valore(dynamic valore) {
      if (valore == null) return '';
      final testo = valore.toString().trim();
      return testo.isEmpty ? '' : testo;
    }

    String dataItaliana(dynamic valoreData) {
      final testo = valore(valoreData);
      if (testo.isEmpty) return '';

      try {
        final data = DateTime.parse(testo);
        return '${dueCifre(data.day)}/${dueCifre(data.month)}/${data.year}';
      } catch (_) {
        return testo;
      }
    }

    final ricercaAttiva = _cercaController.text.trim().isNotEmpty;
    final filtroAttivo = _soloDaFatturare;
    final stampaFiltrata = ricercaAttiva || filtroAttivo;

    final dettaglioFiltro = [
      if (ricercaAttiva) 'ricerca "${_cercaController.text.trim()}"',
      if (filtroAttivo) 'solo Da fatturare',
    ].join(' Â· ');

    final infoStampa = stampaFiltrata
        ? 'Stampa diario filtrato - ${_diario.length} corsi - $dettaglioFiltro - ${formattaDataOra(adesso)}'
        : 'Stampa diario completa - ${_diario.length} corsi - ${formattaDataOra(adesso)}';

    final pdf = pw.Document();

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.blueGrey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 6),
            pw.Text(
              'DIARIO FORMAZIONE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              infoStampa,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Discente',
                'Impresa',
                'Corso',
                'Data',
                'Scadenza',
                'Stato',
                'Prot.',
                'Fattura',
                'Invio',
                'Da fatt.',
              ],
              data: _diario.map((riga) {
                final nome = valore(riga['nome']);
                final cognome = valore(riga['cognome']);
                final discente = '$cognome $nome'.trim();

                final fattura = valore(riga['fattura']).isEmpty
                    ? 'NO FATT.'
                    : valore(riga['fattura']);

                final invio = riga['invio'] == 1 ? 'INVIATO' : 'NO';
                final daFatturare = riga['da_fatturare'] == 1
                    ? 'DA FATT'
                    : 'OK';

                return [
                  discente,
                  valore(riga['impresa']),
                  valore(riga['corso']),
                  dataItaliana(riga['data']),
                  dataItaliana(riga['scadenza']),
                  valore(riga['stato']),
                  valore(riga['prot']),
                  fattura,
                  invio,
                  daFatturare,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.blueGrey900,
              ),
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
              columnWidths: const {
                0: pw.FlexColumnWidth(1.7),
                1: pw.FlexColumnWidth(1.6),
                2: pw.FlexColumnWidth(2.1),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(0.8),
                6: pw.FlexColumnWidth(0.8),
                7: pw.FlexColumnWidth(1.0),
                8: pw.FlexColumnWidth(0.8),
                9: pw.FlexColumnWidth(0.8),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: stampaFiltrata ? 'diario_stampa_filtrato.pdf' : 'diario_stampa.pdf',
      onLayout: (format) async => pdf.save(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stampaFiltrata
              ? 'Stampa Diario avviata: ${_diario.length} corsi dalla vista filtrata'
              : 'Stampa Diario avviata: ${_diario.length} corsi',
        ),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  @override
  void dispose() {
    _cercaController.dispose();
    diarioHorizontalController.dispose();
    diarioVerticalController.dispose();
    super.dispose();
  }

  Future<void> apriSchedaDiscente(Map<String, dynamic> riga) async {
    final idDiscente = riga['discente_id'];

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
        await caricaDiario();
      }

      return;
    }

    if (risultato == true) {
      await caricaDiario();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportDisabilitato = _diario.isEmpty;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DIARIO CORSI',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _cercaController,
              onChanged: (_) => pianificaRicercaDiario(),
              decoration: InputDecoration(
                hintText: 'Cerca discente, impresa, corso, protocollo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _cercaController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Azzera ricerca',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cercaController.clear();
                          caricaDiario();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    spacing: 12,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_cercaController.text.trim().isNotEmpty)
                            Tooltip(
                              message: 'Rimuovi solo la ricerca attiva',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  _cercaController.clear();
                                  caricaDiario();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.manage_search_rounded,
                                        size: 15,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 260,
                                        ),
                                        child: Text(
                                          'Ricerca attiva: ${_cercaController.text.trim()}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (!_soloDaFatturare)
                            Tooltip(
                              message: 'Mostra solo i corsi da fatturare',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  setState(() {
                                    _soloDaFatturare = true;
                                  });

                                  caricaDiario();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 15,
                                        color: Color(0xFFF97316),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Da fatturare',
                                        style: TextStyle(
                                          color: Color(0xFFF97316),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (_soloDaFatturare)
                            Tooltip(
                              message: 'Mostra anche i corsi non da fatturare',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  setState(() {
                                    _soloDaFatturare = false;
                                  });

                                  caricaDiario();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 15,
                                        color: Color(0xFFF97316),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Da fatturare',
                                        style: TextStyle(
                                          color: Color(0xFFF97316),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Color(0xFFF97316),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          Tooltip(
                            message:
                                _cercaController.text.trim().isNotEmpty ||
                                    _soloDaFatturare
                                ? 'Rimuovi ricerca e filtro Da fatturare'
                                : 'Nessuna ricerca o filtro attivo',
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _cercaController.clear();
                                  _soloDaFatturare = false;
                                });

                                caricaDiario();
                              },
                              icon: Icon(
                                _cercaController.text.trim().isNotEmpty ||
                                        _soloDaFatturare
                                    ? Icons.filter_alt_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _cercaController.text.trim().isNotEmpty
                                    ? 'Mostra tutto'
                                    : _soloDaFatturare
                                    ? 'Mostra tutto'
                                    : 'Tutto visibile',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    _cercaController.text.trim().isNotEmpty ||
                                        _soloDaFatturare
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                                side: BorderSide(
                                  color:
                                      _cercaController.text.trim().isNotEmpty ||
                                          _soloDaFatturare
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),

                          Tooltip(
                            message: exportDisabilitato
                                ? 'Nessun corso da esportare'
                                : 'Esporta ${_diario.length} corsi in Excel',
                            child: AppActionButton(
                              type: AppActionButtonType.excel,
                              onPressed: exportDisabilitato
                                  ? null
                                  : esportaExcelDiario,
                              label: 'Excel (${_diario.length})',
                              compact: true,
                            ),
                          ),

                          Tooltip(
                            message: exportDisabilitato
                                ? 'Nessun corso da esportare in PDF'
                                : 'Esporta ${_diario.length} corsi in PDF',
                            child: AppActionButton(
                              type: AppActionButtonType.pdf,
                              onPressed: exportDisabilitato
                                  ? null
                                  : esportaPdfDiario,
                              label: 'PDF (${_diario.length})',
                              compact: true,
                            ),
                          ),

                          Tooltip(
                            message: exportDisabilitato
                                ? 'Nessun corso da stampare'
                                : 'Stampa ${_diario.length} corsi visualizzati',
                            child: AppActionButton(
                              type: AppActionButtonType.stampa,
                              onPressed: exportDisabilitato
                                  ? null
                                  : stampaDiario,
                              label: 'Stampa (${_diario.length})',
                              compact: true,
                            ),
                          ),
                        ],
                      ),

                      if (constraints.maxWidth >= 430)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth < 520 ? 190 : 320,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth < 520 ? 9 : 12,
                              vertical: constraints.maxWidth < 520 ? 6 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: _soloDaFatturare
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _soloDaFatturare
                                    ? const Color(0xFFFED7AA)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _soloDaFatturare
                                      ? Icons.receipt_long_rounded
                                      : Icons.format_list_bulleted_rounded,
                                  size: 15,
                                  color: _soloDaFatturare
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _cercaController.text.trim().isNotEmpty
                                        ? _soloDaFatturare
                                              ? _diario.length == 1
                                                    ? '1 corso da fatturare trovato'
                                                    : '${_diario.length} corsi da fatturare trovati'
                                              : _diario.length == 1
                                              ? '1 corso trovato'
                                              : '${_diario.length} corsi trovati'
                                        : _soloDaFatturare
                                        ? _diario.length == 1
                                              ? '1 corso da fatturare'
                                              : '${_diario.length} corsi da fatturare'
                                        : _diario.length == 1
                                        ? '1 corso visualizzato'
                                        : '${_diario.length} corsi visualizzati',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _soloDaFatturare
                                          ? const Color(0xFFF97316)
                                          : const Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            if (!_caricamento && _totaleDiario > 0)
              Row(
                children: [
                  Text(
                    _diario.length >= _totaleDiario
                        ? 'Tutti i $_totaleDiario corsi sono visualizzati'
                        : 'Visualizzati ${_diario.length} di $_totaleDiario corsi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_diario.length < _totaleDiario)
                    OutlinedButton.icon(
                      onPressed: _caricamentoAltri
                          ? null
                          : () => caricaDiario(append: true),
                      icon: _caricamentoAltri
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more_rounded, size: 18),
                      label: Text(
                        _caricamentoAltri ? 'Caricamento...' : 'Carica altri',
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 12),

            Expanded(
              child: _caricamento
                  ? const Center(child: CircularProgressIndicator())
                  : _diario.isEmpty
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _soloDaFatturare
                                    ? Icons.receipt_long_rounded
                                    : _cercaController.text.trim().isNotEmpty
                                    ? Icons.manage_search_rounded
                                    : Icons.menu_book_rounded,
                                size: 46,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(height: 14),
                              Builder(
                                builder: (context) {
                                  final ricerca = _cercaController.text.trim();
                                  final ricercaAttiva = ricerca.isNotEmpty;
                                  final filtroAttivo = _soloDaFatturare;

                                  final titolo = ricercaAttiva && filtroAttivo
                                      ? 'Nessun corso da fatturare trovato'
                                      : ricercaAttiva
                                      ? 'Nessun corso trovato'
                                      : filtroAttivo
                                      ? 'Nessun corso da fatturare'
                                      : 'Nessun corso presente nel diario';

                                  return Text(
                                    titolo,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final ricerca = _cercaController.text.trim();
                                  final ricercaAttiva = ricerca.isNotEmpty;
                                  final filtroAttivo = _soloDaFatturare;

                                  final descrizione =
                                      ricercaAttiva && filtroAttivo
                                      ? 'La ricerca "$ricerca" non ha trovato corsi tra quelli da fatturare.'
                                      : ricercaAttiva
                                      ? 'Nessun risultato per "$ricerca". Prova a modificare o azzerare la ricerca.'
                                      : filtroAttivo
                                      ? 'Al momento non ci sono corsi segnati come da fatturare.'
                                      : 'Quando saranno presenti corsi nel diario, verranno visualizzati qui.';

                                  return Text(
                                    descrizione,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  );
                                },
                              ),
                              if (_cercaController.text.trim().isNotEmpty ||
                                  _soloDaFatturare) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF334155),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _cercaController.clear();
                                      _soloDaFatturare = false;
                                    });

                                    caricaDiario();
                                  },
                                  icon: const Icon(
                                    Icons.filter_alt_off_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Azzera ricerca e filtro'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            controller: diarioHorizontalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            interactive: true,
                            child: SingleChildScrollView(
                              controller: diarioHorizontalController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: larghezzaDiarioTabella,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    headerDiarioManuale(),
                                    Expanded(
                                      child: Scrollbar(
                                        controller: diarioVerticalController,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        interactive: true,
                                        child: SingleChildScrollView(
                                          controller: diarioVerticalController,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: DataTable(
                                              headingRowHeight: 0,
                                              columnSpacing: 0,
                                              horizontalMargin: 0,
                                              showCheckboxColumn: false,
                                              sortColumnIndex: _sortColumnIndex,
                                              sortAscending: _sortAscending,
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                    Colors.grey.shade100,
                                                  ),
                                              columns: colonneDiarioRighe(),
                                              rows: _diario.map((riga) {
                                                final idDiario =
                                                    riga['id'] as int;
                                                final fatturaPresente = testo(
                                                  riga['fattura'],
                                                ).trim().isNotEmpty;
                                                final rinnovoQuestaRiga =
                                                    rinnovoInCorsoId ==
                                                    idDiario;
                                                final invioQuestaRiga =
                                                    invioInCorsoId == idDiario;

                                                final stato = statoScadenza(
                                                  riga['scadenza']?.toString(),
                                                );

                                                return DataRow(
                                                  color:
                                                      WidgetStateProperty.resolveWith<
                                                        Color?
                                                      >((states) {
                                                        if (rinnovoQuestaRiga) {
                                                          return const Color(
                                                            0xFFEFF6FF,
                                                          );
                                                        }

                                                        return null;
                                                      }),
                                                  cells: [
                                                    DataCell(
                                                      SizedBox(
                                                        width: 150,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 8,
                                                              ),
                                                          child: InkWell(
                                                            mouseCursor:
                                                                SystemMouseCursors
                                                                    .click,
                                                            onTap: () {
                                                              apriSchedaDiscente(
                                                                riga,
                                                              );
                                                            },
                                                            child: Text(
                                                              '${testo(riga['cognome'])} ${testo(riga['nome'])}'
                                                                  .trim(),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF2563EB,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: wImpresa,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 8,
                                                              ),
                                                          child: Text(
                                                            testo(
                                                              riga['impresa'],
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 180,
                                                        child: Text(
                                                          testo(riga['corso']),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 105,
                                                        child: Center(
                                                          child: Text(
                                                            formattaData(
                                                              riga['data'],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 105,
                                                        child: Center(
                                                          child: Text(
                                                            formattaData(
                                                              riga['scadenza'],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 90,
                                                        child: Center(
                                                          child: badge(stato),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 70,
                                                        child: Center(
                                                          child: Text(
                                                            testo(riga['prot']),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 95,
                                                        child: Center(
                                                          child: Tooltip(
                                                            message:
                                                                testo(
                                                                  riga['fattura'],
                                                                ).trim().isEmpty
                                                                ? 'Nessuna fattura inserita. Clicca per aggiungere un riferimento'
                                                                : 'Modifica o svuota riferimento fattura: ${testo(riga['fattura']).trim()}',
                                                            child:
                                                                testo(
                                                                  riga['fattura'],
                                                                ).trim().isEmpty
                                                                ? Container(
                                                                    width: 82,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          5,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFFFF7ED,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            999,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFFFDBA74,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: const Text(
                                                                      'NO FATT.',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                        color: Color(
                                                                          0xFFC2410C,
                                                                        ),
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w800,
                                                                        letterSpacing:
                                                                            0.2,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container(
                                                                    width: 82,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          5,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFECFDF5,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            999,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFF10B981,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      testo(
                                                                        riga['fattura'],
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: const TextStyle(
                                                                        color: Color(
                                                                          0xFF047857,
                                                                        ),
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w800,
                                                                        letterSpacing:
                                                                            0.2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () async {
                                                        Tooltip.dismissAllToolTips();
                                                        FocusManager
                                                            .instance
                                                            .primaryFocus
                                                            ?.unfocus();

                                                        final controller =
                                                            TextEditingController(
                                                              text: testo(
                                                                riga['fattura'],
                                                              ),
                                                            );

                                                        final nuovaFattura = await showDialog<String>(
                                                          context: context,
                                                          builder: (dialogContext) {
                                                            return AlertDialog(
                                                              title: const Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .receipt_long_rounded,
                                                                    color: Color(
                                                                      0xFF047857,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    'Riferimento fattura',
                                                                  ),
                                                                ],
                                                              ),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  TextField(
                                                                    controller:
                                                                        controller,
                                                                    autofocus:
                                                                        true,
                                                                    decoration: const InputDecoration(
                                                                      labelText:
                                                                          'Numero o riferimento fattura',
                                                                      hintText:
                                                                          'Es. 18/26 oppure FT 123',
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  const Text(
                                                                    'Salvando una fattura, il corso verrÃ  rimosso automaticamente dai Da fatturare.',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12.5,
                                                                      color: Color(
                                                                        0xFF64748B,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                      dialogContext,
                                                                    ).pop(null);
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                        'Annulla',
                                                                      ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () async {
                                                                    final confermaSvuota = await showDialog<bool>(
                                                                      context:
                                                                          dialogContext,
                                                                      builder:
                                                                          (
                                                                            confirmContext,
                                                                          ) {
                                                                            return AlertDialog(
                                                                              title: const Row(
                                                                                children: [
                                                                                  Icon(
                                                                                    Icons.warning_amber_rounded,
                                                                                    color: Color(
                                                                                      0xFFF97316,
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: 10,
                                                                                  ),
                                                                                  Text(
                                                                                    'Svuotare fattura?',
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              content: const Text(
                                                                                'Vuoi rimuovere il riferimento fattura da questo corso? Dopo la rimozione, il campo Da fatturare tornerÃ  modificabile manualmente.',
                                                                              ),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Navigator.of(
                                                                                      confirmContext,
                                                                                    ).pop(
                                                                                      false,
                                                                                    );
                                                                                  },
                                                                                  child: const Text(
                                                                                    'Annulla',
                                                                                  ),
                                                                                ),
                                                                                FilledButton.icon(
                                                                                  onPressed: () {
                                                                                    Navigator.of(
                                                                                      confirmContext,
                                                                                    ).pop(
                                                                                      true,
                                                                                    );
                                                                                  },
                                                                                  style: FilledButton.styleFrom(
                                                                                    backgroundColor: const Color(
                                                                                      0xFFDC2626,
                                                                                    ),
                                                                                    foregroundColor: Colors.white,
                                                                                  ),
                                                                                  icon: const Icon(
                                                                                    Icons.delete_outline_rounded,
                                                                                    size: 18,
                                                                                  ),
                                                                                  label: const Text(
                                                                                    'Svuota',
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                    );

                                                                    if (confermaSvuota ==
                                                                        true) {
                                                                      if (!dialogContext
                                                                          .mounted) {
                                                                        return;
                                                                      }

                                                                      Navigator.of(
                                                                        dialogContext,
                                                                      ).pop('');
                                                                    }
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                        'Svuota',
                                                                      ),
                                                                ),
                                                                FilledButton.icon(
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                      dialogContext,
                                                                    ).pop(
                                                                      controller
                                                                          .text
                                                                          .trim(),
                                                                    );
                                                                  },
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .save_rounded,
                                                                    size: 18,
                                                                  ),
                                                                  label:
                                                                      const Text(
                                                                        'Salva',
                                                                      ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );

                                                        controller.dispose();

                                                        if (nuovaFattura ==
                                                            null) {
                                                          return;
                                                        }

                                                        Tooltip.dismissAllToolTips();
                                                        FocusManager
                                                            .instance
                                                            .primaryFocus
                                                            ?.unfocus();

                                                        await DatabaseService
                                                            .instance
                                                            .aggiornaFatturaDiario(
                                                              idDiario:
                                                                  idDiario,
                                                              fattura:
                                                                  nuovaFattura,
                                                            );

                                                        if (nuovaFattura
                                                            .trim()
                                                            .isNotEmpty) {
                                                          await DatabaseService
                                                              .instance
                                                              .aggiornaDaFatturareDiario(
                                                                id: idDiario,
                                                                valore: false,
                                                              );
                                                        }

                                                        await caricaDiario();

                                                        if (!mounted) return;

                                                        ScaffoldMessenger.of(
                                                          this.context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              nuovaFattura
                                                                      .trim()
                                                                      .isEmpty
                                                                  ? 'Riferimento fattura rimosso. Il campo Da fatturare torna modificabile manualmente.'
                                                                  : 'Riferimento fattura salvato. Il corso Ã¨ stato rimosso dai Da fatturare.',
                                                            ),
                                                            backgroundColor:
                                                                nuovaFattura
                                                                    .trim()
                                                                    .isEmpty
                                                                ? const Color(
                                                                    0xFF64748B,
                                                                  )
                                                                : const Color(
                                                                    0xFF047857,
                                                                  ),
                                                            duration:
                                                                const Duration(
                                                                  seconds: 3,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 75,
                                                        child: Center(
                                                          child: Tooltip(
                                                            message:
                                                                invioQuestaRiga
                                                                ? 'Salvataggio invio in corso...'
                                                                : riga['invio']
                                                                          ?.toString() ==
                                                                      '1'
                                                                ? 'Invio giÃ  registrato. Clicca per rimuovere lo stato inviato'
                                                                : 'Nessun invio registrato. Clicca per segnare come inviato',
                                                            child:
                                                                invioQuestaRiga
                                                                ? Container(
                                                                    width: 72,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          5,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFF1F5F9,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            999,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFFCBD5E1,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: const SizedBox(
                                                                      width: 14,
                                                                      height:
                                                                          14,
                                                                      child: Center(
                                                                        child: SizedBox(
                                                                          width:
                                                                              13,
                                                                          height:
                                                                              13,
                                                                          child: CircularProgressIndicator(
                                                                            strokeWidth:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : riga['invio']
                                                                          ?.toString() ==
                                                                      '1'
                                                                ? Container(
                                                                    width: 72,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          5,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFE0F2FE,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            999,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFF0284C7,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: const Text(
                                                                      'INVIATO',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                        color: Color(
                                                                          0xFF0369A1,
                                                                        ),
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w800,
                                                                        letterSpacing:
                                                                            0.2,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container(
                                                                    width: 72,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          5,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFF1F5F9,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            999,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFFCBD5E1,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: const Text(
                                                                      'NO',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                        color: Color(
                                                                          0xFF64748B,
                                                                        ),
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w800,
                                                                        letterSpacing:
                                                                            0.2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () async {
                                                        final invioAttivo =
                                                            riga['invio']
                                                                ?.toString() ==
                                                            '1';
                                                        final nuovoValore =
                                                            invioAttivo ? 0 : 1;

                                                        setState(() {
                                                          invioInCorsoId =
                                                              idDiario;
                                                        });

                                                        try {
                                                          await DatabaseService
                                                              .instance
                                                              .aggiornaInvioDiario(
                                                                idDiario:
                                                                    idDiario,
                                                                invio:
                                                                    nuovoValore,
                                                              );

                                                          await caricaDiario();

                                                          if (!mounted) return;

                                                          ScaffoldMessenger.of(
                                                            this.context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                nuovoValore == 1
                                                                    ? 'Invio documentazione registrato.'
                                                                    : 'Stato invio documentazione rimosso.',
                                                              ),
                                                              backgroundColor:
                                                                  nuovoValore ==
                                                                      1
                                                                  ? const Color(
                                                                      0xFF2563EB,
                                                                    )
                                                                  : const Color(
                                                                      0xFF64748B,
                                                                    ),
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 3,
                                                                  ),
                                                            ),
                                                          );
                                                        } catch (errore) {
                                                          if (!mounted) return;

                                                          ScaffoldMessenger.of(
                                                            this.context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Errore aggiornamento invio: $errore',
                                                              ),
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFFDC2626,
                                                                  ),
                                                            ),
                                                          );
                                                        } finally {
                                                          if (mounted) {
                                                            setState(() {
                                                              invioInCorsoId =
                                                                  null;
                                                            });
                                                          }
                                                        }
                                                      },
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 108,
                                                        child: Center(
                                                          child: Tooltip(
                                                            message:
                                                                fatturaPresente
                                                                ? 'Fattura giÃ  inserita. Svuota prima il riferimento fattura per modificare Da fatturare'
                                                                : riga['da_fatturare'] ==
                                                                      1
                                                                ? 'Il corso Ã¨ da fatturare. Clicca per rimuoverlo dai Da fatturare'
                                                                : 'Il corso non Ã¨ da fatturare. Clicca per segnarlo come Da fatturare',
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    999,
                                                                  ),
                                                              onTap:
                                                                  fatturaPresente
                                                                  ? () {
                                                                      ScaffoldMessenger.of(
                                                                        this.context,
                                                                      ).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text(
                                                                            'Fattura giÃ  inserita. Per modificare Da fatturare, svuota prima il riferimento fattura.',
                                                                          ),
                                                                          backgroundColor: Color(
                                                                            0xFF64748B,
                                                                          ),
                                                                          duration: Duration(
                                                                            seconds:
                                                                                3,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  : () async {
                                                                      final attualmenteDaFatturare =
                                                                          riga['da_fatturare'] ==
                                                                          1;

                                                                      await DatabaseService
                                                                          .instance
                                                                          .aggiornaDaFatturareDiario(
                                                                            id: idDiario,
                                                                            valore:
                                                                                !attualmenteDaFatturare,
                                                                          );

                                                                      await caricaDiario();

                                                                      if (!mounted) {
                                                                        return;
                                                                      }

                                                                      ScaffoldMessenger.of(
                                                                        this.context,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            !attualmenteDaFatturare
                                                                                ? 'Corso segnato come Da fatturare.'
                                                                                : 'Corso rimosso dai Da fatturare.',
                                                                          ),
                                                                          backgroundColor:
                                                                              !attualmenteDaFatturare
                                                                              ? const Color(
                                                                                  0xFFF97316,
                                                                                )
                                                                              : const Color(
                                                                                  0xFF64748B,
                                                                                ),
                                                                          duration: const Duration(
                                                                            seconds:
                                                                                3,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                              child: badgeDaFatturare(
                                                                riga['da_fatturare'] ==
                                                                    1,
                                                                bloccato:
                                                                    fatturaPresente,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: wRinnova,
                                                        child: Center(
                                                          child: Transform.translate(
                                                            offset:
                                                                const Offset(
                                                                  -8,
                                                                  0,
                                                                ),
                                                            child: IconButton(
                                                              tooltip:
                                                                  rinnovoQuestaRiga
                                                                  ? 'Rinnovo corso in corso...'
                                                                  : rinnovoInCorsoId !=
                                                                        null
                                                                  ? 'Attendi il completamento del rinnovo giÃ  avviato'
                                                                  : 'Crea rinnovo corso',
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minWidth:
                                                                        38,
                                                                    minHeight:
                                                                        38,
                                                                  ),
                                                              splashRadius: 22,
                                                              icon:
                                                                  rinnovoQuestaRiga
                                                                  ? const SizedBox(
                                                                      width: 18,
                                                                      height:
                                                                          18,
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2.2,
                                                                      ),
                                                                    )
                                                                  : Container(
                                                                      width: 34,
                                                                      height:
                                                                          34,
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            rinnovoInCorsoId !=
                                                                                null
                                                                            ? const Color(
                                                                                0xFFF1F5F9,
                                                                              )
                                                                            : const Color(
                                                                                0xFFEFF6FF,
                                                                              ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              999,
                                                                            ),
                                                                        border: Border.all(
                                                                          color:
                                                                              rinnovoInCorsoId !=
                                                                                  null
                                                                              ? const Color(
                                                                                  0xFFCBD5E1,
                                                                                )
                                                                              : const Color(
                                                                                  0xFFBFDBFE,
                                                                                ),
                                                                        ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .refresh_rounded,
                                                                        size:
                                                                            19,
                                                                        color:
                                                                            rinnovoInCorsoId !=
                                                                                null
                                                                            ? const Color(
                                                                                0xFF94A3B8,
                                                                              )
                                                                            : const Color(
                                                                                0xFF2563EB,
                                                                              ),
                                                                      ),
                                                                    ),
                                                              onPressed:
                                                                  rinnovoInCorsoId !=
                                                                      null
                                                                  ? null
                                                                  : () async {
                                                                      final confermato = await showDialog<bool>(
                                                                        context:
                                                                            context,
                                                                        barrierDismissible:
                                                                            false,
                                                                        builder:
                                                                            (
                                                                              dialogContext,
                                                                            ) {
                                                                              return AlertDialog(
                                                                                title: const Row(
                                                                                  children: [
                                                                                    Icon(
                                                                                      Icons.refresh_rounded,
                                                                                      color: Color(
                                                                                        0xFF2563EB,
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: 10,
                                                                                    ),
                                                                                    Text(
                                                                                      'Conferma rinnovo corso',
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                content: Text(
                                                                                  'Vuoi creare un nuovo rinnovo per il corso '
                                                                                  '"${testo(riga['corso'])}" di '
                                                                                  '${testo(riga['cognome'])} ${testo(riga['nome'])}?\n\n'
                                                                                  'Il rinnovo verrÃ  aggiunto come nuovo record nel Diario.',
                                                                                ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed: () {
                                                                                      Navigator.of(
                                                                                        dialogContext,
                                                                                      ).pop(
                                                                                        false,
                                                                                      );
                                                                                    },
                                                                                    child: const Text(
                                                                                      'Annulla',
                                                                                    ),
                                                                                  ),
                                                                                  FilledButton.icon(
                                                                                    onPressed: () {
                                                                                      Navigator.of(
                                                                                        dialogContext,
                                                                                      ).pop(
                                                                                        true,
                                                                                      );
                                                                                    },
                                                                                    icon: const Icon(
                                                                                      Icons.refresh_rounded,
                                                                                      size: 18,
                                                                                    ),
                                                                                    label: const Text(
                                                                                      'Crea rinnovo',
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                      );

                                                                      if (!mounted) {
                                                                        return;
                                                                      }
                                                                      if (confermato !=
                                                                          true) {
                                                                        return;
                                                                      }

                                                                      final discenteId =
                                                                          riga['discente_id'];
                                                                      final impresaId =
                                                                          riga['impresa_id'];
                                                                      final corsoId =
                                                                          riga['corso_id'];

                                                                      if (discenteId ==
                                                                              null ||
                                                                          impresaId ==
                                                                              null ||
                                                                          corsoId ==
                                                                              null) {
                                                                        ScaffoldMessenger.of(
                                                                          this.context,
                                                                        ).showSnackBar(
                                                                          const SnackBar(
                                                                            content: Text(
                                                                              'Impossibile rinnovare: discente, impresa o corso mancanti.',
                                                                            ),
                                                                          ),
                                                                        );
                                                                        return;
                                                                      }

                                                                      setState(() {
                                                                        rinnovoInCorsoId =
                                                                            idDiario;
                                                                      });

                                                                      try {
                                                                        await DatabaseService.instance.rinnovaCorso(
                                                                          idDiscente:
                                                                              discenteId
                                                                                  as int,
                                                                          idImpresa:
                                                                              impresaId
                                                                                  as int,
                                                                          idCorso:
                                                                              corsoId
                                                                                  as int,
                                                                        );

                                                                        await caricaDiario();

                                                                        if (!mounted) {
                                                                          return;
                                                                        }

                                                                        ScaffoldMessenger.of(
                                                                          this.context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              'Rinnovo corso creato: ${testo(riga['corso'])} â€” '
                                                                              '${testo(riga['cognome'])} ${testo(riga['nome'])}',
                                                                            ),
                                                                            backgroundColor: const Color(
                                                                              0xFF16A34A,
                                                                            ),
                                                                            duration: const Duration(
                                                                              seconds: 4,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      } catch (
                                                                        errore
                                                                      ) {
                                                                        if (!mounted) {
                                                                          return;
                                                                        }

                                                                        ScaffoldMessenger.of(
                                                                          this.context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              'Errore durante il rinnovo: $errore',
                                                                            ),
                                                                            backgroundColor: const Color(
                                                                              0xFFDC2626,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      } finally {
                                                                        if (mounted) {
                                                                          setState(
                                                                            () {
                                                                              rinnovoInCorsoId = null;
                                                                            },
                                                                          );
                                                                        }
                                                                      }
                                                                    },
                                                            ), // IconButton
                                                          ), // Transform.translate
                                                        ), // Center
                                                      ), // SizedBox
                                                      onTap: () {},
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ), // DataTable righe
                                          ), // Padding
                                        ), // SingleChildScrollView verticale // SingleChildScrollView verticale
                                      ), // Scrollbar verticale
                                    ), // Expanded
                                  ],
                                ), // Column
                              ), // SizedBox larghezzaDiarioTabella
                            ), // SingleChildScrollView orizzontale
                          ); // Scrollbar orizzontale
                        },
                      ), // LayoutBuilder
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
