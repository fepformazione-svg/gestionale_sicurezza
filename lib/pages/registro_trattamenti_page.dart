import 'package:flutter/material.dart';

import '../models/registro_trattamento.dart';
import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RegistroTrattamentiPage extends StatefulWidget {
  const RegistroTrattamentiPage({super.key});

  @override
  State<RegistroTrattamentiPage> createState() =>
      _RegistroTrattamentiPageState();
}

class _RegistroTrattamentiPageState extends State<RegistroTrattamentiPage> {
  final ScrollController _tabellaOrizzontaleController = ScrollController();
  final ScrollController _tabellaVerticaleController = ScrollController();
  final TextEditingController ricercaRegistroController =
      TextEditingController();

  bool caricamento = true;
  String? errore;
  List<RegistroTrattamento> trattamenti = [];

  String filtroStato = 'tutti';
  String filtroStatoRevisione = 'tutti';
  String ricercaRegistro = '';

  // GDPR021A - Ordinamento Registro trattamenti
  String campoOrdinamentoRegistro = 'dataRevisione';
  bool ordinamentoRegistroCrescente = true;

  List<RegistroTrattamento> get trattamentiFiltrati {
    Iterable<RegistroTrattamento> risultati = trattamenti;

    if (filtroStato == 'attivi') {
      risultati = risultati.where((trattamento) => trattamento.attivo);
    } else if (filtroStato == 'non_attivi') {
      risultati = risultati.where((trattamento) => !trattamento.attivo);
    }

    if (filtroStatoRevisione != 'tutti') {
      risultati = risultati.where((trattamento) {
        final statoRevisione = statoRevisioneTrattamento(trattamento);

        return switch (filtroStatoRevisione) {
          'scadute' => statoRevisione == 'Scaduta',
          'in_scadenza' => statoRevisione == 'In scadenza',
          'programmate' => statoRevisione == 'Programmata',
          'non_impostate' => statoRevisione == 'Non impostata',
          'da_verificare' => statoRevisione == 'Da verificare',
          _ => true,
        };
      });
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

    final listaOrdinata = risultati.toList();
    ordinaRegistroTrattamenti(listaOrdinata);

    return listaOrdinata;
  }

  DateTime? parseDataRevisioneRegistro(String? valore) {
    if (valore == null || valore.trim().isEmpty) {
      return null;
    }

    final testo = valore.trim();

    final parti = testo.split('/');
    if (parti.length == 3) {
      final giorno = int.tryParse(parti[0]);
      final mese = int.tryParse(parti[1]);
      final anno = int.tryParse(parti[2]);

      if (giorno != null && mese != null && anno != null) {
        return DateTime(anno, mese, giorno);
      }
    }

    return DateTime.tryParse(testo);
  }

  // GDPR021A - Ordinamento Registro trattamenti
  void cambiaOrdinamentoRegistro(String campo) {
    setState(() {
      if (campoOrdinamentoRegistro == campo) {
        ordinamentoRegistroCrescente = !ordinamentoRegistroCrescente;
      } else {
        campoOrdinamentoRegistro = campo;
        ordinamentoRegistroCrescente = true;
      }
    });
  }

  String _testoOrdinabileRegistro(String? valore) {
    return (valore ?? '').trim().toLowerCase();
  }

  int _confrontaStringheRegistro(String? a, String? b) {
    return _testoOrdinabileRegistro(a).compareTo(_testoOrdinabileRegistro(b));
  }

  int _confrontaDateRegistro(String? a, String? b) {
    final dataA = parseDataRevisioneRegistro(a);
    final dataB = parseDataRevisioneRegistro(b);

    if (dataA == null && dataB == null) return 0;
    if (dataA == null) return 1;
    if (dataB == null) return -1;

    return dataA.compareTo(dataB);
  }

  void ordinaRegistroTrattamenti(List<RegistroTrattamento> lista) {
    lista.sort((a, b) {
      int risultato;

      switch (campoOrdinamentoRegistro) {
        case 'nomeTrattamento':
          risultato = _confrontaStringheRegistro(
            a.nomeTrattamento,
            b.nomeTrattamento,
          );
          break;

        case 'dataRevisione':
          risultato = _confrontaDateRegistro(a.dataRevisione, b.dataRevisione);
          break;

        case 'statoRevisione':
          risultato = _confrontaStringheRegistro(
            statoRevisioneTrattamento(a),
            statoRevisioneTrattamento(b),
          );
          break;

        case 'finalita':
          risultato = _confrontaStringheRegistro(a.finalita, b.finalita);
          break;

        case 'baseGiuridica':
          risultato = _confrontaStringheRegistro(
            a.baseGiuridica,
            b.baseGiuridica,
          );
          break;

        case 'categorieDati':
          risultato = _confrontaStringheRegistro(
            a.categorieDati,
            b.categorieDati,
          );
          break;

        case 'tempiConservazione':
          risultato = _confrontaStringheRegistro(
            a.tempiConservazione,
            b.tempiConservazione,
          );
          break;

        case 'stato':
          risultato = _confrontaStringheRegistro(
            a.attivo ? 'Attivo' : 'Non attivo',
            b.attivo ? 'Attivo' : 'Non attivo',
          );
          break;

        default:
          risultato = _confrontaStringheRegistro(
            a.nomeTrattamento,
            b.nomeTrattamento,
          );
      }

      return ordinamentoRegistroCrescente ? risultato : -risultato;
    });
  }

  String etichettaCampoOrdinamentoRegistro(String campo) {
    switch (campo) {
      case 'nomeTrattamento':
        return 'Trattamento';
      case 'dataRevisione':
        return 'Data revisione';
      case 'statoRevisione':
        return 'Stato revisione';
      case 'finalita':
        return 'Finalità';
      case 'baseGiuridica':
        return 'Base giuridica';
      case 'categorieDati':
        return 'Categorie dati';
      case 'tempiConservazione':
        return 'Conservazione';
      case 'stato':
        return 'Stato';
      default:
        return 'Trattamento';
    }
  }

  String get descrizioneOrdinamentoRegistro {
    final direzione = ordinamentoRegistroCrescente
        ? 'crescente'
        : 'decrescente';

    return '${etichettaCampoOrdinamentoRegistro(campoOrdinamentoRegistro)} - $direzione';
  }

  bool get ordinamentoRegistroPredefinito {
    return campoOrdinamentoRegistro == 'dataRevisione' &&
        ordinamentoRegistroCrescente;
  }

  void ripristinaOrdinamentoRegistro() {
    setState(() {
      campoOrdinamentoRegistro = 'dataRevisione';
      ordinamentoRegistroCrescente = true;
    });
  }

  Widget riepilogoOrdinamentoRegistro() {
    return Row(
      children: [
        Icon(Icons.sort, size: 18, color: Colors.blueGrey.shade700),
        const SizedBox(width: 8),
        Text(
          'Ordinato per: $descrizioneOrdinamentoRegistro',
          style: TextStyle(
            color: Colors.blueGrey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: ordinamentoRegistroPredefinito
              ? null
              : ripristinaOrdinamentoRegistro,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Ripristina ordinamento'),
        ),
      ],
    );
  }

  Widget intestazioneOrdinabileRegistro(String testo, String campo) {
    final attivo = campoOrdinamentoRegistro == campo;

    return InkWell(
      onTap: () => cambiaOrdinamentoRegistro(campo),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(testo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(
              attivo
                  ? ordinamentoRegistroCrescente
                        ? Icons.arrow_upward
                        : Icons.arrow_downward
                  : Icons.unfold_more,
              size: 16,
              color: attivo ? Colors.blueGrey.shade700 : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  String statoRevisioneTrattamento(RegistroTrattamento trattamento) {
    final dataRevisione = trattamento.dataRevisione;

    if (dataRevisione == null || dataRevisione.trim().isEmpty) {
      return 'Non impostata';
    }

    final data = parseDataRevisioneRegistro(dataRevisione);

    if (data == null) {
      return 'Da verificare';
    }

    final oggi = DateTime.now();
    final oggiSoloData = DateTime(oggi.year, oggi.month, oggi.day);
    final revisioneSoloData = DateTime(data.year, data.month, data.day);

    final giorniResidui = revisioneSoloData.difference(oggiSoloData).inDays;

    if (giorniResidui < 0) {
      return 'Scaduta';
    }

    if (giorniResidui <= 30) {
      return 'In scadenza';
    }

    return 'Programmata';
  }

  Color coloreStatoRevisione(String stato) {
    switch (stato) {
      case 'Scaduta':
        return Colors.red.shade700;
      case 'In scadenza':
        return Colors.orange.shade700;
      case 'Programmata':
        return Colors.green.shade700;
      case 'Da verificare':
        return Colors.blueGrey.shade700;
      case 'Non impostata':
      default:
        return Colors.grey.shade700;
    }
  }

  Widget chipFiltroRevisione({
    required String valore,
    required String etichetta,
  }) {
    final selezionato = filtroStatoRevisione == valore;

    return ChoiceChip(
      selected: selezionato,
      label: Text(etichetta),
      onSelected: (_) {
        setState(() {
          filtroStatoRevisione = valore;
        });
      },
    );
  }

  int conteggioRevisioniPerStato(String stato) {
    return trattamenti.where((trattamento) {
      return statoRevisioneTrattamento(trattamento) == stato;
    }).length;
  }

  Widget cardRiepilogoRevisione({
    required String titolo,
    required int valore,
    required String filtro,
    required Color colore,
    required Color sfondo,
    required IconData icona,
  }) {
    final selezionato = filtroStatoRevisione == filtro;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          filtroStatoRevisione = filtro;
        });
      },
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selezionato ? sfondo : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selezionato ? colore : Colors.grey.shade300,
            width: selezionato ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icona, color: colore),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valore.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colore,
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

  bool get filtriRegistroAttivi {
    return filtroStato != 'tutti' ||
        filtroStatoRevisione != 'tutti' ||
        ricercaRegistro.trim().isNotEmpty;
  }

  void azzeraFiltriRegistro() {
    setState(() {
      filtroStato = 'tutti';
      filtroStatoRevisione = 'tutti';
      ricercaRegistro = '';
      ricercaRegistroController.clear();
    });
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
      'Data revisione',
      'Stato revisione',
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
        trattamento.dataRevisione ?? '',
        statoRevisioneTrattamento(trattamento),
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

    final filtroRevisioneTesto = switch (filtroStatoRevisione) {
      'scadute' => 'Scadute',
      'in_scadenza' => 'In scadenza',
      'programmate' => 'Programmate',
      'non_impostate' => 'Non impostate',
      'da_verificare' => 'Da verificare',
      _ => 'Tutte',
    };

    final ricercaTesto = ricercaRegistro.trim();

    final infoFiltri = [
      'Stato: $filtroStatoTesto',
      'Revisione: $filtroRevisioneTesto',
      if (ricercaTesto.isNotEmpty) 'Ricerca: $ricercaTesto',
      'Ordinamento: $descrizioneOrdinamentoRegistro',
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
                'Data revisione',
                'Stato rev.',
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
                  trattamento.dataRevisione ?? '',
                  statoRevisioneTrattamento(trattamento),
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

    final filtroRevisioneTesto = switch (filtroStatoRevisione) {
      'scadute' => 'Scadute',
      'in_scadenza' => 'In scadenza',
      'programmate' => 'Programmate',
      'non_impostate' => 'Non impostate',
      'da_verificare' => 'Da verificare',
      _ => 'Tutte',
    };

    final ricercaTesto = ricercaRegistro.trim();

    final infoFiltri = [
      'Stato: $filtroStatoTesto',
      'Revisione: $filtroRevisioneTesto',
      if (ricercaTesto.isNotEmpty) 'Ricerca: $ricercaTesto',
      'Ordinamento: $descrizioneOrdinamentoRegistro',
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
                'Data revisione',
                'Stato rev.',
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
                  trattamento.dataRevisione ?? '',
                  statoRevisioneTrattamento(trattamento),
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
      dataRevisione: trattamento.dataRevisione,
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

  Future<Uint8List> generaPdfSingoloTrattamentoBytes(
    RegistroTrattamento trattamento,
  ) async {
    String valore(String testo) {
      final valorePulito = testo.trim();
      return valorePulito.isEmpty ? '-' : valorePulito;
    }

    pw.Widget rigaDettaglioPdf(String etichetta, String contenuto) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(
                etichetta,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(child: pw.Text(valore(contenuto))),
          ],
        ),
      );
    }

    pw.Widget sezionePdf(String titolo, List<pw.Widget> righe) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titolo,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            ...righe,
          ],
        ),
      );
    }

