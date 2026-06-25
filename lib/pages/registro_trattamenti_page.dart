import 'package:flutter/material.dart';

import '../models/registro_trattamento.dart';
import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class RegistroTrattamentiPage extends StatefulWidget {
  const RegistroTrattamentiPage({super.key});

  @override
  State<RegistroTrattamentiPage> createState() =>
      _RegistroTrattamentiPageState();
}

class _RegistroTrattamentiPageState extends State<RegistroTrattamentiPage> {
  bool caricamento = true;
  String? errore;
  List<RegistroTrattamento> trattamenti = [];

  String filtroStato = 'tutti';
  String ricercaRegistro = '';

  List<RegistroTrattamento> get trattamentiFiltrati {
    Iterable<RegistroTrattamento> risultati = trattamenti;

    if (filtroStato == 'attivi') {
      risultati = risultati.where((trattamento) => trattamento.attivo);
    } else if (filtroStato == 'non_attivi') {
      risultati = risultati.where((trattamento) => !trattamento.attivo);
    }

    final ricerca = ricercaRegistro.trim().toLowerCase();

    if (ricerca.isNotEmpty) {
      risultati = risultati.where((trattamento) {
        final testo = [
          trattamento.nomeTrattamento,
          trattamento.finalita,
          trattamento.categorieInteressati,
          trattamento.categorieDati,
          trattamento.baseGiuridica,
          trattamento.destinatari,
          trattamento.trasferimentoExtraUe,
          trattamento.tempiConservazione,
          trattamento.misureSicurezza,
          trattamento.responsabileInterno,
          trattamento.note,
        ].whereType<String>().join(' ').toLowerCase();

        return testo.contains(ricerca);
      });
    }

    return risultati.toList();
  }

  Future<void> esportaExcelRegistroTrattamenti() async {
    final datiDaEsportare = trattamentiFiltrati;

    if (datiDaEsportare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun trattamento da esportare.')),
      );
      return;
    }

    final excel = Excel.createExcel();
    const nomeFoglio = 'Registro trattamenti';
    final sheet = excel[nomeFoglio];

