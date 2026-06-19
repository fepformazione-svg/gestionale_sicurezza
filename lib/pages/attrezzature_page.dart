import 'package:flutter/material.dart';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attrezzatura.dart';
import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

class AttrezzaturePage extends StatefulWidget {
  const AttrezzaturePage({super.key});

  @override
  State<AttrezzaturePage> createState() => _AttrezzaturePageState();
}

class _AttrezzaturePageState extends State<AttrezzaturePage> {
  final cercaController = TextEditingController();
  bool soloAttive = true;

  List<Attrezzatura> attrezzature = [];
  bool caricamento = true;

  List<Attrezzatura> get attrezzatureFiltrate {
    final ricerca = cercaController.text.trim().toLowerCase();

    final filtratePerStato = soloAttive
        ? attrezzature.where((attrezzatura) => attrezzatura.attiva).toList()
        : attrezzature;

    if (ricerca.isEmpty) {
      return filtratePerStato;
    }

    return filtratePerStato.where((attrezzatura) {
      final testo = [
        attrezzatura.denominazione,
        attrezzatura.categoria,
        attrezzatura.codice,
        attrezzatura.descrizione,
        attrezzatura.quantita.toString(),
        attrezzatura.unitaMisura,
        attrezzatura.attiva ? 'attiva' : 'non attiva',
        attrezzatura.note,
      ].join(' ').toLowerCase();

      return testo.contains(ricerca);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    caricaAttrezzature();
  }

  @override
  void dispose() {
    cercaController.dispose();
    super.dispose();
  }

  Future<void> caricaAttrezzature() async {
    final dati = await AppDatabase.instance.getAttrezzature();

    if (!mounted) return;

    setState(() {
      attrezzature = dati;
      caricamento = false;
    });
  }

  Future<void> apriDialogNuovaAttrezzatura() async {
    final salvata = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AttrezzaturaDialog(),
    );

    if (salvata != true) return;

    await caricaAttrezzature();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attrezzatura salvata correttamente.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> apriDialogModificaAttrezzatura(Attrezzatura attrezzatura) async {
    final salvata = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AttrezzaturaDialog(attrezzatura: attrezzatura),
    );

    if (salvata != true) return;

    await caricaAttrezzature();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attrezzatura aggiornata correttamente.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> cambiaStatoAttrezzatura(Attrezzatura attrezzatura) async {
    final nuovoStato = !attrezzatura.attiva;

    await AppDatabase.instance.aggiornaStatoAttrezzatura(
      id: attrezzatura.id!,
      attiva: nuovoStato ? 1 : 0,
    );

    await caricaAttrezzature();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuovoStato
              ? 'Attrezzatura riattivata correttamente.'
              : 'Attrezzatura disattivata correttamente.',
        ),
        backgroundColor: nuovoStato
            ? const Color(0xFF16A34A)
            : const Color(0xFF64748B),
      ),
    );
  }

  Future<void> esportaExcelAttrezzature() async {
    final dati = attrezzatureFiltrate;

    if (dati.isEmpty) {
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Attrezzature'];

    excel.setDefaultSheet('Attrezzature');

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final ora = DateTime.now();
    final dataOra =
        '${dueCifre(ora.day)}/${dueCifre(ora.month)}/${ora.year} '
        '${dueCifre(ora.hour)}:${dueCifre(ora.minute)}';

    final ricerca = cercaController.text.trim();

    final info = [
      soloAttive ? 'Solo attive' : 'Tutte',
      if (ricerca.isNotEmpty) 'Ricerca: "$ricerca"',
      '${dati.length} ${dati.length == 1 ? 'attrezzatura' : 'attrezzature'}',
      'Esportazione del $dataOra',
    ].join(' - ');

    sheet.cell(xls.CellIndex.indexByString('A1')).value = xls.TextCellValue(
      info,
    );

    final intestazioni = [
      'Denominazione',
      'Categoria',
      'Codice',
      'Descrizione',
      'Quantità',
      'Unità',
      'Stato',
      'Note',
    ];

    for (var i = 0; i < intestazioni.length; i++) {
      final cella = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );
      cella.value = xls.TextCellValue(intestazioni[i]);
      cella.cellStyle = xls.CellStyle(bold: true);
    }

    for (var i = 0; i < dati.length; i++) {
      final attrezzatura = dati[i];
      final rowIndex = i + 2;

      final valori = [
        attrezzatura.denominazione,
        attrezzatura.categoria,
        attrezzatura.codice,
        attrezzatura.descrizione,
        attrezzatura.quantita.toString(),
        attrezzatura.unitaMisura,
        attrezzatura.attiva ? 'ATTIVA' : 'NON ATTIVA',
        attrezzatura.note,
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

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 38);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 32);

    final bytes = excel.encode();
    if (bytes == null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();

    final nomeFiltro = ricerca.isNotEmpty ? '_filtrato' : '';
    final nomeFile =
        'attrezzature_export$nomeFiltro'
        '_${ora.year}_${dueCifre(ora.month)}_${dueCifre(ora.day)}'
        '_${dueCifre(ora.hour)}h${dueCifre(ora.minute)}.xlsx';

    final file = File('${directory.path}/$nomeFile');
    await file.writeAsBytes(bytes, flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export Excel completato: ${dati.length} '
          '${dati.length == 1 ? 'attrezzatura esportata' : 'attrezzature esportate'}.',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> esportaPdfAttrezzature() async {
    final dati = attrezzatureFiltrate;

    if (dati.isEmpty) {
      return;
    }

    final intestazionePdf = await caricaIntestazioneAziendaPdf();

    final pdf = pw.Document();

    final ricerca = cercaController.text.trim();
    final ora = DateTime.now();
    final dataOra = DateFormat('dd/MM/yyyy HH:mm').format(ora);

    final info = [
      soloAttive ? 'Solo attive' : 'Tutte',
      if (ricerca.isNotEmpty) 'Ricerca: "$ricerca"',
      '${dati.length} ${dati.length == 1 ? 'attrezzatura' : 'attrezzature'}',
      'Esportazione del $dataOra',
    ].join(' - ');

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
            'ATTREZZATURE',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(info, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Denominazione',
              'Categoria',
              'Codice',
              'Descrizione',
              'Quantita',
              'Unita',
              'Stato',
              'Note',
            ],
            data: dati.map((attrezzatura) {
              return [
                attrezzatura.denominazione,
                attrezzatura.categoria,
                attrezzatura.codice,
                attrezzatura.descrizione,
                attrezzatura.quantita.toString(),
                attrezzatura.unitaMisura,
                attrezzatura.attiva ? 'ATTIVA' : 'NON ATTIVA',
                attrezzatura.note,
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
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(1.1),
              3: pw.FlexColumnWidth(2.4),
              4: pw.FlexColumnWidth(0.8),
              5: pw.FlexColumnWidth(0.8),
              6: pw.FlexColumnWidth(1.0),
              7: pw.FlexColumnWidth(2.0),
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
          ),
        ],
      ),
    );

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final nomeFiltro = ricerca.isNotEmpty ? '_filtrato' : '';
    final nomeFile =
        'attrezzature_export_pdf$nomeFiltro'
        '_${ora.year}_${dueCifre(ora.month)}_${dueCifre(ora.day)}'
        '_${dueCifre(ora.hour)}h${dueCifre(ora.minute)}.pdf';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$nomeFile');

    await file.writeAsBytes(await pdf.save(), flush: true);

    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export PDF completato: ${dati.length} '
          '${dati.length == 1 ? 'attrezzatura esportata' : 'attrezzature esportate'}.',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void azzeraRicerca() {
    cercaController.clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtrate = attrezzatureFiltrate;
    final ricercaAttiva = cercaController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attrezzature'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: apriDialogNuovaAttrezzatura,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuova attrezzatura'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: caricamento
            ? const Center(child: CircularProgressIndicator())
            : Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: attrezzature.isEmpty
                      ? const _StatoVuotoAttrezzature()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.construction_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ricercaAttiva
                                        ? '${filtrate.length} ${filtrate.length == 1 ? 'attrezzatura trovata' : 'attrezzature trovate'}'
                                        : soloAttive
                                        ? '${filtrate.length} ${filtrate.length == 1 ? 'attrezzatura attiva' : 'attrezzature attive'}'
                                        : '${filtrate.length} ${filtrate.length == 1 ? 'attrezzatura presente' : 'attrezzature presenti'}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: cercaController,
                              onChanged: (_) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Cerca attrezzatura',
                                hintText:
                                    'Cerca per denominazione, categoria, codice, descrizione, note...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: ricercaAttiva
                                    ? IconButton(
                                        tooltip: 'Pulisci ricerca',
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: azzeraRicerca,
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  selected: soloAttive,
                                  label: const Text('Solo attive'),
                                  avatar: const Icon(
                                    Icons.visibility_rounded,
                                    size: 18,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      soloAttive = true;
                                    });
                                  },
                                ),
                                FilterChip(
                                  selected: !soloAttive,
                                  label: const Text('Tutte'),
                                  avatar: const Icon(
                                    Icons.list_rounded,
                                    size: 18,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      soloAttive = false;
                                    });
                                  },
                                ),
                                OutlinedButton.icon(
                                  onPressed: filtrate.isEmpty
                                      ? null
                                      : esportaExcelAttrezzature,
                                  icon: const Icon(Icons.table_chart_rounded),
                                  label: Text('Excel (${filtrate.length})'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: filtrate.isEmpty
                                      ? null
                                      : esportaPdfAttrezzature,
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                  ),
                                  label: Text('PDF (${filtrate.length})'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (filtrate.isEmpty)
                              Expanded(
                                child: _StatoVuotoRicercaAttrezzature(
                                  ricerca: cercaController.text.trim(),
                                  onAzzera: azzeraRicerca,
                                ),
                              )
                            else
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      headingRowColor:
                                          WidgetStateProperty.all<Color>(
                                            const Color(0xFFF1F5F9),
                                          ),
                                      columns: const [
                                        DataColumn(
                                          label: Text('Denominazione'),
                                        ),
                                        DataColumn(label: Text('Categoria')),
                                        DataColumn(label: Text('Codice')),
                                        DataColumn(label: Text('Quantità')),
                                        DataColumn(label: Text('Unità')),
                                        DataColumn(label: Text('Stato')),
                                        DataColumn(label: Text('Azioni')),
                                      ],
                                      rows: filtrate.map((attrezzatura) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(attrezzatura.denominazione),
                                            ),
                                            DataCell(
                                              Text(attrezzatura.categoria),
                                            ),
                                            DataCell(Text(attrezzatura.codice)),
                                            DataCell(
                                              Text(
                                                attrezzatura.quantita
                                                    .toString(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(attrezzatura.unitaMisura),
                                            ),
                                            DataCell(
                                              _BadgeStatoAttrezzatura(
                                                attiva: attrezzatura.attiva,
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip:
                                                        'Modifica attrezzatura',
                                                    icon: const Icon(
                                                      Icons.edit_rounded,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                    onPressed: () {
                                                      apriDialogModificaAttrezzatura(
                                                        attrezzatura,
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    tooltip: attrezzatura.attiva
                                                        ? 'Disattiva attrezzatura'
                                                        : 'Riattiva attrezzatura',
                                                    icon: Icon(
                                                      attrezzatura.attiva
                                                          ? Icons
                                                                .visibility_off_rounded
                                                          : Icons
                                                                .visibility_rounded,
                                                      color: attrezzatura.attiva
                                                          ? const Color(
                                                              0xFFDC2626,
                                                            )
                                                          : const Color(
                                                              0xFF16A34A,
                                                            ),
                                                    ),
                                                    onPressed: () {
                                                      cambiaStatoAttrezzatura(
                                                        attrezzatura,
                                                      );
                                                    },
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
                          ],
                        ),
                ),
              ),
      ),
    );
  }
}

class _AttrezzaturaDialog extends StatefulWidget {
  final Attrezzatura? attrezzatura;

  const _AttrezzaturaDialog({this.attrezzatura});

  @override
  State<_AttrezzaturaDialog> createState() => _AttrezzaturaDialogState();
}

class _AttrezzaturaDialogState extends State<_AttrezzaturaDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController denominazioneController;
  late final TextEditingController categoriaController;
  late final TextEditingController codiceController;
  late final TextEditingController descrizioneController;
  late final TextEditingController quantitaController;
  late final TextEditingController unitaMisuraController;
  late final TextEditingController noteController;

  bool attiva = true;
  bool salvataggio = false;

  bool get isModifica => widget.attrezzatura != null;

  @override
  void initState() {
    super.initState();

    final attrezzatura = widget.attrezzatura;

    denominazioneController = TextEditingController(
      text: attrezzatura?.denominazione ?? '',
    );
    categoriaController = TextEditingController(
      text: attrezzatura?.categoria ?? 'Generica',
    );
    codiceController = TextEditingController(text: attrezzatura?.codice ?? '');
    descrizioneController = TextEditingController(
      text: attrezzatura?.descrizione ?? '',
    );
    quantitaController = TextEditingController(
      text: (attrezzatura?.quantita ?? 1).toString(),
    );
    unitaMisuraController = TextEditingController(
      text: attrezzatura?.unitaMisura ?? 'pz',
    );
    noteController = TextEditingController(text: attrezzatura?.note ?? '');
    attiva = attrezzatura?.attiva ?? true;
  }

  @override
  void dispose() {
    denominazioneController.dispose();
    categoriaController.dispose();
    codiceController.dispose();
    descrizioneController.dispose();
    quantitaController.dispose();
    unitaMisuraController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> salva() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      salvataggio = true;
    });

    final quantita = int.tryParse(quantitaController.text.trim()) ?? 1;
    final quantitaCorretta = quantita <= 0 ? 1 : quantita;

    if (isModifica) {
      await AppDatabase.instance.aggiornaAttrezzatura(
        id: widget.attrezzatura!.id!,
        denominazione: denominazioneController.text,
        categoria: categoriaController.text,
        codice: codiceController.text,
        descrizione: descrizioneController.text,
        quantita: quantitaCorretta,
        unitaMisura: unitaMisuraController.text,
        attiva: attiva ? 1 : 0,
        note: noteController.text,
      );
    } else {
      await AppDatabase.instance.inserisciAttrezzatura(
        denominazione: denominazioneController.text,
        categoria: categoriaController.text,
        codice: codiceController.text,
        descrizione: descrizioneController.text,
        quantita: quantitaCorretta,
        unitaMisura: unitaMisuraController.text,
        attiva: attiva ? 1 : 0,
        note: noteController.text,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isModifica ? 'Modifica attrezzatura' : 'Nuova attrezzatura'),
      content: SizedBox(
        width: 560,
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
                TextFormField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Es. DPI, Antincendio, Ponteggi, Aula',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codiceController,
                  decoration: const InputDecoration(
                    labelText: 'Codice',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descrizioneController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantitaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantità',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: unitaMisuraController,
                        decoration: const InputDecoration(
                          labelText: 'Unità di misura',
                          hintText: 'pz, kit, aula, set',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: attiva,
                  onChanged: salvataggio
                      ? null
                      : (value) {
                          setState(() {
                            attiva = value;
                          });
                        },
                  title: const Text('Attrezzatura attiva'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvataggio ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: salvataggio ? null : salva,
          icon: salvataggio
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(salvataggio ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}

class _StatoVuotoAttrezzature extends StatelessWidget {
  const _StatoVuotoAttrezzature();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.construction_rounded, color: Color(0xFF2563EB), size: 32),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gestione attrezzature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Nessuna attrezzatura inserita. In questa sezione potrai gestire materiali, DPI, dotazioni didattiche e strumenti usati nei corsi.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatoVuotoRicercaAttrezzature extends StatelessWidget {
  final String ricerca;
  final VoidCallback onAzzera;

  const _StatoVuotoRicercaAttrezzature({
    required this.ricerca,
    required this.onAzzera,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF94A3B8),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nessuna attrezzatura trovata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La ricerca "$ricerca" non ha prodotto risultati.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAzzera,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Azzera ricerca'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeStatoAttrezzatura extends StatelessWidget {
  final bool attiva;

  const _BadgeStatoAttrezzatura({required this.attiva});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: attiva ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        attiva ? 'Attiva' : 'Non attiva',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: attiva ? const Color(0xFF166534) : const Color(0xFF991B1B),
        ),
      ),
    );
  }
}
