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

  int? prenotazioneSelezionataId;

  String filtroLocale = 'tutte';

String colonnaOrdinata = '';
bool ordineCrescente = true;

  List<Map<String, dynamic>> get prenotazioniVisibili {
  final filtroAttivo = filtroLocale;
  final query = ricercaController.text.toLowerCase().trim();

  return prenotazioniFiltrate.where((p) {
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

  ricercaFocusNode.onKeyEvent = (node, event) {
  if (event is KeyDownEvent &&
      event.logicalKey == LogicalKeyboardKey.escape) {
    ricercaController.text = '';
    ricercaController.selection = const TextSelection.collapsed(offset: 0);

    setState(() {
      prenotazioniFiltrate = List<Map<String, dynamic>>.from(prenotazioni);
      selectedRowIndex = 0;
      prenotazioneSelezionataId =
          prenotazioniFiltrate.isNotEmpty
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
      prenotazioneSelezionataId =
          prenotazioniVisibili.isNotEmpty
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
  super.dispose();
}
void gestisciTasti(RawKeyEvent event) async {
  if (event is! RawKeyDownEvent) return;

  if (event.isControlPressed &&
    event.logicalKey == LogicalKeyboardKey.keyF) {

  ricercaFocusNode.requestFocus();

  ricercaController.selection = TextSelection(
    baseOffset: 0,
    extentOffset: ricercaController.text.length,
  );

  return;
}

// CTRL + N
if (event.isControlPressed &&
    event.logicalKey == LogicalKeyboardKey.keyN) {
  apriDialogNuovaPrenotazione();
  return;
}

// CTRL + E
if (event.isControlPressed &&
    event.logicalKey == LogicalKeyboardKey.keyE) {
  exportPrenotazioniExcel();
  return;
}
  
  if (event.logicalKey == LogicalKeyboardKey.escape) {
  tableFocusNode.requestFocus();
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
void didUpdateWidget(
  covariant PrenotazioniPage oldWidget,
) {
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

    if (conferma) return 'Chiuso';
    if (registro) return 'Registro';
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
          confronto = nomeDiscente(a)
              .toLowerCase()
              .compareTo(nomeDiscente(b).toLowerCase());
          break;

        case 'impresa':
          confronto = testo(a['impresa_nome'])
              .toLowerCase()
              .compareTo(testo(b['impresa_nome']).toLowerCase());
          break;

        case 'corso':
          confronto = testo(a['corso_nome'])
              .toLowerCase()
              .compareTo(testo(b['corso_nome']).toLowerCase());
          break;

        case 'data':
          confronto = numeroData(a['data']).compareTo(numeroData(b['data']));
          break;

        case 'prot':
          confronto = testo(a['prot']).compareTo(testo(b['prot']));
          break;

        case 'stato':
          confronto = statoPrenotazione(a)
              .toLowerCase()
              .compareTo(statoPrenotazione(b).toLowerCase());
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
  
Map<String, dynamic> normalizzaPrenotazione(
  Map<String, dynamic> dati,
) {
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

      final nuovoId =
          await DatabaseService.instance.insertPrenotazione(datiPuliti);

            if (datiPuliti['conferma'] == 1) {
        await DatabaseService.instance
            .confermaPrenotazioneWorkflow(nuovoId);
      }

      await caricaPrenotazioni();
      notificaDatiModificati();
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prenotazione salvata'),
        ),
      );
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

  Future<void> modificaPrenotazione(
    Map<String, dynamic> prenotazione,
  ) async {
    final prenotazioneModificata =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return PrenotazioneDialog(
          prenotazione: prenotazione,
        );
      },
    );

    if (prenotazioneModificata == null) return;

    try {
      final datiPuliti =
          normalizzaPrenotazione(prenotazioneModificata);

      await DatabaseService.instance.updatePrenotazione(
        prenotazione['id'],
        datiPuliti,
      );

            if (datiPuliti['conferma'] == 1) {
        await DatabaseService.instance
            .confermaPrenotazioneWorkflow(
          prenotazione['id'],
        );
      } else {
        await DatabaseService.instance
            .annullaConfermaPrenotazioneWorkflow(
          prenotazione['id'],
        );
      }

      await caricaPrenotazioni();
      notificaDatiModificati();
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prenotazione aggiornata'),
        ),
      );
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

  Future<void> eliminaPrenotazione(
    Map<String, dynamic> prenotazione,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina prenotazione'),
          content: Text(
            'Eliminare ${nomeDiscente(prenotazione)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.deletePrenotazione(
      prenotazione['id'],
    );

    await caricaPrenotazioni();
  }
Widget filtroChip({
  required String titolo,
  required String filtro,
  required Color colore,
}) {
  final attivo =
    (filtroLocale.isNotEmpty
        ? filtroLocale
        : widget.filtro) == filtro;

  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
  setState(() {
    filtroLocale = filtro;
     });
},
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
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
  );
}
Widget compactKpiCard({
  required String titolo,
  required String valore,
  required Color colore,
  required String filtro,
}) {
  final attivo =
      (filtroLocale.isNotEmpty
          ? filtroLocale
          : widget.filtro) == filtro;

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
          color: attivo
              ? colore
              : Colors.grey.shade300,
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

  final path =
      '${directory.path}/prenotazioni_export.xlsx';

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
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Table.fromTextArray(
          headers: [
            'Discente',
            'Impresa',
            'Corso',
            'Data',
            'Prot.',
            'Stato',
          ],

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

  final file = File(
    '${directory.path}/prenotazioni.pdf',
  );

  await file.writeAsBytes(
    await pdf.save(),
  );

  await OpenFile.open(file.path);
}
Widget headerOrdinabile(
  String titolo,
  double larghezza,
  String colonna,
) {
  final attiva = colonnaOrdinata == colonna;

  return SizedBox(
    width: larghezza,
    child: InkWell(
      onTap: () => ordinaPrenotazioni(colonna),
      child: Row(
        children: [
          Text(
            titolo,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: attiva
                  ? const Color(0xFF2563EB)
                  : Colors.black87,
            ),
          ),

          const SizedBox(width: 4),

          if (attiva)
            Icon(
              ordineCrescente
                  ? Icons.arrow_drop_up
                  : Icons.arrow_drop_down,
              size: 18,
              color: const Color(0xFF2563EB),
            ),
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
  label: const Text('Export Excel'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF2563EB),
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 18,
    ),
    shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
  side: BorderSide(
    color: Colors.grey.shade300,
  ),
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
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
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
          .where((p) => statoPrenotazione(p) == 'Registro')
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

const SizedBox(height: 12),
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
      titolo: 'Aperte (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Aperto').length})',
      filtro: 'aperte',
      colore: Colors.green,
    ),

    filtroChip(
      titolo: 'Registro (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Registro').length})',
      filtro: 'registro',
      colore: Colors.orange,
    ),

    filtroChip(
      titolo: 'Chiuse (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Chiuso').length})',
      filtro: 'chiuse',
      colore: Colors.grey,
    ),

    filtroChip(
      titolo: 'Da fare (${prenotazioniFiltrate.where((p) => statoPrenotazione(p) == 'Da fare').length})',
      filtro: 'da_fare',
      colore: Colors.red,
    ),
  ],
),

