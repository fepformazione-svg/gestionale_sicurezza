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
    if (prenotazioniSelezionateIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno una prenotazione da stampare'),
        ),
      );
      return;
    }

    debugPrint('STAMPA SELEZIONATE IDS: $prenotazioniSelezionateIds');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stampa di ${prenotazioniSelezionateIds.length} prenotazioni selezionate',
        ),
      ),
    );
  }

  void selezionaTutto() {
    setState(() {
      prenotazioniSelezionateIds = prenotazioniVisibili
          .map((p) => p['id'] as int)
          .toSet();
    });

    debugPrint('SELEZIONA TUTTO IDS: $prenotazioniSelezionateIds');
  }

  void deselezionaTutto() {
    setState(() {
      prenotazioniSelezionateIds.clear();
      ultimoIndexSelezionato = null;
    });

    debugPrint('DESELEZIONA TUTTO');
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
        prenotazioniSelezionateIds = prenotazioniFiltrate
            .map((p) => p['id'] as int)
            .toSet();

        ultimoIndexSelezionato = prenotazioniFiltrate.isNotEmpty
            ? prenotazioniFiltrate.length - 1
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

      prenotazioniFiltrate.sort(confronta);
      prenotazioni.sort(confronta);

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

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          filtroLocale = filtro;
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
              decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          filtroLocale = filtro;
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
              decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
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
    );
  }

  Future<void> exportPrenotazioniExcel() async {
    final excel = Excel.createExcel();

    final sheet = excel['Prenotazioni'];

    // HEADER
    sheet.appendRow([
      TextCellValue('Discente'),
      TextCellValue('Impresa'),
      TextCellValue('Corso'),
      TextCellValue('Data'),
      TextCellValue('Protocollo'),
      TextCellValue('Stato'),
    ]);

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

    final path = '${directory.path}/prenotazioni_export.xlsx';

    final fileBytes = excel.encode();

    if (fileBytes == null) return;

    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    await OpenFile.open(file.path);
  }

  Future<void> esportaPdf() async {
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
  }

  Widget headerOrdinabile(String titolo, double larghezza, String colonna) {
    final attiva = colonnaOrdinata == colonna;

    return SizedBox(
      width: larghezza,
      child: InkWell(
        onTap: () => ordinaPrenotazioni(colonna),
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
            if (attiva) ...[
              const SizedBox(width: 4),
              Icon(
                ordineCrescente ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: const Color(0xFF2563EB),
              ),
            ],
          ],
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
              child: AppSearchBar(
                controller: ricercaController,
                focusNode: ricercaFocusNode,

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

                hintText: 'Ricerca nella pagina prenotazioni...',
                onChanged: (value) {
                  cercaPrenotazioni(value);

                  setState(() {
                    selectedRowIndex = null;
                    prenotazioneSelezionataId = null;
                  });
                },
              ),
            ),

            const SizedBox(width: 16),

            ElevatedButton.icon(
              onPressed: exportPrenotazioniExcel,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Esporta elenco Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
              ),
            ),

            const SizedBox(width: 12),

            ElevatedButton.icon(
              onPressed: apriDialogNuovaPrenotazione,
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
                            child: Text(
                              'DataTable Enterprise',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Text(
                            '${prenotazioniVisibili.length} record',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
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

                      const SizedBox(height: 6),
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

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '${prenotazioniSelezionateIds.length} selezionate',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),

                          if (prenotazioniSelezionateIds.isNotEmpty) ...[
                            ElevatedButton.icon(
                              onPressed: selezionaTutto,
                              icon: const Icon(Icons.select_all, size: 18),
                              label: const Text('Seleziona tutte'),
                            ),

                            ElevatedButton.icon(
                              onPressed: deselezionaTutto,
                              icon: const Icon(Icons.deselect, size: 18),
                              label: const Text('Deseleziona'),
                            ),

                            ElevatedButton.icon(
                              onPressed: () async {
                                await aggiornaStatoPrenotazioniSelezionate(
                                  aperto: 1,
                                  registro: 0,
                                  conferma: 0,
                                );
                              },
                              icon: const Icon(Icons.lock_open, size: 18),
                              label: Text(
                                'Apri selezionate (${prenotazioniSelezionateIds.length})',
                              ),
                            ),

                            ElevatedButton.icon(
                              onPressed: () async {
                                await aggiornaStatoPrenotazioniSelezionate(
                                  aperto: 0,
                                  registro: 0,
                                  conferma: 1,
                                );
                              },
                              icon: const Icon(Icons.lock, size: 18),
                              label: const Text('Chiudi selezionate'),
                            ),

                            ElevatedButton.icon(
                              onPressed: registroSelezionate,
                              icon: const Icon(Icons.fact_check, size: 18),
                              label: const Text('Segna registro'),
                            ),

                            ElevatedButton.icon(
                              onPressed: stampaSelezionate,
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Stampa selezionate'),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

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
                                      height: 40,
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
                                              ? const SizedBox.expand(
                                                  child: Center(
                                                    child: Text(
                                                      'Nessuna prenotazione trovata',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Color(
                                                          0xFF374151,
                                                        ),
                                                      ),
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

                                                            debugPrint(
                                                              'MENU RESULT: $result',
                                                            );

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
                                tooltip: 'Modifica',
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
                                tooltip: 'Elimina',
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
      height: 48,
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
                        width: 30,
                        child: Transform.scale(
                          scale: 0.90,
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
