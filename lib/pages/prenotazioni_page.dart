import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/prenotazione_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/table_status_badge.dart';
import '../widgets/app_action_button.dart';

import '../services/app_database.dart';

import '../utils/pdf_azienda_helper.dart';

import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/registro_presenza.dart';

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
  bool mostraTutteLePrenotazioni = false;
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

  late String filtroLocale;

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

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    String testo(dynamic valore) {
      if (valore == null) return '';
      return valore.toString();
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
            intestazioneAziendaPdfWidget(intestazioneAzienda),
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

            pw.TableHelper.fromTextArray(
              headers: const [
                'Discente',
                'Impresa',
                'Corso',
                'Attrezzature',
                'Data',
                'Prot.',
                'Stato',
              ],
              data: prenotazioniDaStampare.map((p) {
                final discenteCompleto = [
                  testo(p['discente_cognome']),
                  testo(p['discente_nome']),
                ].where((v) => v.trim().isNotEmpty).join(' ');

                return [
                  discenteCompleto,
                  testo(p['impresa_nome']),
                  testo(p['corso_nome']),
                  testo(p['attrezzature_sintesi']),
                  dataItaliana(p['data']),
                  testo(p['prot']),
                  statoPrenotazione(p),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.blueGrey900,
              ),
              headerPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey100,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(1.3),
                2: pw.FlexColumnWidth(2.0),
                3: pw.FlexColumnWidth(2.8),
                4: pw.FlexColumnWidth(0.9),
                5: pw.FlexColumnWidth(0.7),
                6: pw.FlexColumnWidth(1.0),
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

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          prenotazioniDaStampare.length == 1
              ? 'PDF creato per 1 prenotazione selezionata.'
              : 'PDF creato per ${prenotazioniDaStampare.length} prenotazioni selezionate.',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );

    if (!mounted) return;

    setState(() {
      azzeraSelezionePrenotazioni();
    });

    ripristinaFocusTabella();
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
      final docente = testoDocentePrenotazione(p).toLowerCase();
      final aulaSede = testoAulaSedePrenotazione(p).toLowerCase();
      final enteAttestato = testoEnteAttestatoPrenotazione(p).toLowerCase();
      final data = testo(p['data']).toLowerCase();
      final prot = testo(p['prot']).toLowerCase();

      return discente.contains(query) ||
          impresa.contains(query) ||
          corso.contains(query) ||
          docente.contains(query) ||
          aulaSede.contains(query) ||
          enteAttestato.contains(query) ||
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

      if (conferma == 1) {
        await DatabaseService.instance.confermaPrenotazioneWorkflow(id);
      } else {
        await DatabaseService.instance.annullaConfermaPrenotazioneWorkflow(id);
      }
    }

    if (!mounted) return;

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
      mostraTutteLePrenotazioni = false;

      prenotazioni.clear();
      prenotazioniFiltrate.clear();
    });

    try {
      final dati = await DatabaseService.instance.getPrenotazioniPaged(
        limit: righePerPaginaDb,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        prenotazioni = dati;
        prenotazioniFiltrate = dati;

        paginaDbCorrente = 1;

        if (dati.length < righePerPaginaDb) {
          fineArchivioPrenotazioni = true;
          mostraTutteLePrenotazioni = true;
        }
      });
    } catch (e) {
      debugPrint('ERRORE caricaPrenotazioniIniziali: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          caricamentoPaginaDb = false;
        });
      }
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

    filtroLocale = widget.filtro;

    ricercaController.text = widget.globalSearch;
    ricercaController.selection = TextSelection.collapsed(
      offset: ricercaController.text.length,
    );

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
    ricercaController.dispose();
    ricercaFocusNode.dispose();
    tableFocusNode.dispose();
    _scrollController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  void gestisciTasti(KeyEvent event) async {
    if (event is! KeyDownEvent) return;

    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      ricercaFocusNode.requestFocus();

      ricercaController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: ricercaController.text.length,
      );

      return;
    }

    // CTRL + A
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyA) {
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
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyN) {
      apriDialogNuovaPrenotazione();
      return;
    }

    // CTRL + E
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyE) {
      exportPrenotazioniExcel();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        azzeraSelezionePrenotazioni();
      });

      ripristinaFocusTabella();
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

      if (nuovoConferma == 1) {
        await DatabaseService.instance.confermaPrenotazioneWorkflow(id);
      } else {
        await DatabaseService.instance.annullaConfermaPrenotazioneWorkflow(id);
      }

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

    try {
      final dati = await DatabaseService.instance.getPrenotazioniPaged(
        limit: righePerPaginaDb,
        offset: paginaDbCorrente * righePerPaginaDb,
      );

      if (!mounted) return;

      setState(() {
        prenotazioni.addAll(dati);
        prenotazioniFiltrate = List<Map<String, dynamic>>.from(prenotazioni);

        paginaDbCorrente++;

        if (dati.length < righePerPaginaDb) {
          fineArchivioPrenotazioni = true;
        }
      });
    } catch (e) {
      debugPrint('Errore caricamento altre prenotazioni: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore caricamento altre prenotazioni: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          caricamentoPaginaDb = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant PrenotazioniPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.globalSearch != widget.globalSearch ||
        oldWidget.filtro != widget.filtro) {
      ricercaController.text = widget.globalSearch;
      ricercaController.selection = TextSelection.collapsed(
        offset: ricercaController.text.length,
      );

      setState(() {
        filtroLocale = widget.filtro;
        azzeraSelezionePrenotazioni();
      });

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

  String testoDocentePrenotazione(Map<String, dynamic> prenotazione) {
    final cognome = prenotazione['docente_cognome']?.toString().trim() ?? '';
    final nome = prenotazione['docente_nome']?.toString().trim() ?? '';

    final completo = '$cognome $nome'.trim();
    if (completo.isEmpty) return '-';

    return completo;
  }

  String testoAulaSedePrenotazione(Map<String, dynamic> prenotazione) {
    final denominazione =
        prenotazione['aula_sede_denominazione']?.toString().trim() ?? '';
    final comune = prenotazione['aula_sede_comune']?.toString().trim() ?? '';

    if (denominazione.isEmpty && comune.isEmpty) return '-';
    if (comune.isEmpty) return denominazione;
    if (denominazione.isEmpty) return comune;

    return '$denominazione - $comune';
  }

  String testoEnteAttestatoPrenotazione(Map<String, dynamic> prenotazione) {
    final denominazione =
        prenotazione['ente_attestato_denominazione']?.toString().trim() ?? '';

    if (denominazione.isEmpty) return '-';

    return denominazione;
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
      'docente_id': dati['docente_id'],
      'aula_sede_id': dati['aula_sede_id'],
      'ente_attestato_id': dati['ente_attestato_id'],
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
      caricamentoPaginaDb = false;
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

      final datiConAttrezzature = <Map<String, dynamic>>[];

      for (final prenotazione in dati) {
        final prenotazioneArricchita = Map<String, dynamic>.from(prenotazione);
        final prenotazioneIdRaw = prenotazioneArricchita['id'];
        final prenotazioneId = prenotazioneIdRaw is int
            ? prenotazioneIdRaw
            : int.tryParse(prenotazioneIdRaw.toString());

        if (prenotazioneId != null) {
          prenotazioneArricchita['attrezzature_sintesi'] = await AppDatabase
              .instance
              .getSintesiAttrezzaturePrenotazione(prenotazioneId);
        } else {
          prenotazioneArricchita['attrezzature_sintesi'] = '';
        }

        datiConAttrezzature.add(prenotazioneArricchita);
      }

      if (!mounted) return;

      setState(() {
        if (reset) {
          prenotazioni.clear();
        }

        prenotazioni.addAll(datiConAttrezzature);
        prenotazioniFiltrate = List.from(prenotazioni);

        paginaDbCorrente++;

        if (datiConAttrezzature.length < righePerPaginaDb) {
          fineArchivioPrenotazioni = true;
          mostraTutteLePrenotazioni = true;
        }

        caricamentoPaginaDb = false;
        loading = false;
      });

      if (widget.globalSearch.trim().isNotEmpty) {
        cercaPrenotazioni(widget.globalSearch);
      }
    } catch (e) {
      debugPrint('Errore caricamento prenotazioni paged: $e');

      if (!mounted) return;

      setState(() {
        caricamentoPaginaDb = false;
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore caricamento prenotazioni: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> caricaTutteLePrenotazioni() async {
    if (caricamentoPaginaDb) return;

    setState(() {
      caricamentoPaginaDb = true;
    });

    try {
      final tutteLePrenotazioni = <Map<String, dynamic>>[];
      int offset = 0;

      while (true) {
        final dati = await DatabaseService.instance.getPrenotazioniPaged(
          limit: righePerPaginaDb,
          offset: offset,
        );

        tutteLePrenotazioni.addAll(dati);

        if (dati.length < righePerPaginaDb) {
          break;
        }

        offset += righePerPaginaDb;
      }

      if (!mounted) return;

      setState(() {
        prenotazioni = List<Map<String, dynamic>>.from(tutteLePrenotazioni);

        prenotazioniFiltrate = List<Map<String, dynamic>>.from(prenotazioni);

        mostraTutteLePrenotazioni = true;
        paginaDbCorrente = (tutteLePrenotazioni.length / righePerPaginaDb)
            .ceil();
        fineArchivioPrenotazioni = true;

        caricamentoPaginaDb = false;
        loading = false;
      });

      final ricercaCorrente = ricercaController.text.trim();

      if (ricercaCorrente.isNotEmpty) {
        cercaPrenotazioni(ricercaCorrente);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tutteLePrenotazioni.length == 1
                ? 'Archivio completo: 1 prenotazione visualizzata'
                : 'Archivio completo: ${tutteLePrenotazioni.length} prenotazioni visualizzate',
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Errore caricamento completo prenotazioni: $e');

      if (!mounted) return;

      setState(() {
        caricamentoPaginaDb = false;
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore caricamento completo prenotazioni: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
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
        final docente = testoDocentePrenotazione(p).toLowerCase();
        final aulaSede = testoAulaSedePrenotazione(p).toLowerCase();
        final enteAttestato = testoEnteAttestatoPrenotazione(p).toLowerCase();

        return discente.contains(query) ||
            impresa.contains(query) ||
            corso.contains(query) ||
            docente.contains(query) ||
            aulaSede.contains(query) ||
            enteAttestato.contains(query) ||
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

      await AppDatabase.instance.salvaAttrezzaturePrenotazione(
        prenotazioneId: nuovoId,
        attrezzature: List<Map<String, dynamic>>.from(
          nuovaPrenotazione['attrezzature'] ?? [],
        ),
        attrezzatureIds: List<int>.from(
          nuovaPrenotazione['attrezzature_ids'] ?? [],
        ),
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

      await AppDatabase.instance.salvaAttrezzaturePrenotazione(
        prenotazioneId: prenotazione['id'] as int,
        attrezzature: List<Map<String, dynamic>>.from(
          prenotazioneModificata['attrezzature'] ?? [],
        ),
        attrezzatureIds: List<int>.from(
          prenotazioneModificata['attrezzature_ids'] ?? [],
        ),
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
            color: attivo ? colore.withValues(alpha: 0.12) : Colors.white,
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
                color: Colors.black.withValues(alpha: 0.04),
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

  Future<void> apriDialogRegistroPresenze(
    Map<String, dynamic> prenotazione,
  ) async {
    final prenotazioneId = prenotazione['id'] as int?;

    if (prenotazioneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID prenotazione mancante.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    try {
      var registri = await AppDatabase.instance.getRegistriPresenze(
        prenotazioneId: prenotazioneId,
      );

      RegistroPresenza registro;

      if (registri.isEmpty) {
        final nuovoRegistro = RegistroPresenza(
          prenotazioneId: prenotazioneId,
          discenteId: prenotazione['discente_id'] as int?,
          dataLezione: testo(prenotazione['data']),
          presente: true,
        );

        final nuovoId = await AppDatabase.instance.inserisciRegistroPresenza(
          nuovoRegistro,
        );

        registro = nuovoRegistro.copyWith(id: nuovoId);
      } else {
        registro = registri.first;
      }

      if (!mounted) return;

      bool presente = registro.presente;

      final oraInizioController = TextEditingController(
        text: registro.oraInizio ?? '',
      );
      final oraFineController = TextEditingController(
        text: registro.oraFine ?? '',
      );
      final noteController = TextEditingController(text: registro.note ?? '');

      String? normalizzaOrario(String valore) {
        final testo = valore.trim().replaceAll('.', ':');

        if (testo.isEmpty) {
          return '';
        }

        final match = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(testo);
        if (match == null) {
          return null;
        }

        final ore = int.tryParse(match.group(1)!);
        final minuti = int.tryParse(match.group(2)!);

        if (ore == null || minuti == null) {
          return null;
        }

        if (ore < 0 || ore > 23 || minuti < 0 || minuti > 59) {
          return null;
        }

        return '${ore.toString().padLeft(2, '0')}:${minuti.toString().padLeft(2, '0')}';
      }

      int minutiDaOrario(String orario) {
        final parti = orario.split(':');
        return int.parse(parti[0]) * 60 + int.parse(parti[1]);
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Registro presenze'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeDiscente(prenotazione),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(testo(prenotazione['corso_nome'])),
                    const SizedBox(height: 6),
                    Text('Data: ${testo(prenotazione['data'])}'),
                    const SizedBox(height: 18),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: presente,
                      title: const Text('Presente'),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          presente = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: oraInizioController,
                            decoration: const InputDecoration(
                              labelText: 'Ora inizio',
                              hintText: 'es. 09:00',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: oraFineController,
                            decoration: const InputDecoration(
                              labelText: 'Ora fine',
                              hintText: 'es. 13:00',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Eventuali note sul registro presenze',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      final oraInizioNormalizzata = normalizzaOrario(
                        oraInizioController.text,
                      );
                      final oraFineNormalizzata = normalizzaOrario(
                        oraFineController.text,
                      );

                      if (oraInizioNormalizzata == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Formato ora inizio non valido. Usa HH:mm, ad esempio 08:30.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (oraFineNormalizzata == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Formato ora fine non valido. Usa HH:mm, ad esempio 12:30.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (oraInizioNormalizzata.isNotEmpty &&
                          oraFineNormalizzata.isNotEmpty &&
                          minutiDaOrario(oraFineNormalizzata) <=
                              minutiDaOrario(oraInizioNormalizzata)) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ora fine deve essere successiva a Ora inizio.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      final registroAggiornato = registro.copyWith(
                        presente: presente,
                        oraInizio: oraInizioNormalizzata,
                        oraFine: oraFineNormalizzata,
                        note: noteController.text.trim(),
                      );

                      await AppDatabase.instance.aggiornaRegistroPresenza(
                        registroAggiornato,
                      );

                      if (!context.mounted) return;
                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Registro presenze aggiornato.'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Salva'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore registro presenze: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> stampaRegistroPresenze(Map<String, dynamic> prenotazione) async {
    try {
      final prenotazioneIdRaw = prenotazione['id'];
      final prenotazioneId = prenotazioneIdRaw is int
          ? prenotazioneIdRaw
          : int.tryParse(prenotazioneIdRaw?.toString() ?? '');

      if (prenotazioneId == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossibile stampare il registro: ID prenotazione non valido.',
            ),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      final registri = await AppDatabase.instance.getRegistriPresenze(
        prenotazioneId: prenotazioneId,
      );

      String campoPrenotazione(List<String> chiavi) {
        for (final chiave in chiavi) {
          final valore = prenotazione[chiave];
          if (valore != null && valore.toString().trim().isNotEmpty) {
            return valore.toString().trim();
          }
        }
        return '-';
      }

      final dataCorso = campoPrenotazione([
        'data_corso',
        'data',
        'data_inizio',
      ]);

      final protocollo = campoPrenotazione([
        'protocollo',
        'prot',
        'numero_protocollo',
      ]);

      final nomeDiscente = campoPrenotazione([
        'discente',
        'nome_discente',
        'discente_nome',
        'nominativo_discente',
        'nome_completo',
      ]);

      final nomeImpresa = campoPrenotazione([
        'impresa',
        'impresa_nome',
        'nome_impresa',
        'ragione_sociale',
        'azienda',
        'azienda_nome',
        'intestazione',
        'intestazione_impresa',
      ]);

      final nomeCorso = campoPrenotazione([
        'corso',
        'corso_nome',
        'nome_corso',
        'denominazione_corso',
        'titolo_corso',
        'denominazione',
        'corso_denominazione',
      ]);

      final statoPrenotazione = campoPrenotazione([
        'stato',
        'stato_prenotazione',
      ]);

      final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              intestazioneAziendaPdfWidget(intestazioneAzienda),
              pw.SizedBox(height: 16),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'REGISTRO PRESENZE',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),

              pw.SizedBox(height: 14),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Dati corso / prenotazione',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _rigaInfoPdf('Discente', nomeDiscente),
                              _rigaInfoPdf('Impresa', nomeImpresa),
                              _rigaInfoPdf('Corso', nomeCorso),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _rigaInfoPdf('Data corso', dataCorso),
                              _rigaInfoPdf('Protocollo', protocollo),
                              _rigaInfoPdf('Stato', statoPrenotazione),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              pw.Text(
                'Presenze registrate',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: const [
                  'Data',
                  'Ora inizio',
                  'Ora fine',
                  'Presenza',
                  'Note',
                ],
                data: registri.map((registro) {
                  return [
                    registro.dataLezione,
                    _normalizzaOraPdf(registro.oraInizio),
                    _normalizzaOraPdf(registro.oraFine),
                    registro.presente ? 'Presente' : 'Assente',
                    registro.note?.isNotEmpty == true ? registro.note! : '-',
                  ];
                }).toList(),
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(70),
                  1: const pw.FixedColumnWidth(65),
                  2: const pw.FixedColumnWidth(65),
                  3: const pw.FixedColumnWidth(70),
                  4: const pw.FlexColumnWidth(),
                },
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
              ),

              pw.SizedBox(height: 28),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Firme',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 24),

                    pw.Row(
                      children: [
                        pw.Expanded(child: _boxFirmaPdf('Firma discente')),
                        pw.SizedBox(width: 24),
                        pw.Expanded(child: _boxFirmaPdf('Firma docente')),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'Il presente registro attesta la partecipazione del discente alla lezione indicata, secondo i dati registrati nel gestionale.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ];
          },
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Pagina ${context.pageNumber} di ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore stampa registro presenze: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> generaDichiarazioneCorso() async {
    final prenotazioniSelezionate = prenotazioniVisibili
        .where((p) => prenotazioniSelezionateIds.contains(p['id']))
        .toList();

    if (prenotazioniSelezionate.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleziona almeno una prenotazione per generare la dichiarazione corso.',
          ),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 4),
        ),
      );

      ripristinaFocusTabella();
      return;
    }

    String campoPrenotazione(
      Map<String, dynamic> prenotazione,
      List<String> chiavi,
    ) {
      for (final chiave in chiavi) {
        final valore = prenotazione[chiave];

        if (valore != null && valore.toString().trim().isNotEmpty) {
          return valore.toString().trim();
        }
      }

      return '';
    }

    final protocolli = prenotazioniSelezionate
        .map(
          (p) =>
              campoPrenotazione(p, ['prot', 'protocollo', 'numero_protocollo']),
        )
        .where((protocollo) => protocollo.isNotEmpty)
        .toSet();

    if (protocolli.length != 1) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Per generare la dichiarazione corso seleziona prenotazioni dello stesso protocollo.',
          ),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 5),
        ),
      );

      ripristinaFocusTabella();
      return;
    }

    final protocollo = protocolli.first;

    final Map<String, List<Map<String, dynamic>>> gruppiPerImpresa = {};

    for (final prenotazione in prenotazioniSelezionate) {
      final impresa = campoPrenotazione(prenotazione, [
        'impresa_nome',
        'impresa',
        'nome_impresa',
        'ragione_sociale',
        'azienda',
        'azienda_nome',
        'intestazione',
        'intestazione_impresa',
      ]);

      final chiaveImpresa = impresa.isEmpty ? 'Impresa non indicata' : impresa;

      gruppiPerImpresa.putIfAbsent(chiaveImpresa, () => []);
      gruppiPerImpresa[chiaveImpresa]!.add(prenotazione);
    }

    try {
      final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

      final List<File> fileCreati = [];

      for (final gruppo in gruppiPerImpresa.entries) {
        final nomeImpresa = gruppo.key;
        final corsisti = gruppo.value;
        final primaPrenotazione = corsisti.first;

        final nomeCorso = campoPrenotazione(primaPrenotazione, [
          'corso_nome',
          'corso',
          'nome_corso',
          'denominazione_corso',
          'titolo_corso',
          'denominazione',
          'corso_denominazione',
        ]);

        final dataCorso = campoPrenotazione(primaPrenotazione, [
          'data',
          'data_corso',
          'data_inizio',
        ]);

        final docente = campoPrenotazione(primaPrenotazione, [
          'docente_nome',
          'docente',
          'nome_docente',
        ]);

        final aulaSede = campoPrenotazione(primaPrenotazione, [
          'aula_sede_nome',
          'aula_sede',
          'aula',
          'sede',
        ]);

        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
            footer: (context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  'Pagina ${context.pageNumber} di ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              );
            },
            build: (context) {
              return [
                intestazioneAziendaPdfWidget(intestazioneAzienda),

                pw.SizedBox(height: 22),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                    border: pw.Border.all(color: PdfColors.blueGrey200),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'DICHIARAZIONE DI PARTECIPAZIONE AL CORSO',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),

                pw.SizedBox(height: 24),

                pw.Text('Spett.le', style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text(
                  nomeImpresa,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 24),

                pw.Text(
                  'La società F&P S.r.l.s. Formazione e Privacy, in qualità di soggetto formatore, dichiara che i lavoratori sotto indicati hanno partecipato al corso di formazione riportato nella presente dichiarazione.',
                  textAlign: pw.TextAlign.justify,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                ),

                pw.SizedBox(height: 10),

                pw.Text(
                  'La presente dichiarazione viene rilasciata su richiesta dell\'azienda e attesta esclusivamente la partecipazione dei discenti al corso indicato, in attesa dell\'emissione degli eventuali attestati previsti.',
                  textAlign: pw.TextAlign.left,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                ),

                pw.SizedBox(height: 16),

                pw.Text(
                  nomeCorso.isEmpty ? '-' : nomeCorso,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 16),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Dati del corso',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _rigaInfoPdf(
                        'Corso',
                        nomeCorso.isEmpty ? '-' : nomeCorso,
                      ),
                      _rigaInfoPdf(
                        'Protocollo',
                        protocollo.isEmpty ? '-' : protocollo,
                      ),
                      _rigaInfoPdf(
                        'Data corso',
                        dataCorso.isEmpty ? '-' : dataCorso,
                      ),
                      _rigaInfoPdf('Docente', docente.isEmpty ? '-' : docente),
                      _rigaInfoPdf(
                        'Aula/Sede',
                        aulaSede.isEmpty ? '-' : aulaSede,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Corsisti partecipanti',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.TableHelper.fromTextArray(
                  headers: const ['N.', 'Cognome e nome', 'Codice fiscale'],
                  data: List.generate(corsisti.length, (index) {
                    final prenotazione = corsisti[index];

                    final codiceFiscale = campoPrenotazione(prenotazione, [
                      'codice_fiscale',
                      'cf',
                      'codiceFiscale',
                    ]);

                    return [
                      '${index + 1}',
                      nomeDiscente(prenotazione),
                      codiceFiscale.isEmpty ? '-' : codiceFiscale,
                    ];
                  }),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FixedColumnWidth(32),
                    1: const pw.FlexColumnWidth(2.2),
                    2: const pw.FlexColumnWidth(1.6),
                  },
                  cellPadding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 5,
                  ),
                ),

                pw.SizedBox(height: 18),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'La presente dichiarazione non sostituisce l\'attestato di formazione, ove previsto, ma documenta la partecipazione dei corsisti sopra indicati al corso riportato nella presente comunicazione.',
                    textAlign: pw.TextAlign.left,
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
                  ),
                ),

                pw.SizedBox(height: 24),

                pw.Text(
                  "La presente dichiarazione viene rilasciata su richiesta dell'impresa interessata per gli usi consentiti dalla legge.",
                  style: const pw.TextStyle(fontSize: 11),
                ),

                pw.SizedBox(height: 36),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Luogo e data',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 18),
                        pw.Container(
                          width: 180,
                          height: 1,
                          color: PdfColors.grey700,
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          intestazioneAzienda.titolo,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 28),
                        pw.Container(
                          width: 180,
                          height: 1,
                          color: PdfColors.grey700,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Timbro e firma',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ];
            },
          ),
        );

        final cartellaDichiarazioni = await _cartellaDichiarazioniCorso();

        final nomeFile = _nomeFileDichiarazioneCorso(
          corso: nomeCorso,
          protocollo: protocollo,
          impresa: nomeImpresa,
        );

        final file = File(
          '${cartellaDichiarazioni.path}${Platform.pathSeparator}$nomeFile',
        );

        await file.writeAsBytes(await pdf.save());

        fileCreati.add(file);
      }

      for (final file in fileCreati) {
        await OpenFile.open(file.path);
      }

      if (!mounted) return;

      final messaggio = fileCreati.length == 1
          ? 'Dichiarazione corso creata per 1 impresa.'
          : 'Dichiarazioni corso create per ${fileCreati.length} imprese.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messaggio),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 5),
        ),
      );

      ripristinaFocusTabella();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore generazione dichiarazione corso: $e'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 5),
        ),
      );

      ripristinaFocusTabella();
    }
  }

  pw.Widget _rigaInfoPdf(String label, String valore) {
    final testo = valore.trim().isEmpty ? '-' : valore.trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: testo, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  String _normalizzaOraPdf(String? valore) {
    if (valore == null || valore.trim().isEmpty) {
      return '-';
    }

    final testo = valore.trim().replaceAll('.', ':');

    final parti = testo.split(':');
    if (parti.length < 2) {
      return testo;
    }

    final ora = int.tryParse(parti[0]);
    final minuti = int.tryParse(parti[1]);

    if (ora == null || minuti == null) {
      return testo;
    }

    return '${ora.toString().padLeft(2, '0')}:${minuti.toString().padLeft(2, '0')}';
  }

  pw.Widget _boxFirmaPdf(String titolo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titolo,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 28),
        pw.Container(height: 1, color: PdfColors.grey600),
      ],
    );
  }

  String _sanificaNomeFile(String valore) {
    final pulito = valore
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), '_');

    if (pulito.isEmpty) {
      return 'senza_nome';
    }

    return pulito;
  }

  Future<Directory> _cartellaDichiarazioniCorso() async {
    final directoryDocumenti = await getApplicationDocumentsDirectory();

    final cartella = Directory(
      '${directoryDocumenti.path}${Platform.pathSeparator}Gestionale Sicurezza'
      '${Platform.pathSeparator}Dichiarazioni corso',
    );

    if (!await cartella.exists()) {
      await cartella.create(recursive: true);
    }

    return cartella;
  }

  String _nomeFileDichiarazioneCorso({
    required String corso,
    required String protocollo,
    required String impresa,
  }) {
    final dataOra = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());

    final corsoPulito = _sanificaNomeFile(corso);
    final protocolloPulito = _sanificaNomeFile(protocollo);
    final impresaPulita = _sanificaNomeFile(impresa);

    return 'dichiarazione_corso_${corsoPulito}_protocollo_${protocolloPulito}_azienda_${impresaPulita}_$dataOra.pdf';
  }

  Future<void> exportPrenotazioniExcel() async {
    if (prenotazioniVisibili.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna prenotazione da esportare in Excel'),
          backgroundColor: Color(0xFFF97316),
          duration: Duration(seconds: 4),
        ),
      );

      ripristinaFocusTabella();
      return;
    }

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

      final now = DateTime.now();

      final vistaFiltrata =
          ricercaController.text.trim().isNotEmpty || filtroLocale != 'tutte';

      final totaleEsportate = prenotazioniVisibili.length;

      final dataOraExport = DateFormat('dd/MM/yyyy HH:mm').format(now);

      excel.delete('Sheet1');

      sheet.setColumnWidth(0, 52); // Discente / riga informativa export
      sheet.setColumnWidth(1, 26); // Impresa
      sheet.setColumnWidth(2, 38); // Corso
      sheet.setColumnWidth(3, 16); // Data
      sheet.setColumnWidth(4, 18); // Protocollo
      sheet.setColumnWidth(5, 16); // Stato
      sheet.setColumnWidth(6, 48); // Attrezzature

      // RIGA INFORMATIVA EXPORT

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

      sheet.appendRow([
        TextCellValue(
          vistaFiltrata
              ? 'Export prenotazioni filtrato - $totaleEsportate record - $dataOraExport'
              : 'Export prenotazioni - $totaleEsportate record - $dataOraExport',
        ),
      ]);

      sheet.appendRow([TextCellValue('')]);

      // HEADER
      sheet.appendRow([
        TextCellValue('Discente'),
        TextCellValue('Impresa'),
        TextCellValue('Corso'),
        TextCellValue('Data'),
        TextCellValue('Protocollo'),
        TextCellValue('Stato'),
        TextCellValue('Attrezzature'),
      ]);

      for (int col = 0; col < 7; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4),
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
          TextCellValue(testo(p['attrezzature_sintesi'])),
        ]);
      }

      final timestamp =
          '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}h${now.minute.toString().padLeft(2, '0')}';

      final nomeFileExcel = vistaFiltrata
          ? 'prenotazioni_export_filtrato_$timestamp.xlsx'
          : 'prenotazioni_export_$timestamp.xlsx';

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$nomeFileExcel';

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

    try {
      final now = DateTime.now();

      final vistaFiltrata =
          ricercaController.text.trim().isNotEmpty || filtroLocale != 'tutte';

      final totaleEsportate = prenotazioniVisibili.length;

      final ricercaAttiva = ricercaController.text.trim();

      final descrizioneFiltro = switch (filtroLocale) {
        'aperte' => 'Aperte',
        'registro' => 'Registro',
        'chiuse' => 'Chiuse',
        'da_fare' => 'Da fare',
        _ => '',
      };

      final dettaglioVista = ricercaAttiva.isNotEmpty && filtroLocale != 'tutte'
          ? 'Ricerca: $ricercaAttiva - Filtro: $descrizioneFiltro'
          : ricercaAttiva.isNotEmpty
          ? 'Ricerca: $ricercaAttiva'
          : filtroLocale != 'tutte'
          ? 'Filtro: $descrizioneFiltro'
          : '';

      final dataOraExport = DateFormat('dd/MM/yyyy HH:mm').format(now);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final directory = await getApplicationDocumentsDirectory();

      final pdf = pw.Document();

      final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 30),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  intestazioneAzienda.titolo,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.Text(
                  'Pagina ${context.pageNumber} di ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ],
            ),
          ),
          build: (context) => [
            intestazioneAziendaPdfWidget(intestazioneAzienda),

            pw.SizedBox(height: 4),

            pw.Text(
              'PRENOTAZIONI',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Text(
              vistaFiltrata
                  ? 'Vista filtrata - $dettaglioVista - $totaleEsportate record - $dataOraExport'
                  : 'Vista completa - $totaleEsportate record - $dataOraExport',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey700,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Divider(color: PdfColors.blue700, thickness: 1),

            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(
                color: PdfColors.blueGrey400,
                width: 0.5,
              ),
              headerCount: 1,
              headers: [
                'Discente',
                'Impresa',
                'Corso',
                'Attrezzature',
                'Data',
                'Prot.',
                'Stato',
              ],
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.1),
                2: const pw.FlexColumnWidth(2.0),
                3: const pw.FlexColumnWidth(2.6),
                4: const pw.FlexColumnWidth(0.9),
                5: const pw.FlexColumnWidth(0.7),
                6: const pw.FlexColumnWidth(0.9),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              headerAlignment: pw.Alignment.center,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey100,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey900,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              data: prenotazioniVisibili.map((p) {
                return [
                  nomeDiscente(p),
                  testo(p['impresa_nome']),
                  testo(p['corso_nome']),
                  testo(p['attrezzature_sintesi']),
                  testo(p['data']),
                  testo(p['prot']),
                  statoPrenotazione(p),
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final nomeFilePdf = vistaFiltrata
          ? 'prenotazioni_export_filtrato_$timestamp.pdf'
          : 'prenotazioni_export_$timestamp.pdf';

      final file = File('${directory.path}/$nomeFilePdf');

      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(file.path);

      if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la creazione o l’apertura del PDF'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      ripristinaFocusTabella();
    }
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
                          key: ValueKey('attiva_${colonna}_$ordineCrescente'),
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

    final tablet = width < 1100;

    final double tableWidth =
        colDiscente +
        colImpresa +
        colCorso +
        colDocente +
        colAulaSede +
        colEnteAttestato +
        colAttrezzature +
        colData +
        colProt +
        colStato +
        colAzioni +
        (tablet ? 24 : 40);

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
              message: mostraTutteLePrenotazioni
                  ? 'Tutte le prenotazioni sono già visualizzate'
                  : 'Carica tutte le prenotazioni',
              child: ElevatedButton.icon(
                onPressed: mostraTutteLePrenotazioni || caricamentoPaginaDb
                    ? null
                    : () async {
                        setState(() {
                          azzeraSelezionePrenotazioni();
                        });

                        await caricaTutteLePrenotazioni();
                        ripristinaFocusTabella();
                      },
                icon: caricamentoPaginaDb && !mostraTutteLePrenotazioni
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.unfold_more_rounded),
                label: Text(
                  mostraTutteLePrenotazioni
                      ? 'Tutto visualizzato'
                      : 'Mostra tutto',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF475569),
                  disabledBackgroundColor: const Color(0xFFF1F5F9),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: mostraTutteLePrenotazioni
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
                  ? 'Nessuna prenotazione da esportare'
                  : prenotazioniVisibili.length == 1
                  ? 'Esporta 1 prenotazione visualizzata in Excel'
                  : 'Esporta ${prenotazioniVisibili.length} prenotazioni visualizzate in Excel',
              child: AppActionButton(
                type: AppActionButtonType.excel,
                onPressed: prenotazioniVisibili.isEmpty
                    ? null
                    : () {
                        setState(() {
                          azzeraSelezionePrenotazioni();
                        });

                        exportPrenotazioniExcel();
                      },
                label: 'Excel (${prenotazioniVisibili.length})',
              ),
            ),

            const SizedBox(width: 10),

            Tooltip(
              message: prenotazioniVisibili.isEmpty
                  ? 'Nessuna prenotazione da esportare'
                  : prenotazioniVisibili.length == 1
                  ? 'Esporta 1 prenotazione visualizzata in PDF'
                  : 'Esporta ${prenotazioniVisibili.length} prenotazioni visualizzate in PDF',
              child: AppActionButton(
                type: AppActionButtonType.pdf,
                onPressed: prenotazioniVisibili.isEmpty
                    ? null
                    : () {
                        setState(() {
                          azzeraSelezionePrenotazioni();
                        });

                        esportaPdf();
                      },
                label: 'PDF (${prenotazioniVisibili.length})',
              ),
            ),

            const SizedBox(width: 12),

            Tooltip(
              message: 'Crea una nuova prenotazione',
              child: AppActionButton(
                type: AppActionButtonType.nuovo,
                onPressed: () {
                  setState(() {
                    azzeraSelezionePrenotazioni();
                  });

                  apriDialogNuovaPrenotazione();
                },
                label: 'Nuova prenotazione',
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
                                              setState(() {
                                                ricercaController.clear();
                                                filtroLocale = 'tutte';
                                                prenotazioniFiltrate =
                                                    List<
                                                      Map<String, dynamic>
                                                    >.from(prenotazioni);
                                                azzeraSelezionePrenotazioni();
                                              });

                                              ripristinaFocusTabella();
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
                        const SizedBox(height: 8),

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
                                          vertical: 8,
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
                                            vertical: 8,
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

                                    Tooltip(
                                      message:
                                          prenotazioniSelezionateIds.isEmpty
                                          ? 'Nessuna prenotazione selezionata'
                                          : prenotazioniSelezionateIds.length ==
                                                1
                                          ? 'Genera dichiarazione corso per la prenotazione selezionata'
                                          : 'Genera dichiarazione corso per ${prenotazioniSelezionateIds.length} prenotazioni selezionate',
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            prenotazioniSelezionateIds.isEmpty
                                            ? null
                                            : () async {
                                                await generaDichiarazioneCorso();

                                                if (!mounted) return;

                                                setState(() {
                                                  azzeraSelezionePrenotazioni();
                                                });

                                                ripristinaFocusTabella();
                                              },
                                        icon: const Icon(
                                          Icons.description_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          prenotazioniSelezionateIds.isEmpty
                                              ? 'Nessuna selezione'
                                              : 'Dichiarazione corso (${prenotazioniSelezionateIds.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF7C3AED,
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

                        const SizedBox(height: 0),
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
                                      height: 39,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        boxShadow: headerShadowVisible
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.06),
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
                                        child: KeyboardListener(
                                          focusNode: tableFocusNode,
                                          autofocus: true,
                                          onKeyEvent: gestisciTasti,
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
                                                                    children: [
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
                                                                    children: [
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
                                                                    children: [
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
                                                                    children: [
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
                                                                    children: [
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

                                                            if (result ==
                                                                null) {
                                                              return;
                                                            }

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

                                                          onRegistro: () =>
                                                              apriDialogRegistroPresenze(
                                                                p,
                                                              ),

                                                          onStampaRegistro: () =>
                                                              stampaRegistroPresenze(
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

const double colDiscente = 220;
const double colImpresa = 130;
const double colCorso = 230;
const double colDocente = 105;
const double colAulaSede = 115;
const double colEnteAttestato = 125;
const double colAttrezzature = 130;
const double colData = 80;
const double colProt = 45;
const double colStato = 105;
const double colAzioni = 145;

class PrenotazioneRow extends StatefulWidget {
  final Map<String, dynamic> prenotazione;
  final bool tablet;
  final ScrollController horizontalController;

  final bool selezionata;
  final VoidCallback onSeleziona;
  final VoidCallback onRegistro;
  final VoidCallback onStampaRegistro;
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
    required this.onRegistro,
    required this.onStampaRegistro,
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
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
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
                        ),

                        SizedBox(
                          width: colCorso,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
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
                        ),

                        SizedBox(
                          width: colDocente,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              (() {
                                final cognome = widget.testo(
                                  widget.prenotazione['docente_cognome'],
                                );
                                final nome = widget.testo(
                                  widget.prenotazione['docente_nome'],
                                );
                                final docente = '$cognome $nome'.trim();

                                return docente.isEmpty ? '-' : docente;
                              })(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colAulaSede,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              (() {
                                final denominazione = widget.testo(
                                  widget
                                      .prenotazione['aula_sede_denominazione'],
                                );
                                final comune = widget.testo(
                                  widget.prenotazione['aula_sede_comune'],
                                );

                                if (denominazione.isEmpty && comune.isEmpty) {
                                  return '-';
                                }
                                if (comune.isEmpty) return denominazione;
                                if (denominazione.isEmpty) return comune;

                                return '$denominazione - $comune';
                              })(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colEnteAttestato,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              (() {
                                final ente = widget.testo(
                                  widget
                                      .prenotazione['ente_attestato_denominazione'],
                                );

                                return ente.isEmpty ? '-' : ente;
                              })(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: colAttrezzature,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              (() {
                                final attrezzature = widget.testo(
                                  widget.prenotazione['attrezzature_sintesi'],
                                );

                                return attrezzature.isEmpty
                                    ? '-'
                                    : attrezzature;
                              })(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
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
                          child: Center(child: TableStatusBadge(status: stato)),
                        ),

                        SizedBox(
                          width: colAzioni,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Modifica prenotazione',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                onPressed: widget.onModifica,
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                              ),

                              IconButton(
                                tooltip: 'Registro presenze',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                onPressed: widget.onRegistro,
                                icon: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 19,
                                  color: Color(0xFFF97316),
                                ),
                              ),

                              IconButton(
                                tooltip: 'Stampa registro',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                onPressed: widget.onStampaRegistro,
                                icon: const Icon(
                                  Icons.print_outlined,
                                  size: 19,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Elimina prenotazione',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
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
                        padding: const EdgeInsets.only(left: 16, right: 14),
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
                  headerBuilder('Docente', colDocente, 'docente'),
                  headerBuilder('Aula/Sede', colAulaSede, 'aula_sede'),
                  headerBuilder(
                    'Ente attestati',
                    colEnteAttestato,
                    'ente_attestato',
                  ),
                  headerBuilder(
                    'Attrezzature',
                    colAttrezzature,
                    'attrezzature',
                  ),
                  headerBuilder('Data', colData, 'data'),
                  headerBuilder('Prot.', colProt, 'prot'),
                  SizedBox(
                    width: colStato,
                    child: Center(
                      child: SizedBox(
                        width: colStato,
                        child: Center(
                          child: headerBuilder('Stato', 72, 'stato'),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: colAzioni,
                    child: const Center(
                      child: Text(
                        'Azioni',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
                  color: const Color(0xFFF8FAFC),
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
            ],
          );
        },
      ),
    );
  }
}