const SizedBox(height: 14),
                      Expanded(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(
      color: const Color(0xFFE5E7EB),
    ),
  ),
      child: SingleChildScrollView(
        controller: horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: ultraWide
              ? MediaQuery.of(context).size.width - 320
              : desktop
                  ? MediaQuery.of(context).size.width - 280
                  : 1100,
          child: Column(
  children: [
    PrenotazioneHeaderRow(
  tablet: tablet,
  headerBuilder: headerOrdinabile,
),

    const Divider(height: 1),

    Expanded(
      child: RawKeyboardListener(
        focusNode: tableFocusNode,
        autofocus: true,
        onKey: gestisciTasti,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
        primary: false,
        physics: const ClampingScrollPhysics(),
        itemExtent: 64,
        itemCount: prenotazioniVisibili.length +
            (caricamentoPaginaDb ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= prenotazioniVisibili.length) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final p = prenotazioniVisibili[index];

                    return PrenotazioneRow(
                      prenotazione: p,
                      tablet: tablet,
                      selezionata: prenotazioneSelezionataId == p['id'],
                      onSeleziona: () {
                        setState(() {
                          selectedRowIndex = index;
                          prenotazioneSelezionataId = p['id'] as int?;
                        });

                        tableFocusNode.requestFocus();
                      },
                      onModifica: () => modificaPrenotazione(p),
                      onElimina: () => eliminaPrenotazione(p),
                      statoPrenotazione: statoPrenotazione,
                      nomeDiscente: nomeDiscente,
                      testo: testo,
                    );
                  },
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

const double colDiscente = 180;
const double colImpresa = 150;
const double colCorso = 260;
const double colData = 120;
const double colProt = 90;
const double colStato = 130;
const double colAzioni = 110;

class PrenotazioneRow extends StatefulWidget {
  final Map<String, dynamic> prenotazione;
  final bool tablet;

  final bool selezionata;
  final VoidCallback onSeleziona;

  final VoidCallback onModifica;
  final VoidCallback onElimina;

  final String Function(Map<String, dynamic>) statoPrenotazione;
  final String Function(Map<String, dynamic>) nomeDiscente;
  final String Function(dynamic) testo;

  const PrenotazioneRow({
    super.key,
    required this.prenotazione,
    required this.tablet,
    required this.selezionata,
    required this.onSeleziona,
    required this.onModifica,
    required this.onElimina,
    required this.statoPrenotazione,
    required this.nomeDiscente,
    required this.testo,
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
        ? const Color(0xFFEFF6FF)
        : rowColor;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: GestureDetector(
          onTap: widget.onSeleziona,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 64,
            decoration: BoxDecoration(
              color: effectiveColor,
              border: widget.selezionata
                  ? const Border(
                      left: BorderSide(
                        color: Color(0xFF2563EB),
                        width: 4,
                      ),
                    )
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.tablet ? 12 : 20,
            ),
          child: Row(
            children: [
              SizedBox(
                width: colDiscente,
                child: Text(
                  widget.nomeDiscente(widget.prenotazione),
                ),
              ),

              SizedBox(
                width: colImpresa,
                child: Text(
                  widget.testo(widget.prenotazione['impresa_nome']),
                ),
              ),

              SizedBox(
                width: colCorso,
                child: Text(
                  widget.testo(widget.prenotazione['corso_nome']),
                ),
              ),

              SizedBox(
                width: colData,
                child: Text(
                  widget.testo(widget.prenotazione['data']),
                ),
              ),

              SizedBox(
                width: colProt,
                child: Text(
                  widget.testo(widget.prenotazione['prot']),
                ),
              ),

              SizedBox(
                width: colStato,
                child: TableStatusBadge(
                  status: stato,
                ),
              ),

              SizedBox(
                width: colAzioni,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Modifica',
                      onPressed: widget.onModifica,
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    IconButton(
                      tooltip: 'Elimina',
                      onPressed: widget.onElimina,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
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
class PrenotazioneHeaderRow extends StatelessWidget {
  final bool tablet;

  final Widget Function(
    String titolo,
    double larghezza,
    String colonna,
  ) headerBuilder;

  const PrenotazioneHeaderRow({
    super.key,
    required this.tablet,
    required this.headerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: const Color(0xFFF3F4F6),
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 12 : 20,
      ),
      child: Row(
  children: [
    headerBuilder('Discente', colDiscente, 'discente'),
    headerBuilder('Impresa', colImpresa, 'impresa'),
    headerBuilder('Corso', colCorso, 'corso'),
    headerBuilder('Data', colData, 'data'),
    headerBuilder('Prot.', colProt, 'prot'),
    headerBuilder('Stato', colStato, 'stato'),

    SizedBox(
      width: colAzioni,
      child: const Text(
        'Azioni',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
),
    );
  }
}