    excel.setDefaultSheet(nomeFoglio);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final intestazioni = [
      'Nome trattamento',
      'Finalità',
      'Categorie interessati',
      'Categorie dati',
      'Base giuridica',
      'Destinatari',
      'Trasferimento extra UE',
      'Tempi conservazione',
      'Misure sicurezza',
      'Responsabile interno',
      'Stato',
      'Note',
    ];

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 0))
          .value = TextCellValue(
        intestazioni[colonna],
      );
    }

    for (var riga = 0; riga < datiDaEsportare.length; riga++) {
      final trattamento = datiDaEsportare[riga];

      final valori = [
        trattamento.nomeTrattamento,
        trattamento.finalita,
        trattamento.categorieInteressati,
        trattamento.categorieDati,
        trattamento.baseGiuridica,
        trattamento.destinatari,
        trattamento.trasferimentoExtraUe,
        trattamento.tempiConservazione,
        trattamento.misureSicurezza,
        trattamento.responsabileInterno,
        trattamento.attivo ? 'Attivo' : 'Non attivo',
        trattamento.note,
      ];

      for (var colonna = 0; colonna < valori.length; colonna++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colonna,
                rowIndex: riga + 1,
              ),
            )
            .value = TextCellValue(
          valori[colonna],
        );
      }
    }

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet.setColumnWidth(colonna, 24);
    }

    final bytes = excel.encode();

    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la generazione del file Excel.'),
        ),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${directory.path}\\Gestionale Sicurezza\\Export',
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File(
      '${exportDir.path}\\registro_trattamenti_$timestamp.xlsx',
    );

    await file.writeAsBytes(bytes, flush: true);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Excel esportato: ${file.path}')));
  }

  Future<void> esportaPdfRegistroTrattamenti() async {
    final listaDaEsportare = trattamentiFiltrati;

    if (listaDaEsportare.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun trattamento da esportare in PDF.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    final filtroStatoTesto = switch (filtroStato) {
      'attivi' => 'Attivi',
      'non_attivi' => 'Non attivi',
      _ => 'Tutti',
    };

    final ricercaTesto = '';

    final infoFiltri = [
      'Stato: $filtroStatoTesto',
      if (ricercaTesto.isNotEmpty) 'Ricerca: $ricercaTesto',
      'Record esportati: ${listaDaEsportare.length}',
    ].join(' | ');

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 6),
            pw.Text(
              'Registro trattamenti',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Registro dei trattamenti - GDPR 679/2016',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(infoFiltri, style: const pw.TextStyle(fontSize: 9)),
            pw.Divider(),
          ],
        ),
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
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.topLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(4),
              headers: const [
                'Stato',
                'Nome trattamento',
                'Finalità',
                'Categorie interessati',
                'Categorie dati',
                'Base giuridica',
                'Destinatari',
                'Extra UE',
                'Conservazione',
                'Responsabile',
              ],
              data: listaDaEsportare.map((trattamento) {
                return [
                  trattamento.attivo ? 'Attivo' : 'Non attivo',
                  trattamento.nomeTrattamento,
                  trattamento.finalita,
                  trattamento.categorieInteressati,
                  trattamento.categorieDati,
                  trattamento.baseGiuridica,
                  trattamento.destinatari,
                  trattamento.trasferimentoExtraUe,
                  trattamento.tempiConservazione,
                  trattamento.responsabileInterno,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final directoryDocumenti = await getApplicationDocumentsDirectory();
    final directoryExport = Directory(
      '${directoryDocumenti.path}${Platform.pathSeparator}Gestionale Sicurezza${Platform.pathSeparator}Export',
    );

    if (!await directoryExport.exists()) {
      await directoryExport.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${directoryExport.path}${Platform.pathSeparator}registro_trattamenti_$timestamp.pdf',
    );

    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF esportato: ${file.path}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> stampaRegistroTrattamenti() async {
    final listaDaStampare = trattamentiFiltrati;

    if (listaDaStampare.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun trattamento da stampare.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    final filtroStatoTesto = switch (filtroStato) {
      'attivi' => 'Attivi',
      'non_attivi' => 'Non attivi',
      _ => 'Tutti',
    };

    final infoFiltri = [
      'Stato: $filtroStatoTesto',
      'Record stampati: ${listaDaStampare.length}',
    ].join(' | ');

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 6),
            pw.Text(
              'Registro trattamenti',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Registro dei trattamenti - GDPR 679/2016',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(infoFiltri, style: const pw.TextStyle(fontSize: 9)),
            pw.Divider(),
          ],
        ),
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
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.topLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(4),
              headers: const [
                'Stato',
                'Nome trattamento',
                'Finalità',
                'Categorie interessati',
                'Categorie dati',
                'Base giuridica',
                'Destinatari',
                'Extra UE',
                'Conservazione',
                'Responsabile',
              ],
              data: listaDaStampare.map((trattamento) {
                return [
                  trattamento.attivo ? 'Attivo' : 'Non attivo',
                  trattamento.nomeTrattamento,
                  trattamento.finalita,
                  trattamento.categorieInteressati,
                  trattamento.categorieDati,
                  trattamento.baseGiuridica,
                  trattamento.destinatari,
                  trattamento.trasferimentoExtraUe,
                  trattamento.tempiConservazione,
                  trattamento.responsabileInterno,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final directoryTemp = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    final file = File(
      '${directoryTemp.path}${Platform.pathSeparator}registro_trattamenti_stampa_$timestamp.pdf',
    );

    await file.writeAsBytes(await pdf.save());

    await Process.run('cmd', ['/c', 'start', '', file.path], runInShell: true);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'PDF di stampa aperto. Puoi stampare dal visualizzatore PDF.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    caricaTrattamenti();
  }

  Future<void> caricaTrattamenti() async {
    setState(() {
      caricamento = true;
      errore = null;
    });

    try {
      final dati = await AppDatabase.instance.getRegistroTrattamenti();

      if (!mounted) return;

      setState(() {
        trattamenti = dati;
        caricamento = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errore = e.toString();
        caricamento = false;
      });
    }
  }

  Future<void> cambiaStatoTrattamento(RegistroTrattamento trattamento) async {
    final nuovoStatoAttivo = !trattamento.attivo;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            nuovoStatoAttivo
                ? 'Riattivare trattamento?'
                : 'Disattivare trattamento?',
          ),
          content: Text(
            nuovoStatoAttivo
                ? 'Il trattamento tornerà attivo nel Registro trattamenti.'
                : 'Il trattamento non verrà cancellato, ma sarà segnato come non attivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(nuovoStatoAttivo ? 'Riattiva' : 'Disattiva'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    final trattamentoAggiornato = RegistroTrattamento(
      id: trattamento.id,
      nomeTrattamento: trattamento.nomeTrattamento,
      finalita: trattamento.finalita,
      categorieInteressati: trattamento.categorieInteressati,
      categorieDati: trattamento.categorieDati,
      baseGiuridica: trattamento.baseGiuridica,
      destinatari: trattamento.destinatari,
      trasferimentoExtraUe: trattamento.trasferimentoExtraUe,
      tempiConservazione: trattamento.tempiConservazione,
      misureSicurezza: trattamento.misureSicurezza,
      responsabileInterno: trattamento.responsabileInterno,
      note: trattamento.note,
      attivo: nuovoStatoAttivo,
      createdAt: trattamento.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await AppDatabase.instance.updateRegistroTrattamento(trattamentoAggiornato);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuovoStatoAttivo
              ? 'Trattamento riattivato correttamente.'
              : 'Trattamento disattivato correttamente.',
        ),
      ),
    );

    await caricaTrattamenti();
  }

  Widget _buildStatoVuoto() {
    return const Center(
      child: Text(
        'Nessun trattamento registrato.\n'
        'Il registro è collegato al database, ma non contiene ancora dati.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildErrore() {
    return Center(
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Errore durante il caricamento del registro trattamenti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(errore ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: caricaTrattamenti,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> mostraDettaglioTrattamento(
    RegistroTrattamento trattamento,
  ) async {
    Widget rigaDettaglio(String etichetta, String valore) {
      final testo = valore.trim().isEmpty ? '-' : valore.trim();

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 190,
              child: Text(
                etichetta,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(testo)),
          ],
        ),
      );
    }

    Widget titoloSezione(String testo, IconData icona) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(
          children: [
            Icon(icona, size: 18, color: Colors.blueGrey.shade700),
            const SizedBox(width: 8),
            Text(
              testo,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.blueGrey.shade700),
              const SizedBox(width: 10),
              const Expanded(child: Text('Dettaglio trattamento')),
            ],
          ),
          content: SizedBox(
            width: 820,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titoloSezione('Dati principali', Icons.assignment_outlined),
                  rigaDettaglio('Trattamento', trattamento.nomeTrattamento),
                  rigaDettaglio('Finalità', trattamento.finalita),
                  rigaDettaglio(
                    'Stato',
                    trattamento.attivo ? 'Attivo' : 'Non attivo',
                  ),

                  const Divider(height: 28),

                  titoloSezione('Inquadramento GDPR', Icons.gavel_outlined),
                  rigaDettaglio('Base giuridica', trattamento.baseGiuridica),
                  rigaDettaglio(
                    'Tempi conservazione',
                    trattamento.tempiConservazione,
                  ),
                  rigaDettaglio(
                    'Trasferimento extra UE',
                    trattamento.trasferimentoExtraUe,
                  ),

                  const Divider(height: 28),

                  titoloSezione(
                    'Interessati e dati trattati',
                    Icons.groups_outlined,
                  ),
                  rigaDettaglio(
                    'Categorie interessati',
                    trattamento.categorieInteressati,
                  ),
                  rigaDettaglio('Categorie dati', trattamento.categorieDati),

                  const Divider(height: 28),

                  titoloSezione(
                    'Destinatari e sicurezza',
                    Icons.security_outlined,
                  ),
                  rigaDettaglio('Destinatari', trattamento.destinatari),
                  rigaDettaglio(
                    'Responsabile interno',
                    trattamento.responsabileInterno,
                  ),
                  rigaDettaglio(
                    'Misure sicurezza',
                    trattamento.misureSicurezza,
                  ),

                  const Divider(height: 28),

                  titoloSezione('Annotazioni interne', Icons.notes_outlined),
                  rigaDettaglio('Note', trattamento.note),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabella() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Trattamento')),
              DataColumn(label: Text('Finalità')),
              DataColumn(label: Text('Base giuridica')),
              DataColumn(label: Text('Categorie dati')),
              DataColumn(label: Text('Conservazione')),
              DataColumn(label: Text('Stato')),
              DataColumn(label: Text('Azioni')),
            ],
            rows: trattamentiFiltrati.map((trattamento) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(trattamento.nomeTrattamento),
                    ),
                  ),
                  DataCell(
                    SizedBox(width: 260, child: Text(trattamento.finalita)),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(trattamento.baseGiuridica),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(trattamento.categorieDati),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(trattamento.tempiConservazione),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(trattamento.attivo ? 'Attivo' : 'Non attivo'),
                      backgroundColor: trattamento.attivo
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Dettaglio trattamento',
                          icon: const Icon(Icons.description_outlined),
                          color: Colors.blueGrey.shade700,
                          onPressed: () =>
                              mostraDettaglioTrattamento(trattamento),
                        ),
                        IconButton(
                          tooltip: 'Modifica trattamento',
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              mostraDialogTrattamento(trattamento: trattamento),
                        ),
                        IconButton(
                          tooltip: trattamento.attivo
                              ? 'Disattiva trattamento'
                              : 'Riattiva trattamento',
                          icon: Icon(
                            trattamento.attivo
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          color: trattamento.attivo
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          onPressed: () => cambiaStatoTrattamento(trattamento),
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
    );
  }

  Widget _buildContenuto() {
    if (caricamento) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errore != null) {
      return _buildErrore();
    }

    if (trattamenti.isEmpty) {
      return _buildStatoVuoto();
    }

    return _buildTabella();
  }

  Future<void> mostraDialogTrattamento({
    RegistroTrattamento? trattamento,
  }) async {
    final isModifica = trattamento != null;

    final risultato = await showDialog<_NuovoTrattamentoDialogResult>(
      context: context,
      builder: (dialogContext) {
        return _NuovoTrattamentoDialog(trattamento: trattamento);
      },
    );

    if (risultato == null) {
      return;
    }

    try {
      final trattamentoDaSalvare = RegistroTrattamento(
        id: trattamento?.id,
        nomeTrattamento: risultato.nome,
        finalita: risultato.finalita,
        baseGiuridica: risultato.baseGiuridica,
        categorieDati: risultato.categorieDati,
        categorieInteressati: risultato.categorieInteressati,
        destinatari: risultato.destinatari,
        trasferimentoExtraUe: risultato.trasferimentoExtraUe,
        tempiConservazione: risultato.conservazione,
        misureSicurezza: risultato.misureSicurezza,
        responsabileInterno: risultato.responsabileInterno,
        note: risultato.note,
        attivo: trattamento?.attivo ?? true,
        createdAt: trattamento?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      if (isModifica) {
        await AppDatabase.instance.updateRegistroTrattamento(
          trattamentoDaSalvare,
        );
      } else {
        await AppDatabase.instance.insertRegistroTrattamento(
          trattamentoDaSalvare,
        );
      }

      if (!mounted) {
        return;
      }

      await caricaTrattamenti();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isModifica
                ? 'Trattamento "${risultato.nome}" modificato.'
                : 'Trattamento "${risultato.nome}" salvato nel registro.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            isModifica
                ? 'Errore durante la modifica del trattamento: $e'
                : 'Errore durante il salvataggio del trattamento: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro trattamenti'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: esportaExcelRegistroTrattamenti,
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Excel'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: esportaPdfRegistroTrattamenti,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('PDF'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: stampaRegistroTrattamenti,
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Stampa'),
            ),
          ),
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: caricamento ? null : caricaTrattamenti,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Trattamenti registrati: ${trattamenti.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text(
                  'Filtro stato:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Tutti'),
                  selected: filtroStato == 'tutti',
                  onSelected: (_) {
                    setState(() {
                      filtroStato = 'tutti';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Attivi'),
                  selected: filtroStato == 'attivi',
                  onSelected: (_) {
                    setState(() {
                      filtroStato = 'attivi';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Non attivi'),
                  selected: filtroStato == 'non_attivi',
                  onSelected: (_) {
                    setState(() {
                      filtroStato = 'non_attivi';
                    });
                  },
                ),
                const Spacer(),
                Text(
                  'Visibili: ${trattamentiFiltrati.length} / ${trattamenti.length}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: InputDecoration(
                labelText: 'Cerca nel registro trattamenti',
                hintText:
                    'Nome, finalità, base giuridica, dati, responsabile, note...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ricercaRegistro.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Azzera ricerca',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            ricercaRegistro = '';
                          });
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  ricercaRegistro = value;
                });
              },
            ),

            const SizedBox(height: 16),
            Expanded(child: _buildContenuto()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostraDialogTrattamento(),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo trattamento'),
      ),
    );
  }
}

class _NuovoTrattamentoDialogResult {
  const _NuovoTrattamentoDialogResult({
    required this.nome,
    required this.finalita,
    required this.baseGiuridica,
    required this.categorieInteressati,
    required this.categorieDati,
    required this.destinatari,
    required this.trasferimentoExtraUe,
    required this.conservazione,
    required this.misureSicurezza,
    required this.responsabileInterno,
    required this.note,
  });

  final String nome;
  final String finalita;
  final String baseGiuridica;
  final String categorieInteressati;
  final String categorieDati;
  final String destinatari;
  final String trasferimentoExtraUe;
  final String conservazione;
  final String misureSicurezza;
  final String responsabileInterno;
  final String note;
}

class _NuovoTrattamentoDialog extends StatefulWidget {
  const _NuovoTrattamentoDialog({this.trattamento});

  final RegistroTrattamento? trattamento;

  @override
  State<_NuovoTrattamentoDialog> createState() =>
      _NuovoTrattamentoDialogState();
}

class _NuovoTrattamentoDialogState extends State<_NuovoTrattamentoDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _finalitaController = TextEditingController();
  final TextEditingController _baseGiuridicaController =
      TextEditingController();
  final TextEditingController _categorieInteressatiController =
      TextEditingController();
  final TextEditingController _categorieDatiController =
      TextEditingController();
  final TextEditingController _destinatariController = TextEditingController();
  final TextEditingController _trasferimentoExtraUeController =
      TextEditingController();
  final TextEditingController _conservazioneController =
      TextEditingController();
  final TextEditingController _responsabileInternoController =
      TextEditingController();
  final TextEditingController _misureSicurezzaController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _erroreNome;
  String? _erroreFinalita;

  @override
  void initState() {
    super.initState();

    final trattamento = widget.trattamento;
    if (trattamento == null) {
      return;
    }

    _nomeController.text = trattamento.nomeTrattamento;
    _finalitaController.text = trattamento.finalita;
    _baseGiuridicaController.text = trattamento.baseGiuridica;
    _categorieInteressatiController.text = trattamento.categorieInteressati;
    _categorieDatiController.text = trattamento.categorieDati;
    _destinatariController.text = trattamento.destinatari;
    _trasferimentoExtraUeController.text = trattamento.trasferimentoExtraUe;
    _conservazioneController.text = trattamento.tempiConservazione;
    _misureSicurezzaController.text = trattamento.misureSicurezza;
    _responsabileInternoController.text = trattamento.responsabileInterno;
    _noteController.text = trattamento.note;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _finalitaController.dispose();
    _baseGiuridicaController.dispose();
    _categorieInteressatiController.dispose();
    _categorieDatiController.dispose();
    _destinatariController.dispose();
    _trasferimentoExtraUeController.dispose();
    _conservazioneController.dispose();
    _misureSicurezzaController.dispose();
    _responsabileInternoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _salva() {
    final nomeVuoto = _nomeController.text.trim().isEmpty;
    final finalitaVuota = _finalitaController.text.trim().isEmpty;

    setState(() {
      _erroreNome = nomeVuoto ? 'Inserisci il nome del trattamento' : null;
      _erroreFinalita = finalitaVuota
          ? 'Inserisci la finalità del trattamento'
          : null;
    });

    if (nomeVuoto || finalitaVuota) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop(
      _NuovoTrattamentoDialogResult(
        nome: _nomeController.text.trim(),
        finalita: _finalitaController.text.trim(),
        baseGiuridica: _baseGiuridicaController.text.trim(),
        categorieInteressati: _categorieInteressatiController.text.trim(),
        categorieDati: _categorieDatiController.text.trim(),
        destinatari: _destinatariController.text.trim(),
        trasferimentoExtraUe: _trasferimentoExtraUeController.text.trim(),
        conservazione: _conservazioneController.text.trim(),
        misureSicurezza: _misureSicurezzaController.text.trim(),
        responsabileInterno: _responsabileInternoController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isModifica = widget.trattamento != null;
    final screenSize = MediaQuery.of(context).size;

    Widget titoloSezione(String testo, IconData icona) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icona, size: 18, color: Colors.blueGrey.shade700),
            const SizedBox(width: 8),
            Text(
              testo,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    Widget campoTesto({
      required TextEditingController controller,
      required String label,
      String? hintText,
      String? errorText,
      int minLines = 1,
      int maxLines = 1,
    }) {
      return TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          errorText: errorText,
          border: const OutlineInputBorder(),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      );
    }

    Widget rigaDoppia({required Widget primo, required Widget secondo}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              children: [primo, const SizedBox(height: 12), secondo],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: primo),
              const SizedBox(width: 12),
              Expanded(child: secondo),
            ],
          );
        },
      );
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Icon(
            isModifica ? Icons.edit_note : Icons.playlist_add,
            color: Colors.blueGrey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isModifica ? 'Modifica trattamento' : 'Nuovo trattamento',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenSize.height * 0.78),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titoloSezione('Dati principali', Icons.assignment_outlined),
                campoTesto(
                  controller: _nomeController,
                  label: 'Nome trattamento *',
                  errorText: _erroreNome,
                ),
                const SizedBox(height: 12),
                campoTesto(
                  controller: _finalitaController,
                  label: 'Finalità *',
                  errorText: _erroreFinalita,
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 18),

                titoloSezione('Inquadramento GDPR', Icons.gavel_outlined),
                rigaDoppia(
                  primo: campoTesto(
                    controller: _baseGiuridicaController,
                    label: 'Base giuridica',
                    hintText: 'Es. obbligo di legge, contratto, consenso',
                    minLines: 2,
                    maxLines: 3,
                  ),
                  secondo: campoTesto(
                    controller: _conservazioneController,
                    label: 'Tempi di conservazione',
                    hintText: 'Es. 10 anni, obblighi di legge',
                    minLines: 2,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 12),
                campoTesto(
                  controller: _trasferimentoExtraUeController,
                  label: 'Trasferimento extra UE',
                  hintText:
                      'Es. Nessuno / fornitori extra UE / garanzie applicate',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),

                titoloSezione(
                  'Interessati e dati trattati',
                  Icons.groups_outlined,
                ),
                rigaDoppia(
                  primo: campoTesto(
                    controller: _categorieInteressatiController,
                    label: 'Categorie interessati',
                    hintText:
                        'Es. discenti, lavoratori, imprese clienti, docenti',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  secondo: campoTesto(
                    controller: _categorieDatiController,
                    label: 'Categorie dati personali',
                    hintText: 'Es. dati anagrafici, contatti, attestati',
                    minLines: 2,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 18),

                titoloSezione(
                  'Destinatari e sicurezza',
                  Icons.security_outlined,
                ),
                rigaDoppia(
                  primo: campoTesto(
                    controller: _destinatariController,
                    label: 'Destinatari / categorie destinatari',
                    hintText:
                        'Es. enti attestati, consulenti, medico competente',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  secondo: campoTesto(
                    controller: _responsabileInternoController,
                    label: 'Responsabile interno',
                    hintText:
                        'Es. titolare, referente privacy, amministrazione',
                    minLines: 2,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 12),
                campoTesto(
                  controller: _misureSicurezzaController,
                  label: 'Misure di sicurezza',
                  hintText: 'Es. accessi profilati, backup, antivirus',
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 18),

                titoloSezione('Annotazioni interne', Icons.notes_outlined),
                campoTesto(
                  controller: _noteController,
                  label: 'Note',
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          icon: const Icon(Icons.close),
          label: const Text('Annulla'),
        ),
        ElevatedButton.icon(
          onPressed: _salva,
          icon: const Icon(Icons.save),
          label: Text(isModifica ? 'Salva modifiche' : 'Salva'),
        ),
      ],
    );
  }
}