    final pdf = pw.Document();

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
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
              'Dettaglio singolo trattamento - GDPR 679/2016',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Trattamento: ${trattamento.nomeTrattamento}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          );
        },
        build: (context) {
          return [
            pw.SizedBox(height: 12),
            sezionePdf('Dati principali', [
              rigaDettaglioPdf('Nome trattamento', trattamento.nomeTrattamento),
              rigaDettaglioPdf(
                'Stato',
                trattamento.attivo ? 'Attivo' : 'Non attivo',
              ),
              rigaDettaglioPdf(
                'Responsabile interno',
                trattamento.responsabileInterno,
              ),
            ]),
            sezionePdf('Inquadramento GDPR', [
              rigaDettaglioPdf('Finalità', trattamento.finalita),
              rigaDettaglioPdf('Base giuridica', trattamento.baseGiuridica),
              rigaDettaglioPdf(
                'Tempi di conservazione',
                trattamento.tempiConservazione,
              ),
            ]),
            sezionePdf('Interessati e dati trattati', [
              rigaDettaglioPdf(
                'Categorie interessati',
                trattamento.categorieInteressati,
              ),
              rigaDettaglioPdf('Categorie dati', trattamento.categorieDati),
            ]),
            sezionePdf('Destinatari e sicurezza', [
              rigaDettaglioPdf('Destinatari', trattamento.destinatari),
              rigaDettaglioPdf(
                'Trasferimento extra UE',
                trattamento.trasferimentoExtraUe,
              ),
              rigaDettaglioPdf(
                'Misure di sicurezza',
                trattamento.misureSicurezza,
              ),
            ]),
            sezionePdf('Annotazioni interne', [
              rigaDettaglioPdf('Note', trattamento.note),
            ]),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> esportaPdfSingoloTrattamento(
    RegistroTrattamento trattamento,
  ) async {
    final bytes = await generaPdfSingoloTrattamentoBytes(trattamento);

    final documentiDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${documentiDir.path}${Platform.pathSeparator}Gestionale Sicurezza${Platform.pathSeparator}Export',
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    String nomeFileSicuro(String testo) {
      final pulito = testo
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

      return pulito.isEmpty ? 'trattamento' : pulito;
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    final file = File(
      '${exportDir.path}${Platform.pathSeparator}'
      'registro_trattamento_${nomeFileSicuro(trattamento.nomeTrattamento)}_$timestamp.pdf',
    );

    await file.writeAsBytes(bytes);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF singolo trattamento salvato: ${file.path}')),
    );
  }

  Future<void> stampaSingoloTrattamento(RegistroTrattamento trattamento) async {
    final bytes = await generaPdfSingoloTrattamentoBytes(trattamento);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Anteprima trattamento')),
            body: PdfPreview(
              build: (format) async => bytes,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
            ),
          );
        },
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

    final azioneDettaglio = await showDialog<String>(
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
                    'Data revisione',
                    trattamento.dataRevisione ?? '',
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
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Chiudi'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop('pdf'),
              icon: const Icon(Icons.save_alt),
              label: const Text('PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop('stampa'),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Anteprima'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop('modifica'),
              icon: const Icon(Icons.edit),
              label: const Text('Modifica'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }

    if (azioneDettaglio == 'modifica') {
      await mostraDialogTrattamento(trattamento: trattamento);
      return;
    }

    if (azioneDettaglio == 'pdf') {
      await esportaPdfSingoloTrattamento(trattamento);
      return;
    }

    if (azioneDettaglio == 'stampa') {
      await stampaSingoloTrattamento(trattamento);
    }
  }

  Widget _buildTabella() {
    return Scrollbar(
      controller: _tabellaVerticaleController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _tabellaVerticaleController,
        primary: false,
        child: Scrollbar(
          controller: _tabellaOrizzontaleController,
          thumbVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _tabellaOrizzontaleController,
            scrollDirection: Axis.horizontal,
            primary: false,
            child: DataTable(
              columns: [
                DataColumn(
                  label: intestazioneOrdinabileRegistro(
                    'Trattamento',
                    'nomeTrattamento',
                  ),
                ),
                const DataColumn(label: Text('Azioni')),
                DataColumn(
                  label: intestazioneOrdinabileRegistro(
                    'Data revisione',
                    'dataRevisione',
                  ),
                ),
                DataColumn(
                  label: intestazioneOrdinabileRegistro(
                    'Stato revisione',
                    'statoRevisione',
                  ),
                ),
                DataColumn(
                  label: intestazioneOrdinabileRegistro('Finalità', 'finalita'),
                ),
                DataColumn(
                  label: intestazioneOrdinabileRegistro(
                    'Base giuridica',
                    'baseGiuridica',
                  ),
                ),
                DataColumn(
                  label: intestazioneOrdinabileRegistro(
                    'Categorie dati',
                    'categorieDati',
                  ),
                ),
                DataColumn(
                  label: intestazioneOrdinabileRegistro(
                    'Conservazione',
                    'tempiConservazione',
                  ),
                ),
                DataColumn(
                  label: intestazioneOrdinabileRegistro('Stato', 'stato'),
                ),
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
                            tooltip: 'Duplica trattamento',
                            icon: const Icon(Icons.copy),
                            color: Colors.indigo.shade700,
                            onPressed: () => mostraDialogTrattamento(
                              trattamento: trattamento,
                              duplica: true,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Modifica trattamento',
                            icon: const Icon(Icons.edit),
                            onPressed: () => mostraDialogTrattamento(
                              trattamento: trattamento,
                            ),
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
                            onPressed: () =>
                                cambiaStatoTrattamento(trattamento),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(trattamento.dataRevisione ?? ''),
                      ),
                    ),
                    DataCell(
                      Builder(
                        builder: (context) {
                          final stato = statoRevisioneTrattamento(trattamento);

                          return Chip(
                            label: Text(
                              stato,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: coloreStatoRevisione(stato),
                            visualDensity: VisualDensity.compact,
                          );
                        },
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
                        label: Text(
                          trattamento.attivo ? 'Attivo' : 'Non attivo',
                        ),
                        backgroundColor: trattamento.attivo
                            ? Colors.green.shade100
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ), // DataTable
          ), // SingleChildScrollView orizzontale
        ), // Scrollbar orizzontale
      ), // SingleChildScrollView verticale
    ); // Scrollbar verticale
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
    bool duplica = false,
  }) async {
    final isModifica = trattamento != null;
    final isDuplicazione = duplica && trattamento != null;

    final risultato = await showDialog<_NuovoTrattamentoDialogResult>(
      context: context,
      builder: (dialogContext) {
        return _NuovoTrattamentoDialog(
          trattamento: trattamento,
          duplica: isDuplicazione,
        );
      },
    );

    if (risultato == null) {
      return;
    }

    try {
      final now = DateTime.now().toIso8601String();

      final trattamentoDaSalvare = RegistroTrattamento(
        id: isDuplicazione ? null : trattamento?.id,
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
        dataRevisione: risultato.dataRevisione,
        createdAt: isDuplicazione ? now : trattamento?.createdAt ?? now,
        updatedAt: now,
      );

      if (isModifica && !isDuplicazione) {
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

      final messaggioSalvataggio = isDuplicazione
          ? 'Trattamento "${risultato.nome}" duplicato nel registro.'
          : isModifica
          ? 'Trattamento "${risultato.nome}" modificato.'
          : 'Trattamento "${risultato.nome}" salvato nel registro.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messaggioSalvataggio)));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            isDuplicazione
                ? 'Errore durante la duplicazione del trattamento: $e'
                : isModifica
                ? 'Errore durante la modifica del trattamento: $e'
                : 'Errore durante il salvataggio del trattamento: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabellaOrizzontaleController.dispose();
    _tabellaVerticaleController.dispose();
    ricercaRegistroController.dispose();
    super.dispose();
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

            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                cardRiepilogoRevisione(
                  titolo: 'Scadute',
                  valore: conteggioRevisioniPerStato('Scaduta'),
                  filtro: 'scadute',
                  colore: Colors.red.shade700,
                  sfondo: Colors.red.shade50,
                  icona: Icons.error_outline,
                ),
                cardRiepilogoRevisione(
                  titolo: 'In scadenza',
                  valore: conteggioRevisioniPerStato('In scadenza'),
                  filtro: 'in_scadenza',
                  colore: Colors.orange.shade700,
                  sfondo: Colors.orange.shade50,
                  icona: Icons.warning_amber_outlined,
                ),
                cardRiepilogoRevisione(
                  titolo: 'Programmate',
                  valore: conteggioRevisioniPerStato('Programmata'),
                  filtro: 'programmate',
                  colore: Colors.green.shade700,
                  sfondo: Colors.green.shade50,
                  icona: Icons.event_available_outlined,
                ),
                cardRiepilogoRevisione(
                  titolo: 'Non impostate',
                  valore: conteggioRevisioniPerStato('Non impostata'),
                  filtro: 'non_impostate',
                  colore: Colors.grey.shade700,
                  sfondo: Colors.grey.shade100,
                  icona: Icons.event_busy_outlined,
                ),
                cardRiepilogoRevisione(
                  titolo: 'Da verificare',
                  valore: conteggioRevisioniPerStato('Da verificare'),
                  filtro: 'da_verificare',
                  colore: Colors.blueGrey.shade700,
                  sfondo: Colors.blueGrey.shade50,
                  icona: Icons.manage_search_outlined,
                ),
              ],
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

            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Filtro revisione:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chipFiltroRevisione(valore: 'tutti', etichetta: 'Tutte'),
                      chipFiltroRevisione(
                        valore: 'scadute',
                        etichetta: 'Scadute',
                      ),
                      chipFiltroRevisione(
                        valore: 'in_scadenza',
                        etichetta: 'In scadenza',
                      ),
                      chipFiltroRevisione(
                        valore: 'programmate',
                        etichetta: 'Programmate',
                      ),
                      chipFiltroRevisione(
                        valore: 'non_impostate',
                        etichetta: 'Non impostate',
                      ),
                      chipFiltroRevisione(
                        valore: 'da_verificare',
                        etichetta: 'Da verificare',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: filtriRegistroAttivi ? azzeraFiltriRegistro : null,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Azzera filtri'),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: ricercaRegistroController,
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
                            ricercaRegistroController.clear();
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

            riepilogoOrdinamentoRegistro(),

            const SizedBox(height: 8),

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
    required this.dataRevisione,
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
  final String dataRevisione;
  final String misureSicurezza;
  final String responsabileInterno;
  final String note;
}

class _NuovoTrattamentoDialog extends StatefulWidget {
  final RegistroTrattamento? trattamento;
  final bool duplica;

  const _NuovoTrattamentoDialog({this.trattamento, this.duplica = false});

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
  final TextEditingController _dataRevisioneController =
      TextEditingController();
  final TextEditingController _responsabileInternoController =
      TextEditingController();
  final TextEditingController _misureSicurezzaController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _erroreNome;
  String? _erroreFinalita;
  String? _erroreDataRevisione;

  @override
  void initState() {
    super.initState();

    final trattamento = widget.trattamento;
    if (trattamento == null) {
      return;
    }

    _nomeController.text = widget.duplica
        ? 'Copia di ${trattamento.nomeTrattamento}'
        : trattamento.nomeTrattamento;
    _finalitaController.text = trattamento.finalita;
    _baseGiuridicaController.text = trattamento.baseGiuridica;
    _categorieInteressatiController.text = trattamento.categorieInteressati;
    _categorieDatiController.text = trattamento.categorieDati;
    _destinatariController.text = trattamento.destinatari;
    _trasferimentoExtraUeController.text = trattamento.trasferimentoExtraUe;
    _conservazioneController.text = trattamento.tempiConservazione;
    _dataRevisioneController.text = widget.duplica
        ? ''
        : _normalizzaDataRevisione(trattamento.dataRevisione ?? '');
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
    _dataRevisioneController.dispose();
    _misureSicurezzaController.dispose();
    _responsabileInternoController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  bool _dataRevisioneValida(String valore) {
    final testo = valore.trim();

    if (testo.isEmpty) {
      return true;
    }

    try {
      DateFormat('dd/MM/yyyy').parseStrict(testo);
      return true;
    } catch (_) {
      // Prova formato tecnico ISO solo data: yyyy-MM-dd
    }

    final formatoIsoSoloData = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!formatoIsoSoloData.hasMatch(testo)) {
      return false;
    }

    return DateTime.tryParse(testo) != null;
  }

  String _normalizzaDataRevisione(String valore) {
    final testo = valore.trim();

    if (testo.isEmpty) {
      return '';
    }

    try {
      final data = DateFormat('dd/MM/yyyy').parseStrict(testo);
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (_) {
      // Prova formato tecnico ISO solo data: yyyy-MM-dd
    }

    final formatoIsoSoloData = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!formatoIsoSoloData.hasMatch(testo)) {
      return testo;
    }

    final data = DateTime.tryParse(testo);
    if (data == null) {
      return testo;
    }

    return DateFormat('dd/MM/yyyy').format(data);
  }

  DateTime? _parseDataRevisioneDialog(String valore) {
    final testo = valore.trim();

    if (testo.isEmpty) {
      return null;
    }

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(testo);
    } catch (_) {
      // Prova formato tecnico ISO solo data: yyyy-MM-dd
    }

    final formatoIsoSoloData = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!formatoIsoSoloData.hasMatch(testo)) {
      return null;
    }

    return DateTime.tryParse(testo);
  }

  Future<void> _selezionaDataRevisione() async {
    final dataAttuale =
        _parseDataRevisioneDialog(_dataRevisioneController.text) ??
        DateTime.now();

    final dataScelta = await showDatePicker(
      context: context,
      initialDate: dataAttuale,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleziona data revisione',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
    );

    if (dataScelta == null) {
      return;
    }

    setState(() {
      _dataRevisioneController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(dataScelta);
      _erroreDataRevisione = null;
    });
  }

  void _salva() {
    final nomeVuoto = _nomeController.text.trim().isEmpty;
    final finalitaVuota = _finalitaController.text.trim().isEmpty;
    final dataRevisioneNonValida = !_dataRevisioneValida(
      _dataRevisioneController.text,
    );

    setState(() {
      _erroreNome = nomeVuoto ? 'Inserisci il nome del trattamento' : null;
      _erroreFinalita = finalitaVuota
          ? 'Inserisci la finalità del trattamento'
          : null;
      _erroreDataRevisione = dataRevisioneNonValida
          ? 'Inserisci una data valida nel formato gg/mm/aaaa'
          : null;
    });

    if (nomeVuoto || finalitaVuota || dataRevisioneNonValida) {
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
        dataRevisione: _normalizzaDataRevisione(_dataRevisioneController.text),
        misureSicurezza: _misureSicurezzaController.text.trim(),
        responsabileInterno: _responsabileInternoController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isModifica = widget.trattamento != null;
    final isDuplicazione = widget.duplica && widget.trattamento != null;
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
      Widget? suffixIcon,
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
          suffixIcon: suffixIcon,
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
            isDuplicazione
                ? Icons.copy
                : isModifica
                ? Icons.edit_note
                : Icons.playlist_add,
            color: Colors.blueGrey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.duplica
                  ? 'Duplica trattamento'
                  : isModifica
                  ? 'Modifica trattamento'
                  : 'Nuovo trattamento',
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
                  controller: _dataRevisioneController,
                  label: 'Data revisione',
                  hintText: 'Es. 25/06/2026',
                  errorText: _erroreDataRevisione,
                  suffixIcon: IconButton(
                    tooltip: 'Seleziona data revisione',
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: _selezionaDataRevisione,
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
          icon: Icon(isDuplicazione ? Icons.copy : Icons.save),
          label: Text(
            isDuplicazione
                ? 'Duplica trattamento'
                : isModifica
                ? 'Salva modifiche'
                : 'Salva',
          ),
        ),
      ],
    );
  }
}
