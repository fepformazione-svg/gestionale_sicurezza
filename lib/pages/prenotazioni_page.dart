import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_service.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/prenotazione_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/table_status_badge.dart';

import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PrenotazioniPage extends StatefulWidget {
  final String globalSearch;
  final String filtro;
  final VoidCallback? onDatiModificati;

  const PrenotazioniPage({
    super.key,
    required this.globalSearch,
    this.filtro = 'tutte',
    this.onDatiModificati,
  });

  @override
  State<PrenotazioniPage> createState() => _PrenotazioniPageState();
}

class _PrenotazioniPageState extends State<PrenotazioniPage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController horizontalController = ScrollController();
  final FocusNode ricercaFocusNode = FocusNode();
  final TextEditingController ricercaController = TextEditingController();

  void notificaDatiModificati() {
    widget.onDatiModificati?.call();
  }

  List<Map<String, dynamic>> prenotazioni = [];
  List<Map<String, dynamic>> prenotazioniFiltrate = [];

  final int righePerPaginaDb = 50;
  int paginaDbCorrente = 0;
  bool fineArchivioPrenotazioni = false;
  bool caricamentoPaginaDb = false;
  bool headerShadowVisible = false;

  int? prenotazioneSelezionataId;

  Set<int> prenotazioniSelezionateIds = {};
  int? ultimoIndexSelezionato;

  bool? get statoCheckboxHeader {
    final idsVisibili = prenotazioniVisibili.map((p) => p['id'] as int).toSet();

    if (idsVisibili.isEmpty) return false;

    final selezionateVisibili = idsVisibili
        .where((id) => prenotazioniSelezionateIds.contains(id))
        .length;

    if (selezionateVisibili == 0) return false;
    if (selezionateVisibili == idsVisibili.length) return true;

    return null;
  }

  void toggleSelezionaTutteVisibili() {
    final idsVisibili = prenotazioniVisibili.map((p) => p['id'] as int).toSet();

    if (idsVisibili.isEmpty) return;

    setState(() {
      final tutteGiaSelezionate = idsVisibili.every(
        (id) => prenotazioniSelezionateIds.contains(id),
      );

      if (tutteGiaSelezionate) {
        prenotazioniSelezionateIds.removeAll(idsVisibili);
      } else {
        prenotazioniSelezionateIds.addAll(idsVisibili);
      }
    });
  }

  String filtroLocale = 'aperte';

  String colonnaOrdinata = '';
  bool ordineCrescente = true;

  Future<void> stampaSelezionate() async {
    final prenotazioniDaStampare = prenotazioniVisibili
        .where((p) => prenotazioniSelezionateIds.contains(p['id']))
        .toList();

    if (prenotazioniDaStampare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno una prenotazione da stampare.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final pdf = pw.Document();

    String testo(dynamic valore) {
      if (valore == null) return '';
      return valore.toString();
    }

    String valoreCampo(Map<String, dynamic> p, List<String> chiavi) {
      for (final chiave in chiavi) {
        final valore = p[chiave];

        if (valore != null && valore.toString().trim().isNotEmpty) {
          return valore.toString();
        }
      }

      return '';
    }

    String dataItaliana(dynamic valore) {
      if (valore == null || valore.toString().trim().isEmpty) return '';

      try {
        final data = DateTime.parse(valore.toString());
        return DateFormat('dd/MM/yyyy').format(data);
      } catch (_) {
        return valore.toString();
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              'F&P Formazione e Prevenzione',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Stampa prenotazioni selezionate',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Totale prenotazioni: ${prenotazioniDaStampare.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),

            pw.Table.fromTextArray(
              headers: const [
                'Discente',
                'Impresa',
                'Corso',
                'Data',
                'Prot.',
                'Stato',
              ],
              data: prenotazioniDaStampare.map((p) {
                final discenteCompleto = [
                  testo(p['discente_cognome']),
                  testo(p['discente_nome']),
                ].where((v) => v.trim().isNotEmpty).join(' ');

                String statoPrenotazione() {
                  if (p['conferma'] == 1) return 'Chiusa';
                  if (p['registro'] == 1) return 'Registro';
                  if (p['aperto'] == 1) return 'Aperta';
                  return 'Da fare';
                }

                return [
                  discenteCompleto,
                  testo(p['impresa_nome']),
                  testo(p['corso_nome']),
                  dataItaliana(p['data']),
                  testo(p['prot']),
                  statoPrenotazione(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1.2),
              },
            ),
          ];
        },
      ),
    );

    final documenti = await getApplicationDocumentsDirectory();

    final cartella = Directory(
      '${documenti.path}\\Gestionale Sicurezza\\Stampe\\Prenotazioni',
    );

    if (!await cartella.exists()) {
      await cartella.create(recursive: true);
    }

    final nomeFile =
        'prenotazioni_selezionate_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    final file = File('${cartella.path}\\$nomeFile');

    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      name: nomeFile,
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF creato per ${prenotazioniDaStampare.length} prenotazioni selezionate.',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void selezionaTutto() {
    setState(() {
      prenotazioniSelezionateIds = prenotazioniVisibili
          .map((p) => p['id'] as int)
          .toSet();
    });

    tableFocusNode.requestFocus();
  }

  void deselezionaTutto() {
    setState(() {
      azzeraSelezionePrenotazioni();
    });

    tableFocusNode.requestFocus();
  }

  void azzeraSelezionePrenotazioni() {
    selectedRowIndex = null;
    prenotazioneSelezionataId = null;
    prenotazioniSelezionateIds.clear();
    ultimoIndexSelezionato = null;
  }

  void ripristinaFocusTabella() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      tableFocusNode.requestFocus();
    });
  }

  String testoSelezionePrenotazioni() {
    final totale = prenotazioniSelezionateIds.length;

    if (totale == 1) {
      return '1 prenotazione selezionata';
    }

    return '$totale prenotazioni selezionate';
  }

  String suffissoSelezionatePrenotazioni() {
    return prenotazioniSelezionateIds.length == 1
        ? 'selezionata'
        : 'selezionate';
  }

  Future<void> registroSelezionate() async {
    if (prenotazioniSelezionateIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una prenotazione')),
      );
      return;
    }

    await aggiornaStatoPrenotazioniSelezionate(
      aperto: 0,
      registro: 1,
      conferma: 0,
    );
  }

  List<Map<String, dynamic>> get prenotazioniVisibili {
    final filtroAttivo = filtroLocale;
    final query = ricercaController.text.toLowerCase().trim();

    return prenotazioni.where((p) {
      final stato = statoPrenotazione(p);

      if (filtroAttivo == 'aperte' && stato != 'Aperto') return false;
      if (filtroAttivo == 'registro' && stato != 'Registro') return false;
      if (filtroAttivo == 'chiuse' && stato != 'Chiuso') return false;
      if (filtroAttivo == 'da_fare' && stato != 'Da fare') return false;

      if (query.isEmpty) return true;

      final discente = nomeDiscente(p).toLowerCase();
      final impresa = testo(p['impresa_nome']).toLowerCase();
      final corso = testo(p['corso_nome']).toLowerCase();
      final data = testo(p['data']).toLowerCase();
      final prot = testo(p['prot']).toLowerCase();

      return discente.contains(query) ||
          impresa.contains(query) ||
          corso.contains(query) ||
          data.contains(query) ||
          prot.contains(query) ||
          stato.toLowerCase().contains(query);
    }).toList();
  }

  void gestisciSelezioneMassiva({
    required int index,
    required Map<String, dynamic> prenotazione,
    required bool ctrlPremuto,
    required bool shiftPremuto,
  }) {
    final id = prenotazione['id'] as int;

    tableFocusNode.requestFocus();

    setState(() {
      if (shiftPremuto && ultimoIndexSelezionato != null) {
        final start = ultimoIndexSelezionato! < index
            ? ultimoIndexSelezionato!
            : index;
        final end = ultimoIndexSelezionato! > index
            ? ultimoIndexSelezionato!
            : index;

        for (int i = start; i <= end; i++) {
          final idRange = prenotazioniVisibili[i]['id'] as int;
          prenotazioniSelezionateIds.add(idRange);
        }
      } else if (ctrlPremuto) {
        if (prenotazioniSelezionateIds.contains(id)) {
          prenotazioniSelezionateIds.remove(id);
        } else {
          prenotazioniSelezionateIds.add(id);
        }

        ultimoIndexSelezionato = index;
      } else {
        prenotazioniSelezionateIds
          ..clear()
          ..add(id);

        ultimoIndexSelezionato = index;
      }

      prenotazioneSelezionataId = id;
      selectedRowIndex = index;
    });
  }

  Future<void> aggiornaStatoPrenotazioniSelezionate({
    required int aperto,
    required int registro,
    required int conferma,
  }) async {
    final ids = prenotazioniSelezionateIds.toList();
    debugPrint('AZIONE MASSIVA IDS: $ids');

    if (ids.isEmpty) return;

    for (final id in ids) {
      await DatabaseService.instance.aggiornaStatoPrenotazione(
        id: id,
        aperto: aperto,
        registro: registro,
        conferma: conferma,
      );
    }

    setState(() {
      prenotazioni = prenotazioni.map((p) {
        if (ids.contains(p['id'])) {
          return {
            ...p,
            'aperto': aperto,
            'registro': registro,
            'conferma': conferma,
          };
        }
        return p;
      }).toList();

      prenotazioniFiltrate = prenotazioniFiltrate.map((p) {
        if (ids.contains(p['id'])) {
          return {
            ...p,
            'aperto': aperto,
            'registro': registro,
            'conferma': conferma,
          };
        }
        return p;
      }).toList();

      prenotazioniSelezionateIds.clear();
      ultimoIndexSelezionato = null;
      prenotazioneSelezionataId = null;
      selectedRowIndex = null;
    });

    notificaDatiModificati();
  }

  Future<void> caricaPrenotazioniIniziali() async {
    setState(() {
      loading = true;
      caricamentoPaginaDb = true;
      paginaDbCorrente = 0;
      fineArchivioPrenotazioni = false;

      prenotazioni.clear();
      prenotazioniFiltrate.clear();
    });

    try {
      final dati = await DatabaseService.instance.getPrenotazioniPaged(
        limit: righePerPaginaDb,
        offset: 0,
      );

      setState(() {
        prenotazioni = dati;
        prenotazioniFiltrate = dati;

        paginaDbCorrente = 1;

        if (dati.length < righePerPaginaDb) {
          fineArchivioPrenotazioni = true;
        }
      });
    } catch (e) {
      debugPrint('ERRORE caricaPrenotazioniIniziali: $e');
    } finally {
      setState(() {
        loading = false;
        caricamentoPaginaDb = false;
      });
    }
  }

  bool loading = true;

  final FocusNode tableFocusNode = FocusNode();
  int? selectedRowIndex;

  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final showShadow = _scrollController.offset > 0;

      if (showShadow != headerShadowVisible) {
        setState(() {
          headerShadowVisible = showShadow;
        });
      }
    });

    ricercaFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        ricercaController.text = '';
        ricercaController.selection = const TextSelection.collapsed(offset: 0);

        setState(() {
          prenotazioniFiltrate = List<Map<String, dynamic>>.from(prenotazioni);
          selectedRowIndex = 0;
          prenotazioneSelezionataId = prenotazioniFiltrate.isNotEmpty
              ? prenotazioniFiltrate.first['id'] as int?
              : null;
        });

        tableFocusNode.requestFocus();
        scrollToSelectedRow();

        return KeyEventResult.handled;
      }

      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          selectedRowIndex = 0;
          prenotazioneSelezionataId = prenotazioniVisibili.isNotEmpty
              ? prenotazioniVisibili.first['id'] as int?
              : null;
        });

        tableFocusNode.requestFocus();
        scrollToSelectedRow();

        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    };

    caricaPrenotazioniIniziali();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        caricaAltrePrenotazioni();
      }
    });
  }

  @override
  void dispose() {
    tableFocusNode.dispose();
    _scrollController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  void gestisciTasti(RawKeyEvent event) async {
    if (event is! RawKeyDownEvent) return;

    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      ricercaFocusNode.requestFocus();

      ricercaController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: ricercaController.text.length,
      );

      return;
    }

    // CTRL + A
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      setState(() {
        prenotazioniSelezionateIds = prenotazioniVisibili
            .map((p) => p['id'] as int)
            .toSet();

        prenotazioneSelezionataId = prenotazioniVisibili.isNotEmpty
            ? prenotazioniVisibili.first['id'] as int
            : null;

        selectedRowIndex = prenotazioniVisibili.isNotEmpty ? 0 : null;

        ultimoIndexSelezionato = prenotazioniVisibili.isNotEmpty
            ? prenotazioniVisibili.length - 1
            : null;
      });

      return;
    }
    // CTRL + N
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
      apriDialogNuovaPrenotazione();
      return;
    }

    // CTRL + E
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyE) {
      exportPrenotazioniExcel();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      tableFocusNode.requestFocus();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight ||
        event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight) {
      return;
    }

    if (prenotazioniVisibili.isEmpty) return;

    int nuovoIndex = selectedRowIndex ?? 0;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (nuovoIndex < prenotazioniVisibili.length - 1) {
        nuovoIndex++;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (nuovoIndex > 0) {
        nuovoIndex--;
      }
    }

    final p = prenotazioniVisibili[nuovoIndex];

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      modificaPrenotazione(p);
      return;
    }

    // F2
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      modificaPrenotazione(p);
      return;
    }

    // DEL
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      eliminaPrenotazione(p);
      return;
    }

    // SPACE = cambia stato
    if (event.logicalKey == LogicalKeyboardKey.space) {
      debugPrint('SPACE PREMUTO');

      final id = p['id'];
      final stato = statoPrenotazione(p);

      int nuovoAperto = 0;
      int nuovoRegistro = 0;
      int nuovoConferma = 0;

      if (stato == 'Da fare') {
        nuovoAperto = 1;
      } else if (stato == 'Aperto') {
        nuovoRegistro = 1;
      } else if (stato == 'Registro') {
        nuovoConferma = 1;
      }

      setState(() {
        prenotazioni = prenotazioni.map((item) {
          if (item['id'] == id) {
            return {
              ...item,
              'aperto': nuovoAperto,
              'registro': nuovoRegistro,
              'conferma': nuovoConferma,
            };
          }
          return item;
        }).toList();

        prenotazioniFiltrate = prenotazioniFiltrate.map((item) {
          if (item['id'] == id) {
            return {
              ...item,
              'aperto': nuovoAperto,
              'registro': nuovoRegistro,
              'conferma': nuovoConferma,
            };
          }
          return item;
        }).toList();
      });

      await DatabaseService.instance.aggiornaStatoPrenotazione(
        id: id,
        aperto: nuovoAperto,
        registro: nuovoRegistro,
        conferma: nuovoConferma,
      );

      notificaDatiModificati();

      return;
    }

    setState(() {
      selectedRowIndex = nuovoIndex;
      prenotazioneSelezionataId = p['id'] as int?;
    });

    Future.delayed(Duration.zero, () {
      tableFocusNode.requestFocus();
      scrollToSelectedRow();
    });
  }

  void scrollToSelectedRow() {
    if (selectedRowIndex == null) return;
    if (!_scrollController.hasClients) return;

    final targetOffset = selectedRowIndex! * 64.0;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  Future<void> caricaAltrePrenotazioni() async {
    if (caricamentoPaginaDb || fineArchivioPrenotazioni) return;

    setState(() {
      caricamentoPaginaDb = true;
    });

    final dati = await DatabaseService.instance.getPrenotazioniPaged(
      limit: righePerPaginaDb,
      offset: paginaDbCorrente * righePerPaginaDb,
    );

    setState(() {
      prenotazioni.addAll(dati);
      prenotazioniFiltrate = prenotazioni;

      paginaDbCorrente++;

      caricamentoPaginaDb = false;

      if (dati.length < righePerPaginaDb) {
        fineArchivioPrenotazioni = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant PrenotazioniPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.globalSearch != widget.globalSearch ||
        oldWidget.filtro != widget.filtro) {
      cercaPrenotazioni(widget.globalSearch);
    }
  }

  String testo(dynamic value) {
    return (value ?? '').toString();
  }

  String nomeDiscente(Map<String, dynamic> p) {
    final cognome = testo(p['discente_cognome']);
    final nome = testo(p['discente_nome']);

    return '$cognome $nome'.trim();
  }

  String etichettaFiltroPrenotazioni(String filtro) {
    switch (filtro) {
      case 'aperte':
        return 'Aperte';
      case 'registro':
        return 'Registro';
      case 'chiuse':
        return 'Chiuse';
      case 'da_fare':
        return 'Da fare';
      case 'tutte':
      default:
        return 'Tutte';
    }
  }

  String tooltipFiltroPrenotazioni(String filtro) {
    switch (filtro) {
      case 'aperte':
        return 'Mostra solo le prenotazioni aperte';
      case 'registro':
        return 'Mostra solo le prenotazioni in registro';
      case 'chiuse':
        return 'Mostra solo le prenotazioni chiuse';
      case 'da_fare':
        return 'Mostra solo le prenotazioni da fare';
      case 'tutte':
      default:
        return 'Mostra tutte le prenotazioni';
    }
  }

  String statoPrenotazione(Map<String, dynamic> p) {
    final conferma = p['conferma'] == 1;
    final registro = p['registro'] == 1;
    final aperto = p['aperto'] == 1;

    if (registro) return 'Registro';
    if (conferma) return 'Chiuso';
    if (aperto) return 'Aperto';
    return 'Da fare';
  }

  void ordinaPrenotazioni(String colonna) {
    setState(() {
      if (colonnaOrdinata == colonna) {
        ordineCrescente = !ordineCrescente;
      } else {
        colonnaOrdinata = colonna;
        ordineCrescente = true;
      }

      int confronta(Map<String, dynamic> a, Map<String, dynamic> b) {
        int confronto = 0;

        switch (colonna) {
          case 'discente':
            confronto = nomeDiscente(
              a,
            ).toLowerCase().compareTo(nomeDiscente(b).toLowerCase());
            break;

          case 'impresa':
            confronto = testo(
              a['impresa_nome'],
            ).toLowerCase().compareTo(testo(b['impresa_nome']).toLowerCase());
            break;

          case 'corso':
            confronto = testo(
              a['corso_nome'],
            ).toLowerCase().compareTo(testo(b['corso_nome']).toLowerCase());
            break;

          case 'data':
            confronto = numeroData(a['data']).compareTo(numeroData(b['data']));
            break;

          case 'prot':
            confronto = testo(a['prot']).compareTo(testo(b['prot']));
            break;

          case 'stato':
            confronto = statoPrenotazione(
              a,
            ).toLowerCase().compareTo(statoPrenotazione(b).toLowerCase());
            break;
        }

        return ordineCrescente ? confronto : -confronto;
      }

      prenotazioni = List<Map<String, dynamic>>.from(prenotazioni)
        ..sort(confronta);

      selectedRowIndex = null;
      prenotazioneSelezionataId = null;
    });
  }

  DateTime dataOrdinabile(dynamic valore) {
    if (valore == null) {
      return DateTime(1900);
    }

    final dataTesto = valore.toString().trim();

    if (dataTesto.isEmpty) {
      return DateTime(1900);
    }

    try {
      return DateTime.parse(dataTesto);
    } catch (_) {
      return DateTime(1900);
    }
  }

  int numeroData(dynamic valore) {
    final testoData = valore.toString().trim();

    final parti = testoData.split('/');

    if (parti.length != 3) {
      return 0;
    }

    final giorno = int.tryParse(parti[0]) ?? 0;
    final mese = int.tryParse(parti[1]) ?? 0;
    final anno = int.tryParse(parti[2]) ?? 0;

    return anno * 10000 + mese * 100 + giorno;
  }

  Map<String, dynamic> normalizzaPrenotazione(Map<String, dynamic> dati) {
    return {
      'discente_id': dati['discente_id'],
      'impresa_id': dati['impresa_id'],
      'corso_id': dati['corso_id'],
      'data': testo(dati['data']).trim(),
      'prot': testo(dati['prot']).trim(),
      'aperto': dati['aperto'] == 1 ? 1 : 0,
      'conferma': dati['conferma'] == 1 ? 1 : 0,
      'registro': dati['registro'] == 1 ? 1 : 0,
    };
  }

  Future<void> caricaPrenotazioni() async {
    setState(() {
      loading = true;
      paginaDbCorrente = 0;
      fineArchivioPrenotazioni = false;
      prenotazioni = [];
      prenotazioniFiltrate = [];
    });

    await caricaPaginaPrenotazioni(reset: true);
  }

  Future<void> caricaPaginaPrenotazioni({bool reset = false}) async {
    if (caricamentoPaginaDb || fineArchivioPrenotazioni) return;

    setState(() {
      caricamentoPaginaDb = true;
    });

    try {
      final offset = paginaDbCorrente * righePerPaginaDb;

      final dati = await DatabaseService.instance.getPrenotazioniPaged(
        limit: righePerPaginaDb,
        offset: offset,
      );

      setState(() {
        if (reset) {
          prenotazioni.clear();
        }

        prenotazioni.addAll(dati);
        prenotazioniFiltrate = List.from(prenotazioni);

        paginaDbCorrente++;

        if (dati.length < righePerPaginaDb) {
          fineArchivioPrenotazioni = true;
        }

        caricamentoPaginaDb = false;
        loading = false;
      });

      if (widget.globalSearch.trim().isNotEmpty) {
        cercaPrenotazioni(widget.globalSearch);
      }
    } catch (e) {
      setState(() {
        caricamentoPaginaDb = false;
        loading = false;
      });

      debugPrint('Errore caricamento prenotazioni paged: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento prenotazioni: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void cercaPrenotazioni(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        prenotazioniFiltrate = prenotazioni;
        return;
      }

      prenotazioniFiltrate = prenotazioni.where((p) {
        final discente = nomeDiscente(p).toLowerCase();
        final impresa = testo(p['impresa_nome']).toLowerCase();
        final corso = testo(p['corso_nome']).toLowerCase();
        final data = testo(p['data']).toLowerCase();
        final prot = testo(p['prot']).toLowerCase();
        final stato = statoPrenotazione(p).toLowerCase();

        return discente.contains(query) ||
            impresa.contains(query) ||
            corso.contains(query) ||
            data.contains(query) ||
            prot.contains(query) ||
            stato.contains(query);
      }).toList();
    });
  }

  void ordina<T>(
    int columnIndex,
    bool ascending,
    Comparable<T> Function(Map<String, dynamic> p) getField,
  ) {
    prenotazioniFiltrate.sort((a, b) {
      if (!ascending) {
        final c = a;
        a = b;
        b = c;
      }

      final aValue = getField(a);
      final bValue = getField(b);

      return Comparable.compare(aValue, bValue);
    });

    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }

  Future<void> apriDialogNuovaPrenotazione() async {
    final nuovaPrenotazione = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return const PrenotazioneDialog();
      },
    );

    if (nuovaPrenotazione == null) return;

    try {
      final datiPuliti = normalizzaPrenotazione(nuovaPrenotazione);

      final nuovoId = await DatabaseService.instance.insertPrenotazione(
        datiPuliti,
      );

      if (datiPuliti['conferma'] == 1) {
        await DatabaseService.instance.confermaPrenotazioneWorkflow(nuovoId);
      }

      await caricaPrenotazioni();
      notificaDatiModificati();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prenotazione salvata')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore salvataggio prenotazione: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> modificaPrenotazione(Map<String, dynamic> prenotazione) async {
    final prenotazioneModificata = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return PrenotazioneDialog(prenotazione: prenotazione);
      },
    );

    if (prenotazioneModificata == null) return;

    try {
      final datiPuliti = normalizzaPrenotazione(prenotazioneModificata);

      await DatabaseService.instance.updatePrenotazione(
        prenotazione['id'],
        datiPuliti,
      );

      if (datiPuliti['conferma'] == 1) {
        await DatabaseService.instance.confermaPrenotazioneWorkflow(
          prenotazione['id'],
        );
      } else {
        await DatabaseService.instance.annullaConfermaPrenotazioneWorkflow(
          prenotazione['id'],
        );
      }

      await caricaPrenotazioni();
      notificaDatiModificati();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prenotazione aggiornata')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore modifica prenotazione: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> eliminaPrenotazione(Map<String, dynamic> prenotazione) async {
    final bool prenotazioneConfermata =
        prenotazione['conferma'] == 1 || prenotazione['conferma'] == true;

    final corsoPrenotazione =
        (prenotazione['corso'] ??
                prenotazione['corso_nome'] ??
                prenotazione['denominazione_corso'] ??
                prenotazione['corso_denominazione'] ??
                prenotazione['nome_corso'] ??
                prenotazione['denominazione'] ??
                '')
            .toString()
            .trim();

    if (prenotazioneConfermata) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFF97316),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Impossibile eliminare',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Text(
                'La prenotazione di ${nomeDiscente(prenotazione)} non può essere eliminata perché è già stata confermata.\n\n'
                'Corso: ${corsoPrenotazione.isEmpty ? '-' : corsoPrenotazione}\n\n'
                'Per mantenere coerenti Diario, Scadenze e Storico formativo, le prenotazioni confermate non vanno cancellate direttamente.',
                style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ok',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );

      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Elimina prenotazione',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            'Vuoi eliminare la prenotazione di ${nomeDiscente(prenotazione)}?\n\n'
            'Corso: ${corsoPrenotazione.isEmpty ? '-' : corsoPrenotazione}\n\n'
            'Questa operazione non può essere annullata.',
            style: const TextStyle(height: 1.45, fontWeight: FontWeight.w500),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Annulla',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text(
                'Elimina prenotazione',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.deletePrenotazione(prenotazione['id']);

    await caricaPrenotazioni();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Prenotazione di ${nomeDiscente(prenotazione)} eliminata correttamente.',
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget filtroChip({
    required String titolo,
    required String filtro,
    required Color colore,
  }) {
    final attivo =
        (filtroLocale.isNotEmpty ? filtroLocale : widget.filtro) == filtro;

    return Tooltip(
      message: tooltipFiltroPrenotazioni(filtro),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            filtroLocale = filtro;
            azzeraSelezionePrenotazioni();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: attivo ? colore.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: attivo ? colore : Colors.grey.shade300,
              width: attivo ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colore,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                titolo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: attivo ? colore : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget compactKpiCard({
    required String titolo,
    required String valore,
    required Color colore,
    required String filtro,
  }) {
    final attivo =
        (filtroLocale.isNotEmpty ? filtroLocale : widget.filtro) == filtro;

    return Tooltip(
      message: tooltipFiltroPrenotazioni(filtro),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            filtroLocale = filtro;
            azzeraSelezionePrenotazioni();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: attivo ? colore : Colors.grey.shade300,
              width: attivo ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colore,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                valore,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colore,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                titolo,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> exportPrenotazioniExcel() async {
    try {
      if (prenotazioniVisibili.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessuna prenotazione da esportare'),
            backgroundColor: Color(0xFFF97316),
            duration: Duration(seconds: 4),
          ),
        );

        ripristinaFocusTabella();
        return;
      }

      final excel = Excel.createExcel();

      final sheet = excel['Prenotazioni'];

      excel.delete('Sheet1');

      sheet.setColumnWidth(0, 52); // Discente / riga informativa export
      sheet.setColumnWidth(1, 26); // Impresa
      sheet.setColumnWidth(2, 38); // Corso
      sheet.setColumnWidth(3, 16); // Data
      sheet.setColumnWidth(4, 18); // Protocollo
      sheet.setColumnWidth(5, 16); // Stato

      // RIGA INFORMATIVA EXPORT
      final nowInfo = DateTime.now();

      final dataOraExport =
          '${nowInfo.day.toString().padLeft(2, '0')}/'
          '${nowInfo.month.toString().padLeft(2, '0')}/'
          '${nowInfo.year} '
          '${nowInfo.hour.toString().padLeft(2, '0')}:'
          '${nowInfo.minute.toString().padLeft(2, '0')}';

      final exportFiltratoInfo =
          ricercaController.text.trim().isNotEmpty || filtroLocale != 'tutte';

      final testoInfoExport = exportFiltratoInfo
          ? 'Export prenotazioni filtrato - ${prenotazioniVisibili.length} record - $dataOraExport'
          : 'Export prenotazioni - ${prenotazioniVisibili.length} record - $dataOraExport';

      sheet.appendRow([
        TextCellValue(testoInfoExport),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle = CellStyle(
        bold: true,
      );

      // RIGA VUOTA
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      // HEADER
      sheet.appendRow([
        TextCellValue('Discente'),
        TextCellValue('Impresa'),
        TextCellValue('Corso'),
        TextCellValue('Data'),
        TextCellValue('Protocollo'),
        TextCellValue('Stato'),
      ]);

      for (int col = 0; col < 6; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2),
        );

        cell.cellStyle = CellStyle(bold: true);
      }

      // DATI
      for (final p in prenotazioniVisibili) {
        sheet.appendRow([
          TextCellValue(nomeDiscente(p)),
          TextCellValue(testo(p['impresa_nome'])),
          TextCellValue(testo(p['corso_nome'])),
          TextCellValue(testo(p['data'])),
          TextCellValue(testo(p['prot'])),
          TextCellValue(statoPrenotazione(p)),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();

      final now = DateTime.now();

      final timestamp =
          '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}h${now.minute.toString().padLeft(2, '0')}';

      final vistaFiltrata =
          ricercaController.text.trim().isNotEmpty || filtroLocale != 'tutte';

      final nomeFile = vistaFiltrata
          ? 'prenotazioni_export_filtrato_$timestamp.xlsx'
          : 'prenotazioni_export_$timestamp.xlsx';

      final path = '${directory.path}/$nomeFile';

      final fileBytes = excel.encode();

      if (fileBytes == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la creazione del file Excel'),
            backgroundColor: Color(0xFFDC2626),
            duration: Duration(seconds: 3),
          ),
        );

        ripristinaFocusTabella();
        return;
      }

      final file = File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await OpenFile.open(file.path);

      if (!mounted) return;

      final totaleEsportate = prenotazioniVisibili.length;

      final messaggioExport = totaleEsportate == 1
          ? vistaFiltrata
                ? 'Export Excel completato: 1 prenotazione esportata dalla vista filtrata'
                : 'Export Excel completato: 1 prenotazione esportata'
          : vistaFiltrata
          ? 'Export Excel completato: $totaleEsportate prenotazioni esportate dalla vista filtrata'
          : 'Export Excel completato: $totaleEsportate prenotazioni esportate';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messaggioExport),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 5),
        ),
      );

      ripristinaFocusTabella();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore export Excel: $e'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );

      ripristinaFocusTabella();
    }
  }

  Future<void> esportaPdf() async {
    if (prenotazioniVisibili.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna prenotazione da esportare in PDF'),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 4),
        ),
      );

      ripristinaFocusTabella();
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text(
            'PRENOTAZIONI',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['Discente', 'Impresa', 'Corso', 'Data', 'Prot.', 'Stato'],

            data: prenotazioniVisibili.map((p) {
              return [
                nomeDiscente(p),
                testo(p['impresa_nome']),
                testo(p['corso_nome']),
                testo(p['data']),
                testo(p['prot']),
                statoPrenotazione(p),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/prenotazioni.pdf');

    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);

    if (!mounted) return;

    final totaleEsportate = prenotazioniVisibili.length;

    final vistaFiltrata =
        ricercaController.text.trim().isNotEmpty || filtroLocale != 'tutte';

    final messaggioExportPdf = totaleEsportate == 1
        ? vistaFiltrata
              ? 'Export PDF completato: 1 prenotazione esportata dalla vista filtrata'
              : 'Export PDF completato: 1 prenotazione esportata'
        : vistaFiltrata
        ? 'Export PDF completato: $totaleEsportate prenotazioni esportate dalla vista filtrata'
        : 'Export PDF completato: $totaleEsportate prenotazioni esportate';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggioExportPdf),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 5),
      ),
    );

    ripristinaFocusTabella();
  }

  Widget headerOrdinabile(String titolo, double larghezza, String colonna) {
    final attiva = colonnaOrdinata == colonna;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ordinaPrenotazioni(colonna),
      child: SizedBox(
        width: larghezza,
        height: 39,
        child: Tooltip(
          message: attiva
              ? ordineCrescente
                    ? 'Ordinamento crescente attivo - clicca per invertire'
                    : 'Ordinamento decrescente attivo - clicca per invertire'
              : 'Ordina per $titolo',
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    titolo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: attiva
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),

                const SizedBox(width: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: attiva
                      ? Container(
                          key: ValueKey('attiva_${colonna}_${ordineCrescente}'),
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Icon(
                            ordineCrescente
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: const Color(0xFF2563EB),
                          ),
                        )
                      : Container(
                          key: ValueKey('inattiva_$colonna'),
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.unfold_more_rounded,
                            size: 15,
                            color: Color(0xFF94A3B8),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final ultraWide = width > 1800;
    final desktop = width > 1400;
    final tablet = width < 1100;

    final double tableWidth =
        colDiscente +
        colImpresa +
        colCorso +
        colData +
        colProt +
        colStato +
        colAzioni +
        (tablet ? 24 : 40);

    final double rowHeight = 64;
    final int numeroRighe =
        prenotazioniVisibili.length + (caricamentoPaginaDb ? 1 : 0);

    final double altezzaRighe = numeroRighe * rowHeight;

    final double altezzaMassimaTabella =
        (MediaQuery.of(context).size.height * 0.28).clamp(160.0, 280.0);

    final double altezzaMinimaTabella = rowHeight * 2;

    final double altezzaTabella = altezzaRighe < altezzaMinimaTabella
        ? altezzaMinimaTabella
        : altezzaRighe > altezzaMassimaTabella
        ? altezzaMassimaTabella
        : altezzaRighe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Prenotazioni',
          subtitle: 'Gestione enterprise delle prenotazioni.',
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: Tooltip(
                message:
                    'Cerca per discente, impresa, corso, data o protocollo',
                child: AppSearchBar(
                  controller: ricercaController,
                  focusNode: ricercaFocusNode,
                  hintText: 'Ricerca nella pagina prenotazioni...',

                  onArrowDown: () {
                    if (prenotazioniVisibili.isEmpty) return;

                    setState(() {
                      selectedRowIndex = 0;

                      prenotazioneSelezionataId =
                          prenotazioniVisibili.first['id'] as int?;
                    });

                    tableFocusNode.requestFocus();

                    scrollToSelectedRow();
                  },

                  onChanged: (value) {
                    cercaPrenotazioni(value);

                    setState(() {
                      azzeraSelezionePrenotazioni();
                    });
                  },
                ),
              ),
            ),

            const SizedBox(width: 16),

            Tooltip(
              message: prenotazioniVisibili.isEmpty
                  ? 'Nessuna prenotazione da esportare'
                  : prenotazioniVisibili.length == 1
                  ? 'Esporta 1 prenotazione visualizzata in Excel'
                  : 'Esporta ${prenotazioniVisibili.length} prenotazioni visualizzate in Excel',
              child: ElevatedButton.icon(
                onPressed: prenotazioniVisibili.isEmpty
                    ? null
                    : () {
                        setState(() {
                          azzeraSelezionePrenotazioni();
                        });

                        exportPrenotazioniExcel();
                      },
                icon: const Icon(Icons.table_view_outlined),
                label: Text(
                  prenotazioniVisibili.isEmpty
                      ? 'Esporta elenco Excel'
                      : 'Esporta Excel (${prenotazioniVisibili.length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFF8FAFC),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: prenotazioniVisibili.isEmpty
                          ? const Color(0xFFE2E8F0)
                          : Colors.grey.shade300,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            Tooltip(
              message: prenotazioniVisibili.isEmpty
                  ? 'Nessuna prenotazione da esportare in PDF'
                  : prenotazioniVisibili.length == 1
                  ? 'Esporta 1 prenotazione visualizzata in PDF'
                  : 'Esporta ${prenotazioniVisibili.length} prenotazioni visualizzate in PDF',
              child: ElevatedButton.icon(
                onPressed: prenotazioniVisibili.isEmpty
                    ? null
                    : () {
                        setState(() {
                          azzeraSelezionePrenotazioni();
                        });

                        esportaPdf();
                      },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  prenotazioniVisibili.isEmpty
                      ? 'Esporta PDF'
                      : 'Esporta PDF (${prenotazioniVisibili.length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFDC2626),
                  disabledBackgroundColor: const Color(0xFFF8FAFC),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: prenotazioniVisibili.isEmpty
                          ? const Color(0xFFE2E8F0)
                          : Colors.grey.shade300,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Tooltip(
              message: 'Crea una nuova prenotazione',
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    azzeraSelezionePrenotazioni();
                  });

                  apriDialogNuovaPrenotazione();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuova prenotazione'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),

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
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Elenco prenotazioni',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ricercaController.text.trim().isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
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
                                        size: 16,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ricerca attiva: ${ricercaController.text.trim()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],

                              if (filtroLocale != 'tutte') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.filter_alt_rounded,
                                        size: 16,
                                        color: Color(0xFFF97316),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Filtro attivo: ${etichettaFiltroPrenotazioni(filtroLocale)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFC2410C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],

                              if (ricercaController.text.trim().isNotEmpty ||
                                  filtroLocale != 'tutte') ...[
                                Tooltip(
                                  message:
                                      ricercaController.text
                                              .trim()
                                              .isNotEmpty &&
                                          filtroLocale != 'tutte'
                                      ? 'Azzera ricerca e filtro attivo'
                                      : ricercaController.text.trim().isNotEmpty
                                      ? 'Azzera la ricerca attiva'
                                      : 'Azzera il filtro attivo',
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        ricercaController.clear();
                                        filtroLocale = 'tutte';
                                        prenotazioniFiltrate =
                                            List<Map<String, dynamic>>.from(
                                              prenotazioni,
                                            );
                                        azzeraSelezionePrenotazioni();
                                      });

                                      ripristinaFocusTabella();
                                    },
                                    icon: const Icon(
                                      Icons.restart_alt_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Azzera filtri',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(
                                        color: Color(0xFFBFDBFE),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],

                              Builder(
                                builder: (context) {
                                  final numeroPrenotazioniVisibili =
                                      prenotazioniVisibili.length;
                                  final testoPrenotazione =
                                      numeroPrenotazioniVisibili == 1
                                      ? 'prenotazione'
                                      : 'prenotazioni';

                                  final filtriAttivi =
                                      ricercaController.text
                                          .trim()
                                          .isNotEmpty ||
                                      filtroLocale != 'tutte';

                                  return Tooltip(
                                    message:
                                        ricercaController.text.trim().isNotEmpty
                                        ? 'Numero di prenotazioni trovate con la ricerca attiva - clicca per azzerare'
                                        : filtroLocale != 'tutte'
                                        ? 'Numero di prenotazioni visualizzate con il filtro attivo - clicca per azzerare'
                                        : 'Numero totale di prenotazioni visualizzate',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: filtriAttivi
                                          ? () {
                                              ricercaController.clear();

                                              setState(() {
                                                filtroLocale = 'tutte';
                                              });

                                              azzeraSelezionePrenotazioni();
                                            }
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: filtriAttivi
                                              ? const Color(0xFFEFF6FF)
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: filtriAttivi
                                                ? const Color(0xFFBFDBFE)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              filtriAttivi
                                                  ? Icons.filter_alt_off_rounded
                                                  : Icons
                                                        .format_list_bulleted_rounded,
                                              size: 14,
                                              color: filtriAttivi
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              ricercaController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? '$numeroPrenotazioniVisibili $testoPrenotazione ${numeroPrenotazioniVisibili == 1 ? 'trovata' : 'trovate'}'
                                                  : filtroLocale != 'tutte'
                                                  ? '$numeroPrenotazioniVisibili $testoPrenotazione ${numeroPrenotazioniVisibili == 1 ? 'visualizzata' : 'visualizzate'}'
                                                  : '$numeroPrenotazioniVisibili $testoPrenotazione',
                                              style: TextStyle(
                                                color: filtriAttivi
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFF64748B),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: [
                          compactKpiCard(
                            titolo: 'Totale',
                            valore: prenotazioniFiltrate.length.toString(),
                            colore: const Color(0xFF2563EB),
                            filtro: 'tutte',
                          ),

                          compactKpiCard(
                            titolo: 'Aperte',
                            valore: prenotazioniFiltrate
                                .where((p) => statoPrenotazione(p) == 'Aperto')
                                .length
                                .toString(),
                            colore: Colors.green,
                            filtro: 'aperte',
                          ),

                          compactKpiCard(
                            titolo: 'Registro',
                            valore: prenotazioniFiltrate
                                .where(
                                  (p) => statoPrenotazione(p) == 'Registro',
                                )
                                .length
                                .toString(),
                            colore: Colors.orange,
                            filtro: 'registro',
                          ),

                          compactKpiCard(
                            titolo: 'Chiuse',
                            valore: prenotazioniFiltrate
                                .where((p) => statoPrenotazione(p) == 'Chiuso')
                                .length
                                .toString(),
                            colore: Colors.grey,
                            filtro: 'chiuse',
                          ),

                          compactKpiCard(
                            titolo: 'Da fare',
                            valore: prenotazioniFiltrate
                                .where((p) => statoPrenotazione(p) == 'Da fare')
                                .length
                                .toString(),
                            colore: Colors.red,
                            filtro: 'da_fare',
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          filtroChip(
                            titolo: 'Tutte (${prenotazioniFiltrate.length})',
                            filtro: 'tutte',
                            colore: Colors.blue,
                          ),

                          filtroChip(
                            titolo:
                                'Aperte (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Aperto').length})',
                            filtro: 'aperte',
                            colore: Colors.green,
                          ),

                          filtroChip(
                            titolo:
                                'Registro (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Registro').length})',
                            filtro: 'registro',
                            colore: Colors.orange,
                          ),

                          filtroChip(
                            titolo:
                                'Chiuse (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Chiuso').length})',
                            filtro: 'chiuse',
                            colore: Colors.grey,
                          ),

                          filtroChip(
                            titolo:
                                'Da fare (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Da fare').length})',
                            filtro: 'da_fare',
                            colore: Colors.red,
                          ),

                          if (prenotazioniSelezionateIds.isNotEmpty)
                            Tooltip(
                              message: prenotazioniSelezionateIds.length == 1
                                  ? '1 prenotazione selezionata'
                                  : '${prenotazioniSelezionateIds.length} prenotazioni selezionate',
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
                                    width: 1.1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      testoSelezionePrenotazioni(),
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (prenotazioniSelezionateIds.isNotEmpty) ...[
                        const SizedBox(height: 12),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              width: constraints.maxWidth,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Tooltip(
                                    message: prenotazioniVisibili.isEmpty
                                        ? 'Nessuna prenotazione attualmente visibile'
                                        : prenotazioniSelezionateIds.length ==
                                              prenotazioniVisibili.length
                                        ? 'Le prenotazioni visibili sono già selezionate'
                                        : prenotazioniSelezionateIds.isNotEmpty
                                        ? 'Aggiungi alla selezione tutte le prenotazioni visibili'
                                        : 'Seleziona le prenotazioni attualmente visibili',
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          prenotazioniVisibili.isEmpty ||
                                              prenotazioniSelezionateIds
                                                      .length ==
                                                  prenotazioniVisibili.length
                                          ? null
                                          : () {
                                              selezionaTutto();

                                              ripristinaFocusTabella();
                                            },
                                      icon: const Icon(
                                        Icons.select_all_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        prenotazioniVisibili.isEmpty
                                            ? 'Nessuna prenotazione'
                                            : prenotazioniSelezionateIds
                                                      .length ==
                                                  prenotazioniVisibili.length
                                            ? 'Visibili selezionate'
                                            : prenotazioniSelezionateIds
                                                  .isNotEmpty
                                            ? 'Completa selezione (${prenotazioniVisibili.length})'
                                            : 'Seleziona visibili (${prenotazioniVisibili.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFEFF6FF,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFFF1F5F9,
                                        ),
                                        disabledForegroundColor: const Color(
                                          0xFF94A3B8,
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          side: BorderSide(
                                            color:
                                                prenotazioniVisibili.isEmpty ||
                                                    prenotazioniSelezionateIds
                                                            .length ==
                                                        prenotazioniVisibili
                                                            .length
                                                ? const Color(0xFFE2E8F0)
                                                : const Color(0xFFBFDBFE),
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (prenotazioniSelezionateIds
                                      .isNotEmpty) ...[
                                    Tooltip(
                                      message:
                                          prenotazioniSelezionateIds.isEmpty
                                          ? 'Nessuna prenotazione selezionata'
                                          : prenotazioniSelezionateIds.length ==
                                                1
                                          ? 'Deseleziona la prenotazione selezionata'
                                          : 'Deseleziona ${prenotazioniSelezionateIds.length} prenotazioni selezionate',
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            prenotazioniSelezionateIds.isEmpty
                                            ? null
                                            : () {
                                                deselezionaTutto();

                                                ripristinaFocusTabella();
                                              },
                                        icon: const Icon(
                                          Icons.deselect_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          prenotazioniSelezionateIds.isEmpty
                                              ? 'Nessuna selezione'
                                              : 'Deseleziona (${prenotazioniSelezionateIds.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF8FAFC,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF475569,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFFE2E8F0,
                                          ),
                                          disabledForegroundColor: const Color(
                                            0xFF94A3B8,
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Tooltip(
                                      message:
                                          prenotazioniSelezionateIds.isEmpty
                                          ? 'Nessuna prenotazione selezionata'
                                          : prenotazioniSelezionateIds.length ==
                                                1
                                          ? 'Apri la prenotazione selezionata'
                                          : 'Apri ${prenotazioniSelezionateIds.length} prenotazioni selezionate',
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            prenotazioniSelezionateIds.isEmpty
                                            ? null
                                            : () async {
                                                await aggiornaStatoPrenotazioniSelezionate(
                                                  aperto: 1,
                                                  registro: 0,
                                                  conferma: 0,
                                                );

                                                if (!mounted) return;

                                                setState(() {
                                                  azzeraSelezionePrenotazioni();
                                                });

                                                ripristinaFocusTabella();
                                              },
                                        icon: const Icon(
                                          Icons.lock_open_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          prenotazioniSelezionateIds.isEmpty
                                              ? 'Apri selezionate'
                                              : 'Apri ${suffissoSelezionatePrenotazioni()} (${prenotazioniSelezionateIds.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFEFF6FF,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFFE2E8F0,
                                          ),
                                          disabledForegroundColor: const Color(
                                            0xFF94A3B8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFBFDBFE),
                                              width: 1.2,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),

                                    Tooltip(
                                      message:
                                          prenotazioniSelezionateIds.isEmpty
                                          ? 'Nessuna prenotazione selezionata'
                                          : prenotazioniSelezionateIds.length ==
                                                1
                                          ? 'Segna come registro la prenotazione selezionata'
                                          : 'Segna come registro ${prenotazioniSelezionateIds.length} prenotazioni selezionate',
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            prenotazioniSelezionateIds.isEmpty
                                            ? null
                                            : () async {
                                                await registroSelezionate();

                                                if (!mounted) return;

                                                setState(() {
                                                  azzeraSelezionePrenotazioni();
                                                });

                                                ripristinaFocusTabella();
                                              },
                                        icon: const Icon(
                                          Icons.fact_check_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          prenotazioniSelezionateIds.isEmpty
                                              ? 'Nessuna selezione'
                                              : 'Segna registro ${suffissoSelezionatePrenotazioni()} (${prenotazioniSelezionateIds.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF5F3FF,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF7C3AED,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFFE2E8F0,
                                          ),
                                          disabledForegroundColor: const Color(
                                            0xFF94A3B8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xDDD8B4FE),
                                              width: 1.2,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),

                                    Tooltip(
                                      message:
                                          prenotazioniSelezionateIds.isEmpty
                                          ? 'Nessuna prenotazione selezionata'
                                          : prenotazioniSelezionateIds.length ==
                                                1
                                          ? 'Stampa la prenotazione selezionata'
                                          : 'Stampa ${prenotazioniSelezionateIds.length} prenotazioni selezionate',
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            prenotazioniSelezionateIds.isEmpty
                                            ? null
                                            : () async {
                                                await stampaSelezionate();

                                                if (!mounted) return;

                                                setState(() {
                                                  azzeraSelezionePrenotazioni();
                                                });

                                                ripristinaFocusTabella();
                                              },
                                        icon: const Icon(
                                          Icons.print_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          prenotazioniSelezionateIds.isEmpty
                                              ? 'Nessuna selezione'
                                              : 'Stampa ${suffissoSelezionatePrenotazioni()} (${prenotazioniSelezionateIds.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(
                                            0xFFE2E8F0,
                                          ),
                                          disabledForegroundColor: const Color(
                                            0xFF94A3B8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),
                      ] else
                        const SizedBox(height: 14),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: SingleChildScrollView(
                              controller: horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        boxShadow: headerShadowVisible
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: SizedBox(
                                        width: tableWidth,
                                        child: PrenotazioneHeaderRow(
                                          tablet: tablet,
                                          headerBuilder: headerOrdinabile,
                                          horizontalController:
                                              horizontalController,
                                          tutteSelezionate: statoCheckboxHeader,
                                          onToggleSelezionaTutte:
                                              toggleSelezionaTutteVisibili,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 0),

                                    Expanded(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                            top: BorderSide(
                                              color: Color(0xFFE5E7EB),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: RawKeyboardListener(
                                          focusNode: tableFocusNode,
                                          autofocus: true,
                                          onKey: gestisciTasti,
                                          child: prenotazioniVisibili.isEmpty
                                              ? Center(
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 460,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 22,
                                                          vertical: 18,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF8FAFC,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFE2E8F0,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .search_off_rounded,
                                                          size: 26,
                                                          color: Color(
                                                            0xFF94A3B8,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Flexible(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const Text(
                                                                'Nessuna prenotazione trovata',
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color: Color(
                                                                    0xFF374151,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                ricercaController
                                                                            .text
                                                                            .trim()
                                                                            .isNotEmpty &&
                                                                        filtroLocale !=
                                                                            'tutte'
                                                                    ? 'La ricerca "${ricercaController.text.trim()}" non produce risultati nel filtro ${etichettaFiltroPrenotazioni(filtroLocale)}.'
                                                                    : ricercaController
                                                                          .text
                                                                          .trim()
                                                                          .isNotEmpty
                                                                    ? 'La ricerca "${ricercaController.text.trim()}" non produce risultati.'
                                                                    : filtroLocale !=
                                                                          'tutte'
                                                                    ? 'Non ci sono prenotazioni nel filtro ${etichettaFiltroPrenotazioni(filtroLocale)}.'
                                                                    : 'Non ci sono prenotazioni da visualizzare.',
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF64748B,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : Scrollbar(
                                                  controller: _scrollController,
                                                  thumbVisibility: true,
                                                  radius: const Radius.circular(
                                                    10,
                                                  ),
                                                  thickness: 7,
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    controller:
                                                        _scrollController,
                                                    primary: false,
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    itemExtent: 48,
                                                    itemCount:
                                                        prenotazioniVisibili
                                                            .length +
                                                        (caricamentoPaginaDb
                                                            ? 1
                                                            : 0),
                                                    itemBuilder: (context, index) {
                                                      if (index >=
                                                          prenotazioniVisibili
                                                              .length) {
                                                        return const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                18,
                                                              ),
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      }

                                                      final p =
                                                          prenotazioniVisibili[index];

                                                      return SizedBox(
                                                        width: tableWidth,
                                                        child: PrenotazioneRow(
                                                          prenotazione: p,
                                                          tablet: tablet,

                                                          horizontalController:
                                                              horizontalController,
                                                          selezionata:
                                                              prenotazioniSelezionateIds
                                                                  .contains(
                                                                    p['id']
                                                                        as int,
                                                                  ),
                                                          onSeleziona: () {
                                                            gestisciSelezioneMassiva(
                                                              index: index,
                                                              prenotazione: p,
                                                              ctrlPremuto:
                                                                  HardwareKeyboard
                                                                      .instance
                                                                      .logicalKeysPressed
                                                                      .contains(
                                                                        LogicalKeyboardKey
                                                                            .controlLeft,
                                                                      ) ||
                                                                  HardwareKeyboard
                                                                      .instance
                                                                      .logicalKeysPressed
                                                                      .contains(
                                                                        LogicalKeyboardKey
                                                                            .controlRight,
                                                                      ),
                                                              shiftPremuto:
                                                                  HardwareKeyboard
                                                                      .instance
                                                                      .logicalKeysPressed
                                                                      .contains(
                                                                        LogicalKeyboardKey
                                                                            .shiftLeft,
                                                                      ) ||
                                                                  HardwareKeyboard
                                                                      .instance
                                                                      .logicalKeysPressed
                                                                      .contains(
                                                                        LogicalKeyboardKey
                                                                            .shiftRight,
                                                                      ),
                                                            );

                                                            tableFocusNode
                                                                .requestFocus();
                                                          },
                                                          onDoppioClick: () {
                                                            modificaPrenotazione(
                                                              p,
                                                            );
                                                          },
                                                          onTastoDestro: (details) async {
                                                            final result = await showMenu<String>(
                                                              context: context,
                                                              position: RelativeRect.fromLTRB(
                                                                details
                                                                    .globalPosition
                                                                    .dx,
                                                                details
                                                                    .globalPosition
                                                                    .dy,
                                                                details
                                                                    .globalPosition
                                                                    .dx,
                                                                details
                                                                    .globalPosition
                                                                    .dy,
                                                              ),
                                                              items: const [
                                                                PopupMenuItem(
                                                                  value:
                                                                      'modifica',
                                                                  child: Row(
                                                                    children: const [
                                                                      Icon(
                                                                        Icons
                                                                            .edit_rounded,
                                                                        size:
                                                                            18,
                                                                        color: Color(
                                                                          0xFF0F172A,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Modifica prenotazione',
                                                                        style: TextStyle(
                                                                          color: Color(
                                                                            0xFF0F172A,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  value: 'apri',
                                                                  child: Row(
                                                                    children: const [
                                                                      Icon(
                                                                        Icons
                                                                            .lock_open_rounded,
                                                                        size:
                                                                            18,
                                                                        color: Color(
                                                                          0xFF2563EB,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Apri prenotazione',
                                                                        style: TextStyle(
                                                                          color: Color(
                                                                            0xFF2563EB,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  value:
                                                                      'chiudi',
                                                                  child: Row(
                                                                    children: const [
                                                                      Icon(
                                                                        Icons
                                                                            .lock_rounded,
                                                                        size:
                                                                            18,
                                                                        color: Color(
                                                                          0xFF4B5563,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Chiudi prenotazione',
                                                                        style: TextStyle(
                                                                          color: Color(
                                                                            0xFF4B5563,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  value:
                                                                      'registro',
                                                                  child: Row(
                                                                    children: const [
                                                                      Icon(
                                                                        Icons
                                                                            .fact_check_rounded,
                                                                        size:
                                                                            18,
                                                                        color: Color(
                                                                          0xFF7C3AED,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Segna registro',
                                                                        style: TextStyle(
                                                                          color: Color(
                                                                            0xFF7C3AED,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                PopupMenuItem(
                                                                  value:
                                                                      'elimina',
                                                                  child: Row(
                                                                    children: const [
                                                                      Icon(
                                                                        Icons
                                                                            .delete_outline_rounded,
                                                                        size:
                                                                            18,
                                                                        color: Color(
                                                                          0xFFDC2626,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Elimina prenotazione',
                                                                        style: TextStyle(
                                                                          color: Color(
                                                                            0xFFDC2626,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            );

                                                            if (result == null)
                                                              return;

                                                            if (result ==
                                                                'modifica') {
                                                              modificaPrenotazione(
                                                                p,
                                                              );
                                                            }

                                                            if (result ==
                                                                'apri') {
                                                              prenotazioniSelezionateIds =
                                                                  {
                                                                    p['id']
                                                                        as int,
                                                                  };
                                                              await aggiornaStatoPrenotazioniSelezionate(
                                                                aperto: 1,
                                                                registro: 0,
                                                                conferma: 0,
                                                              );
                                                            }

                                                            if (result ==
                                                                'chiudi') {
                                                              prenotazioniSelezionateIds =
                                                                  {
                                                                    p['id']
                                                                        as int,
                                                                  };
                                                              await aggiornaStatoPrenotazioniSelezionate(
                                                                aperto: 0,
                                                                registro: 0,
                                                                conferma: 1,
                                                              );
                                                            }

                                                            if (result ==
                                                                'registro') {
                                                              prenotazioniSelezionateIds =
                                                                  {
                                                                    p['id']
                                                                        as int,
                                                                  };
                                                              await aggiornaStatoPrenotazioniSelezionate(
                                                                aperto: 0,
                                                                registro: 1,
                                                                conferma: 0,
                                                              );
                                                            }

                                                            if (result ==
                                                                'elimina') {
                                                              eliminaPrenotazione(
                                                                p,
                                                              );
                                                            }
                                                          },
                                                          onModifica: () =>
                                                              modificaPrenotazione(
                                                                p,
                                                              ),

                                                          onElimina: () =>
                                                              eliminaPrenotazione(
                                                                p,
                                                              ),
                                                          statoPrenotazione:
                                                              statoPrenotazione,
                                                          nomeDiscente:
                                                              nomeDiscente,
                                                          testo: testo,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

const double colDiscente = 240;
const double colImpresa = 180;
const double colCorso = 320;
const double colData = 110;
const double colProt = 80;
const double colStato = 110;
const double colAzioni = 90;

class PrenotazioneRow extends StatefulWidget {
  final Map<String, dynamic> prenotazione;
  final bool tablet;
  final ScrollController horizontalController;

  final bool selezionata;
  final VoidCallback onSeleziona;

  final VoidCallback onModifica;
  final VoidCallback onElimina;
  final VoidCallback onDoppioClick;
  final void Function(TapDownDetails details) onTastoDestro;

  final String Function(Map<String, dynamic>) statoPrenotazione;
  final String Function(Map<String, dynamic>) nomeDiscente;
  final String Function(dynamic) testo;

  const PrenotazioneRow({
    super.key,
    required this.prenotazione,
    required this.tablet,
    required this.horizontalController,
    required this.selezionata,
    required this.onSeleziona,
    required this.onModifica,
    required this.onElimina,
    required this.statoPrenotazione,
    required this.nomeDiscente,
    required this.testo,
    required this.onDoppioClick,
    required this.onTastoDestro,
  });

  @override
  State<PrenotazioneRow> createState() => _PrenotazioneRowState();
}

class _PrenotazioneRowState extends State<PrenotazioneRow> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final stato = widget.statoPrenotazione(widget.prenotazione);

    Color? rowColor;

    if (widget.selezionata) {
      rowColor = const Color(0xFFDBEAFE);
    } else if (hover) {
      rowColor = const Color(0xFFEFF6FF);
    } else if (stato == 'Chiuso') {
      rowColor = Colors.grey.shade100;
    } else if (stato == 'Registro') {
      rowColor = Colors.orange.shade50;
    } else if (stato == 'Aperto') {
      rowColor = Colors.green.shade50;
    }

    final effectiveColor = widget.selezionata
        ? const Color(0xFFDBEAFE)
        : hover
        ? const Color(0xFFF8FBFF)
        : rowColor;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSeleziona,
          onDoubleTap: widget.onDoppioClick,
          onSecondaryTapDown: widget.onTastoDestro,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            decoration: BoxDecoration(
              color: effectiveColor,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: widget.tablet ? 10 : 16),
            child: AnimatedBuilder(
              animation: widget.horizontalController,
              builder: (context, child) {
                final offset = widget.horizontalController.hasClients
                    ? widget.horizontalController.offset
                    : 0.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: colDiscente),

                        SizedBox(
                          width: colImpresa,
                          child: Text(
                            widget.testo(widget.prenotazione['impresa_nome']),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colCorso,
                          child: Text(
                            widget.testo(widget.prenotazione['corso_nome']),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colData,
                          child: Text(
                            widget.testo(widget.prenotazione['data']),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colProt,
                          child: Text(
                            widget.testo(widget.prenotazione['prot']),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colStato,
                          child: TableStatusBadge(status: stato),
                        ),

                        SizedBox(
                          width: colAzioni,
                          child: Wrap(
                            spacing: 0,
                            alignment: WrapAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Modifica prenotazione',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: widget.onModifica,
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                              ),

                              IconButton(
                                tooltip: 'Elimina prenotazione',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: widget.onElimina,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Positioned(
                      left: offset,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: colDiscente,
                        color: effectiveColor ?? Colors.white,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 2, right: 14),
                        child: Text(
                          widget.nomeDiscente(widget.prenotazione),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: widget.selezionata
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: offset + colDiscente - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        color: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PrenotazioneHeaderRow extends StatelessWidget {
  final bool tablet;
  final ScrollController horizontalController;

  final bool? tutteSelezionate;
  final VoidCallback onToggleSelezionaTutte;

  final Widget Function(String titolo, double larghezza, String colonna)
  headerBuilder;

  const PrenotazioneHeaderRow({
    super.key,
    required this.tablet,
    required this.headerBuilder,
    required this.horizontalController,
    required this.tutteSelezionate,
    required this.onToggleSelezionaTutte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: tablet ? 10 : 16),
      child: AnimatedBuilder(
        animation: horizontalController,
        builder: (context, child) {
          final offset = horizontalController.hasClients
              ? horizontalController.offset
              : 0.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  const SizedBox(width: colDiscente),
                  headerBuilder('Impresa', colImpresa, 'impresa'),
                  headerBuilder('Corso', colCorso, 'corso'),
                  headerBuilder('Data', colData, 'data'),
                  headerBuilder('Prot.', colProt, 'prot'),
                  headerBuilder('Stato', colStato, 'stato'),

                  SizedBox(
                    width: colAzioni,
                    child: const Text(
                      'Azioni',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              Positioned(
                left: offset,
                top: 0,
                bottom: 0,
                child: Container(
                  width: colDiscente,
                  color: const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: Transform.scale(
                            scale: 0.78,
                            child: Checkbox(
                              value: tutteSelezionate,
                              tristate: true,
                              onChanged: (_) => onToggleSelezionaTutte(),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: headerBuilder(
                          'Discente',
                          colDiscente - 36,
                          'discente',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: offset + colDiscente - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: const Color(0xFFD1D5DB)),
              ),
            ],
          );
        },
      ),
    );
  }
}
