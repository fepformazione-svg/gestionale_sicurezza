import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/data_breach.dart';
import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

class RegistroDataBreachPage extends StatefulWidget {
  const RegistroDataBreachPage({super.key});

  @override
  State<RegistroDataBreachPage> createState() => _RegistroDataBreachPageState();
}

class _RegistroDataBreachPageState extends State<RegistroDataBreachPage> {
  final TextEditingController ricercaController = TextEditingController();

  final List<String> stati = const [
    'Tutti',
    'Aperto',
    'In valutazione',
    'Chiuso',
  ];

  String filtroStato = 'Tutti';
  String filtroGravita = 'Tutte';
  String filtroNotificaGarante = 'Tutte';
  String filtroComunicazioneInteressati = 'Tutte';

  bool filtroSoloNotificatiGarante = false;
  bool caricamento = true;
  List<DataBreach> elencoDataBreach = [];
  List<DataBreach> elencoRiepilogoDataBreach = [];

  String campoOrdinamentoDataBreach = 'dataEvento';
  bool ordinamentoDataBreachCrescente = false;

  String _normalizzaStatoDataBreach(String valore) {
    return valore.trim().toLowerCase();
  }

  int _conteggioDataBreachPerStato(String stato) {
    final statoNormalizzato = _normalizzaStatoDataBreach(stato);

    return elencoRiepilogoDataBreach
        .where(
          (breach) =>
              _normalizzaStatoDataBreach(breach.stato) == statoNormalizzato,
        )
        .length;
  }

  int _conteggioDataBreachNotificatiGarante() {
    return elencoRiepilogoDataBreach
        .where((breach) => breach.notificatoGarante)
        .length;
  }

  void cambiaOrdinamentoDataBreach(String campo) {
    setState(() {
      if (campoOrdinamentoDataBreach == campo) {
        ordinamentoDataBreachCrescente = !ordinamentoDataBreachCrescente;
      } else {
        campoOrdinamentoDataBreach = campo;

        if (campo == 'dataEvento' || campo == 'dataRilevazione') {
          ordinamentoDataBreachCrescente = false;
        } else {
          ordinamentoDataBreachCrescente = true;
        }
      }

      ordinaElencoDataBreach(elencoDataBreach);
    });
  }

  void ordinaElencoDataBreach(List<DataBreach> lista) {
    lista.sort((a, b) {
      final confronto = confrontaDataBreach(a, b, campoOrdinamentoDataBreach);
      return ordinamentoDataBreachCrescente ? confronto : -confronto;
    });
  }

  int confrontaDataBreach(DataBreach a, DataBreach b, String campo) {
    switch (campo) {
      case 'dataEvento':
        return confrontaDateDataBreach(a.dataEvento, b.dataEvento);

      case 'dataRilevazione':
        return confrontaDateDataBreach(a.dataRilevazione, b.dataRilevazione);

      case 'descrizione':
        return a.descrizione.toLowerCase().compareTo(
          b.descrizione.toLowerCase(),
        );

      case 'categorieDati':
        return a.categorieDati.toLowerCase().compareTo(
          b.categorieDati.toLowerCase(),
        );

      case 'rischio':
        return ordineRischioDataBreach(
          a.rischio,
        ).compareTo(ordineRischioDataBreach(b.rischio));

      case 'stato':
        return ordineStatoDataBreach(
          a.stato,
        ).compareTo(ordineStatoDataBreach(b.stato));

      case 'numeroInteressati':
        return a.numeroInteressati.compareTo(b.numeroInteressati);

      case 'notificatoGarante':
        return boolDataBreach(
          a.notificatoGarante,
        ).compareTo(boolDataBreach(b.notificatoGarante));

      case 'comunicatoInteressati':
        return boolDataBreach(
          a.comunicatoInteressati,
        ).compareTo(boolDataBreach(b.comunicatoInteressati));

      default:
        return a.descrizione.toLowerCase().compareTo(
          b.descrizione.toLowerCase(),
        );
    }
  }

  int confrontaDateDataBreach(String? valoreA, String? valoreB) {
    final dataA = parseDataDataBreach(valoreA);
    final dataB = parseDataDataBreach(valoreB);

    if (dataA == null && dataB == null) return 0;
    if (dataA == null) return 1;
    if (dataB == null) return -1;

    return dataA.compareTo(dataB);
  }

  DateTime? parseDataDataBreach(String? valore) {
    if (valore == null || valore.trim().isEmpty) return null;

    final testo = valore.trim();

    final formatoItaliano = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (formatoItaliano.hasMatch(testo)) {
      final parti = testo.split('/');
      return DateTime(
        int.parse(parti[2]),
        int.parse(parti[1]),
        int.parse(parti[0]),
      );
    }

    return DateTime.tryParse(testo);
  }

  int ordineRischioDataBreach(String rischio) {
    switch (rischio.toLowerCase()) {
      case 'basso':
      case 'bassa':
        return 1;
      case 'medio':
      case 'media':
        return 2;
      case 'alto':
      case 'alta':
        return 3;
      case 'critico':
      case 'critica':
        return 4;
      default:
        return 0;
    }
  }

  int ordineStatoDataBreach(String stato) {
    switch (stato.toLowerCase()) {
      case 'aperto':
        return 1;
      case 'in valutazione':
        return 2;
      case 'notificato':
        return 3;
      case 'chiuso':
        return 4;
      default:
        return 0;
    }
  }

  int boolDataBreach(bool valore) {
    return valore ? 1 : 0;
  }

  Widget intestazioneOrdinabileDataBreach(
    String titolo,
    String campo, {
    TextAlign textAlign = TextAlign.left,
  }) {
    final attivo = campoOrdinamentoDataBreach == campo;

    return InkWell(
      onTap: () => cambiaOrdinamentoDataBreach(campo),
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              titolo,
              textAlign: textAlign,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            attivo
                ? ordinamentoDataBreachCrescente
                      ? Icons.arrow_upward
                      : Icons.arrow_downward
                : Icons.unfold_more,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _applicaFiltroRiepilogoDataBreach(String stato) {
    setState(() {
      filtroStato = stato;
      filtroSoloNotificatiGarante = false;
    });

    caricaDataBreach();
  }

  bool get filtriAvanzatiDataBreachAttivi {
    return filtroStato != 'Tutti' ||
        filtroGravita != 'Tutte' ||
        filtroNotificaGarante != 'Tutte' ||
        filtroComunicazioneInteressati != 'Tutte' ||
        filtroSoloNotificatiGarante;
  }

  void azzeraFiltriDataBreach() {
    setState(() {
      filtroStato = 'Tutti';
      filtroGravita = 'Tutte';
      filtroNotificaGarante = 'Tutte';
      filtroComunicazioneInteressati = 'Tutte';
      filtroSoloNotificatiGarante = false;
    });

    caricaDataBreach();
  }

  bool passaFiltroGravitaDataBreach(DataBreach breach) {
    if (filtroGravita == 'Tutte') return true;

    return breach.rischio.trim().toLowerCase() ==
        filtroGravita.trim().toLowerCase();
  }

  bool passaFiltroNotificaGaranteDataBreach(DataBreach breach) {
    if (filtroNotificaGarante == 'Tutte') return true;

    if (filtroNotificaGarante == 'Notificati') {
      return breach.notificatoGarante;
    }

    if (filtroNotificaGarante == 'Non notificati') {
      return !breach.notificatoGarante;
    }

    return true;
  }

  bool passaFiltroComunicazioneInteressatiDataBreach(DataBreach breach) {
    if (filtroComunicazioneInteressati == 'Tutte') return true;

    if (filtroComunicazioneInteressati == 'Comunicati') {
      return breach.comunicatoInteressati;
    }

    if (filtroComunicazioneInteressati == 'Non comunicati') {
      return !breach.comunicatoInteressati;
    }

    return true;
  }

  void _applicaFiltroNotificatiGarante() {
    setState(() {
      filtroStato = 'Tutti';
      filtroSoloNotificatiGarante = true;
    });

    caricaDataBreach();
  }

  @override
  void initState() {
    super.initState();
    caricaDataBreach();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    super.dispose();
  }

  Future<void> caricaDataBreach() async {
    setState(() {
      caricamento = true;
    });

    final elencoRiepilogo = await AppDatabase.instance.getDataBreach(
      filtroStato: 'Tutti',
      ricerca: ricercaController.text,
    );

    final elencoFiltrato = await AppDatabase.instance.getDataBreach(
      filtroStato: filtroStato,
      ricerca: ricercaController.text,
    );

    final elencoBase = filtroSoloNotificatiGarante
        ? elencoFiltrato
              .where((elemento) => elemento.notificatoGarante)
              .toList()
        : elencoFiltrato;

    final elenco = elencoBase.where((elemento) {
      return passaFiltroGravitaDataBreach(elemento) &&
          passaFiltroNotificaGaranteDataBreach(elemento) &&
          passaFiltroComunicazioneInteressatiDataBreach(elemento);
    }).toList();

    if (!mounted) return;

    ordinaElencoDataBreach(elenco);

    setState(() {
      elencoRiepilogoDataBreach = elencoRiepilogo;
      elencoDataBreach = elenco;
      caricamento = false;
    });
  }

  Future<void> mostraDialogDataBreach({DataBreach? elemento}) async {
    final risultato = await showDialog<DataBreach>(
      context: context,
      builder: (_) => _DataBreachDialog(elemento: elemento),
    );

    if (risultato == null) return;

    if (elemento == null) {
      await AppDatabase.instance.insertDataBreach(risultato);
    } else {
      await AppDatabase.instance.updateDataBreach(risultato);
    }

    await caricaDataBreach();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          elemento == null
              ? 'Data breach inserito correttamente'
              : 'Data breach aggiornato correttamente',
        ),
      ),
    );
  }

  Future<void> eliminaDataBreach(DataBreach elemento) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elimina data breach'),
        content: const Text(
          'Vuoi eliminare definitivamente questa registrazione?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma != true || elemento.id == null) return;

    await AppDatabase.instance.deleteDataBreach(elemento.id!);
    await caricaDataBreach();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data breach eliminato')));
  }

  Future<void> esportaExcelDataBreach() async {
    if (elencoDataBreach.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun data breach da esportare')),
      );
      return;
    }

    String valore(String testo) {
      final pulito = testo.trim();
      return pulito.isEmpty ? '-' : pulito;
    }

    String siNo(bool valore) => valore ? 'Sì' : 'No';

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    try {
      final documento = excel.Excel.createExcel();
      const nomeFoglio = 'Registro Data Breach';
      final foglio = documento[nomeFoglio];

      if (documento.sheets.containsKey('Sheet1')) {
        documento.delete('Sheet1');
      }

      foglio.appendRow(
        [
          'ID',
          'Data evento',
          'Data rilevazione',
          'Descrizione evento',
          'Categorie dati coinvolti',
          'Categorie interessati',
          'Numero interessati/record coinvolti',
          'Conseguenze probabili',
          'Misure adottate o proposte',
          'Rischio',
          'Notificato al Garante',
          'Data notifica Garante',
          'Comunicazione agli interessati',
          'Data comunicazione interessati',
          'Motivazione mancata notifica/comunicazione',
          'Responsabile interno',
          'Stato',
          'Note',
          'Creato il',
          'Aggiornato il',
        ].map((testo) => excel.TextCellValue(testo)).toList(),
      );

      for (final elemento in elencoDataBreach) {
        foglio.appendRow(
          [
            elemento.id?.toString() ?? '-',
            valore(elemento.dataEvento),
            valore(elemento.dataRilevazione),
            valore(elemento.descrizione),
            valore(elemento.categorieDati),
            valore(elemento.categorieInteressati),
            valore(elemento.numeroInteressati),
            valore(elemento.conseguenze),
            valore(elemento.misureAdottate),
            valore(elemento.rischio),
            siNo(elemento.notificatoGarante),
            valore(elemento.dataNotificaGarante),
            siNo(elemento.comunicatoInteressati),
            valore(elemento.dataComunicazioneInteressati),
            valore(elemento.motivazioneMancataNotifica),
            valore(elemento.responsabileInterno),
            valore(elemento.stato),
            valore(elemento.note),
            valore(elemento.createdAt),
            valore(elemento.updatedAt),
          ].map((testo) => excel.TextCellValue(testo)).toList(),
        );
      }

      final bytes = documento.save();

      if (bytes == null) {
        throw Exception('Generazione file Excel non riuscita');
      }

      final now = DateTime.now();
      final timestamp =
          '${now.year}-${dueCifre(now.month)}-${dueCifre(now.day)}_'
          '${dueCifre(now.hour)}-${dueCifre(now.minute)}-${dueCifre(now.second)}';

      final cartellaExport = Directory(
        '${Platform.environment['USERPROFILE'] ?? Directory.current.path}'
        '${Platform.pathSeparator}Documents'
        '${Platform.pathSeparator}Gestionale Sicurezza',
      );

      if (!await cartellaExport.exists()) {
        await cartellaExport.create(recursive: true);
      }

      final percorso =
          '${cartellaExport.path}${Platform.pathSeparator}registro_data_breach_$timestamp.xlsx';

      final file = File(percorso);
      await file.writeAsBytes(bytes, flush: true);

      await Process.run('cmd', ['/c', 'start', '', percorso]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel Registro Data Breach esportato: $percorso'),
        ),
      );
    } catch (errore) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore export Excel: $errore')));
    }
  }

  Future<Uint8List> generaPdfRegistroDataBreachBytes() async {
    final listaDaEsportare = elencoDataBreach;

    String valore(String testo) {
      final pulito = testo.trim();
      return pulito.isEmpty ? '-' : pulito;
    }

    String siNo(bool valore) => valore ? 'Sì' : 'No';

    String dueCifre(int valore) => valore.toString().padLeft(2, '0');

    final now = DateTime.now();
    final generatoIl =
        '${dueCifre(now.day)}/${dueCifre(now.month)}/${now.year} '
        '${dueCifre(now.hour)}:${dueCifre(now.minute)}';

    final ricercaTesto = ricercaController.text.trim();

    final riepilogoFiltro = [
      'Stato: $filtroStato',
      'Rischio: $filtroGravita',
      'Notifica Garante: $filtroNotificaGarante',
      'Comunicazione interessati: $filtroComunicazioneInteressati',
      if (filtroSoloNotificatiGarante) 'Solo notificati Garante: Sì',
      if (ricercaTesto.isNotEmpty) 'Ricerca: "$ricercaTesto"',
      'Record esportati: ${listaDaEsportare.length}',
      'Generato il: $generatoIl',
    ].join(' | ');

    final documento = pw.Document();
    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            intestazioneAziendaPdfWidget(intestazioneAzienda),
            pw.SizedBox(height: 6),
            pw.Text(
              'Registro Data Breach',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Vista corrente filtrata/ricercata - GDPR 679/2016',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.Text(riepilogoFiltro, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.topLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Data evento',
              'Rilevazione',
              'Descrizione',
              'Categorie dati',
              'Rischio',
              'Garante',
              'Interessati',
              'Stato',
              'Responsabile',
            ],
            data: listaDaEsportare
                .map(
                  (elemento) => [
                    valore(elemento.dataEvento),
                    valore(elemento.dataRilevazione),
                    valore(elemento.descrizione),
                    valore(elemento.categorieDati),
                    valore(elemento.rischio),
                    siNo(elemento.notificatoGarante),
                    siNo(elemento.comunicatoInteressati),
                    valore(elemento.stato),
                    valore(elemento.responsabileInterno),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return documento.save();
  }

  Future<void> mostraAnteprimaPdfDataBreach() async {
    if (elencoDataBreach.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun data breach da esportare in PDF')),
      );
      return;
    }

    final bytes = await generaPdfRegistroDataBreachBytes();

    if (!mounted) return;

    final dimensioni = MediaQuery.of(context).size;
    final larghezzaDialog = dimensioni.width * 0.92;
    final altezzaDialog = dimensioni.height * 0.88;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anteprima PDF Registro Data Breach'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: larghezzaDialog,
          height: altezzaDialog,
          child: PdfPreview(
            build: (_) async => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowSharing: false,
            allowPrinting: true,
            initialPageFormat: PdfPageFormat.a4.landscape,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> stampaRegistroDataBreach() async {
    if (elencoDataBreach.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun data breach da stampare')),
      );
      return;
    }

    final bytes = await generaPdfRegistroDataBreachBytes();

    if (!mounted) return;

    final dimensioni = MediaQuery.of(context).size;
    final larghezzaDialog = dimensioni.width * 0.92;
    final altezzaDialog = dimensioni.height * 0.88;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anteprima stampa Registro Data Breach'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: larghezzaDialog,
          height: altezzaDialog,
          child: PdfPreview(
            build: (_) async => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowSharing: false,
            allowPrinting: true,
            initialPageFormat: PdfPageFormat.a4.landscape,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> mostraDettaglioDataBreach(DataBreach elemento) async {
    String valore(String testo) {
      final pulito = testo.trim();
      return pulito.isEmpty ? '-' : pulito;
    }

    String siNo(bool valore) => valore ? 'Sì' : 'No';

    Widget sezione(String titolo) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            titolo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    Widget riga(String etichetta, String contenuto) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 230,
              child: Text(
                etichetta,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: SelectableText(valore(contenuto))),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dettaglio data breach'),
        content: SizedBox(
          width: 850,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      badge(elemento.rischio, coloreRischio(elemento.rischio)),
                      badge(elemento.stato, coloreStato(elemento.stato)),
                    ],
                  ),
                ),
                sezione('Evento'),
                riga('Data evento', elemento.dataEvento),
                riga('Data rilevazione', elemento.dataRilevazione),
                riga('Descrizione dell’evento', elemento.descrizione),
                riga('Categorie dati coinvolti', elemento.categorieDati),
                riga('Categorie interessati', elemento.categorieInteressati),
                riga(
                  'Numero interessati/record coinvolti',
                  elemento.numeroInteressati,
                ),
                sezione('Valutazione e misure'),
                riga('Conseguenze probabili', elemento.conseguenze),
                riga('Misure adottate o proposte', elemento.misureAdottate),
                riga('Rischio', elemento.rischio),
                sezione('Notifiche GDPR'),
                riga('Notificato al Garante', siNo(elemento.notificatoGarante)),
                riga('Data notifica Garante', elemento.dataNotificaGarante),
                riga(
                  'Comunicazione agli interessati',
                  siNo(elemento.comunicatoInteressati),
                ),
                riga(
                  'Data comunicazione interessati',
                  elemento.dataComunicazioneInteressati,
                ),
                riga(
                  'Motivazione mancata notifica/comunicazione',
                  elemento.motivazioneMancataNotifica,
                ),
                sezione('Gestione interna'),
                riga('Responsabile interno', elemento.responsabileInterno),
                riga('Stato', elemento.stato),
                riga('Note', elemento.note),
                sezione('Tracciamento'),
                riga('Creato il', elemento.createdAt),
                riga('Aggiornato il', elemento.updatedAt),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> mostraGuidaRapidaDataBreach() async {
    Widget sezione(String titolo, String testo) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titolo,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(testo, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Guida rapida Registro Data Breach'),
        content: SizedBox(
          width: 850,
          child: SingleChildScrollView(
            child: Column(
              children: [
                sezione(
                  '1. A cosa serve il Registro Data Breach',
                  'Il Registro Data Breach consente di documentare gli eventi di violazione dei dati personali, anche quando non viene effettuata la notifica al Garante. '
                      'La registrazione interna aiuta a dimostrare la valutazione svolta, le misure adottate e le decisioni prese.',
                ),
                sezione(
                  '2. Nuovo data breach',
                  'Usa il pulsante "Nuovo data breach" per inserire una nuova registrazione. '
                      'Compila almeno la descrizione dell’evento e, quando disponibili, data evento, data rilevazione, categorie di dati, categorie di interessati e numero di soggetti o record coinvolti.',
                ),
                sezione(
                  '3. Valutazione del rischio',
                  'Il campo "Rischio" permette di classificare l’evento come Da valutare, Basso, Medio o Alto. '
                      'La classificazione deve essere coerente con le conseguenze probabili per gli interessati e con le misure già adottate o pianificate.',
                ),
                sezione(
                  '4. Notifica al Garante e comunicazione agli interessati',
                  'Le caselle "Notificato al Garante" e "Comunicazione agli interessati" indicano le azioni intraprese. '
                      'Quando una notifica o comunicazione non viene effettuata, è opportuno indicare la motivazione nel campo dedicato.',
                ),
                sezione(
                  '5. Stato della registrazione',
                  'Lo stato può essere Aperto, In valutazione o Chiuso. '
                      'Usa "Aperto" per eventi appena registrati, "In valutazione" quando sono in corso verifiche interne e "Chiuso" quando valutazione, misure e decisioni sono state completate.',
                ),
                sezione(
                  '6. Ricerca e filtri',
                  'La ricerca e il filtro Stato lavorano insieme. '
                      'Il pulsante "Azzera filtri" riporta la vista completa. Gli export Excel, PDF e la stampa rispettano sempre la vista corrente filtrata o ricercata.',
                ),
                sezione(
                  '7. Dettaglio, modifica ed eliminazione',
                  'L’icona occhio apre il dettaglio completo in sola lettura. '
                      'La matita modifica la registrazione. Il cestino elimina definitivamente il data breach dopo conferma.',
                ),
                sezione(
                  '8. Excel, PDF e stampa',
                  'Il pulsante Excel genera un file nella cartella Documenti\\Gestionale Sicurezza e lo apre automaticamente. '
                      'Il pulsante PDF apre l’anteprima con intestazione aziendale/logo. Il pulsante Stampa apre la stessa anteprima abilitando la stampa.',
                ),
                sezione(
                  '9. Buona prassi operativa',
                  'Per ogni evento conserva una traccia chiara: cosa è accaduto, quando è stato rilevato, quali dati sono coinvolti, quali conseguenze sono possibili, quali misure sono state adottate e perché è stata presa una determinata decisione sulla notifica.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void azzeraFiltri() {
    ricercaController.clear();
    setState(() {
      filtroStato = 'Tutti';
      filtroGravita = 'Tutte';
      filtroNotificaGarante = 'Tutte';
      filtroComunicazioneInteressati = 'Tutte';
      filtroSoloNotificatiGarante = false;
    });
    caricaDataBreach();
  }

  Widget buildFiltriAvanzatiDataBreach() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: filtroStato,
                decoration: const InputDecoration(
                  labelText: 'Stato',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: stati
                    .map(
                      (stato) => DropdownMenuItem<String>(
                        value: stato,
                        child: Text(stato),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    filtroStato = value;
                    filtroSoloNotificatiGarante = false;
                  });

                  caricaDataBreach();
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: filtroGravita,
                decoration: const InputDecoration(
                  labelText: 'Rischio',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Tutte', child: Text('Tutte')),
                  DropdownMenuItem(
                    value: 'Da valutare',
                    child: Text('Da valutare'),
                  ),
                  DropdownMenuItem(value: 'Basso', child: Text('Basso')),
                  DropdownMenuItem(value: 'Medio', child: Text('Medio')),
                  DropdownMenuItem(value: 'Alto', child: Text('Alto')),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    filtroGravita = value;
                  });

                  caricaDataBreach();
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: filtroNotificaGarante,
                decoration: const InputDecoration(
                  labelText: 'Notifica Garante',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Tutte', child: Text('Tutte')),
                  DropdownMenuItem(
                    value: 'Notificati',
                    child: Text('Notificati'),
                  ),
                  DropdownMenuItem(
                    value: 'Non notificati',
                    child: Text('Non notificati'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    filtroNotificaGarante = value;
                    filtroSoloNotificatiGarante = false;
                  });

                  caricaDataBreach();
                },
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: filtroComunicazioneInteressati,
                decoration: const InputDecoration(
                  labelText: 'Comunicazione interessati',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Tutte', child: Text('Tutte')),
                  DropdownMenuItem(
                    value: 'Comunicati',
                    child: Text('Comunicati'),
                  ),
                  DropdownMenuItem(
                    value: 'Non comunicati',
                    child: Text('Non comunicati'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    filtroComunicazioneInteressati = value;
                  });

                  caricaDataBreach();
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: filtriAvanzatiDataBreachAttivi ? azzeraFiltri : null,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Azzera filtri'),
            ),
            if (filtriAvanzatiDataBreachAttivi)
              const Chip(
                avatar: Icon(Icons.filter_alt, size: 18),
                label: Text('Filtri attivi'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Color coloreRischio(String rischio) {
    switch (rischio) {
      case 'Alto':
        return Colors.red.shade700;
      case 'Medio':
        return Colors.orange.shade700;
      case 'Basso':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'Chiuso':
        return Colors.green.shade700;
      case 'In valutazione':
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  Widget badge(String testo, Color colore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colore.withValues(alpha: 0.5)),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: colore,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _riepilogoDataBreach() {
    final totale = elencoRiepilogoDataBreach.length;
    final aperti = _conteggioDataBreachPerStato('Aperto');
    final inValutazione = _conteggioDataBreachPerStato('In valutazione');
    final notificati = _conteggioDataBreachNotificatiGarante();
    final chiusi = _conteggioDataBreachPerStato('Chiuso');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compatto = constraints.maxWidth < 720;
            final larghezzaCard = compatto
                ? constraints.maxWidth
                : (constraints.maxWidth - 48) / 5;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _cardRiepilogoDataBreach(
                  titolo: 'Totali',
                  valore: totale,
                  icona: Icons.fact_check_outlined,
                  colore: Colors.blueGrey,
                  larghezza: larghezzaCard,
                  attiva:
                      filtroStato == 'Tutti' && !filtroSoloNotificatiGarante,
                  onTap: () => _applicaFiltroRiepilogoDataBreach('Tutti'),
                ),
                _cardRiepilogoDataBreach(
                  titolo: 'Aperti',
                  valore: aperti,
                  icona: Icons.warning_amber_outlined,
                  colore: Colors.red,
                  larghezza: larghezzaCard,
                  attiva:
                      filtroStato == 'Aperto' && !filtroSoloNotificatiGarante,
                  onTap: () => _applicaFiltroRiepilogoDataBreach('Aperto'),
                ),
                _cardRiepilogoDataBreach(
                  titolo: 'In valutazione',
                  valore: inValutazione,
                  icona: Icons.manage_search_outlined,
                  colore: Colors.orange,
                  larghezza: larghezzaCard,
                  attiva:
                      filtroStato == 'In valutazione' &&
                      !filtroSoloNotificatiGarante,
                  onTap: () =>
                      _applicaFiltroRiepilogoDataBreach('In valutazione'),
                ),
                _cardRiepilogoDataBreach(
                  titolo: 'Notificati',
                  valore: notificati,
                  icona: Icons.outgoing_mail,
                  colore: Colors.deepPurple,
                  larghezza: larghezzaCard,
                  attiva: filtroSoloNotificatiGarante,
                  onTap: _applicaFiltroNotificatiGarante,
                ),
                _cardRiepilogoDataBreach(
                  titolo: 'Chiusi',
                  valore: chiusi,
                  icona: Icons.verified_outlined,
                  colore: Colors.green,
                  larghezza: larghezzaCard,
                  attiva:
                      filtroStato == 'Chiuso' && !filtroSoloNotificatiGarante,
                  onTap: () => _applicaFiltroRiepilogoDataBreach('Chiuso'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardRiepilogoDataBreach({
    required String titolo,
    required int valore,
    required IconData icona,
    required Color colore,
    required double larghezza,
    required bool attiva,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: larghezza,
      child: Card(
        elevation: attiva ? 4 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: attiva ? colore : Colors.grey.shade300,
            width: attiva ? 1.8 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colore.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icona, color: colore, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titolo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: attiva
                              ? FontWeight.w700
                              : FontWeight.w600,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Data Breach')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostraGuidaRapidaDataBreach,
        icon: const Icon(Icons.help_outline),
        label: const Text('Guida'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compatto = constraints.maxWidth < 720;
                    final larghezzaPulsante = compatto
                        ? constraints.maxWidth
                        : null;

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: larghezzaPulsante,
                          child: OutlinedButton.icon(
                            onPressed: caricamento || elencoDataBreach.isEmpty
                                ? null
                                : esportaExcelDataBreach,
                            icon: const Icon(Icons.table_view),
                            label: const Text('Excel'),
                          ),
                        ),
                        SizedBox(
                          width: larghezzaPulsante,
                          child: OutlinedButton.icon(
                            onPressed: caricamento || elencoDataBreach.isEmpty
                                ? null
                                : mostraAnteprimaPdfDataBreach,
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF'),
                          ),
                        ),
                        SizedBox(
                          width: larghezzaPulsante,
                          child: OutlinedButton.icon(
                            onPressed: caricamento || elencoDataBreach.isEmpty
                                ? null
                                : stampaRegistroDataBreach,
                            icon: const Icon(Icons.print),
                            label: const Text('Stampa'),
                          ),
                        ),
                        SizedBox(
                          width: larghezzaPulsante,
                          child: FilledButton.icon(
                            onPressed: () => mostraDialogDataBreach(),
                            icon: const Icon(Icons.add),
                            label: const Text('Nuovo data breach'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _riepilogoDataBreach(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: ricercaController,
                  decoration: InputDecoration(
                    labelText: 'Cerca',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ricercaController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Svuota ricerca',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              ricercaController.clear();
                              caricaDataBreach();
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => caricaDataBreach(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            buildFiltriAvanzatiDataBreach(),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : elencoDataBreach.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun data breach registrato',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1510,
                            child: Column(
                              children: [
                                Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Data evento',
                                          'dataEvento',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Rilevazione',
                                          'dataRilevazione',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 290,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Descrizione',
                                          'descrizione',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 170,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Categorie dati',
                                          'categorieDati',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Rischio',
                                          'rischio',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Garante',
                                          'notificatoGarante',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Interessati',
                                          'comunicatoInteressati',
                                        ),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: intestazioneOrdinabileDataBreach(
                                          'Stato',
                                          'stato',
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 190,
                                        child: Text(
                                          'Azioni',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: ListView.separated(
                                      itemCount: elencoDataBreach.length,
                                      separatorBuilder: (_, _) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final elemento =
                                            elencoDataBreach[index];

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 120,
                                                child: Text(
                                                  elemento.dataEvento,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 130,
                                                child: Text(
                                                  elemento.dataRilevazione,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 290,
                                                child: Text(
                                                  elemento.descrizione,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  elemento.categorieDati,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 120,
                                                child: badge(
                                                  elemento.rischio,
                                                  coloreRischio(
                                                    elemento.rischio,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 130,
                                                child: Text(
                                                  elemento.notificatoGarante
                                                      ? 'Sì'
                                                      : 'No',
                                                ),
                                              ),
                                              SizedBox(
                                                width: 140,
                                                child: Text(
                                                  elemento.comunicatoInteressati
                                                      ? 'Sì'
                                                      : 'No',
                                                ),
                                              ),
                                              SizedBox(
                                                width: 140,
                                                child: badge(
                                                  elemento.stato,
                                                  coloreStato(elemento.stato),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 190,
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Dettaglio',
                                                      icon: const Icon(
                                                        Icons.visibility,
                                                      ),
                                                      onPressed: () =>
                                                          mostraDettaglioDataBreach(
                                                            elemento,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Modifica',
                                                      icon: const Icon(
                                                        Icons.edit,
                                                      ),
                                                      onPressed: () =>
                                                          mostraDialogDataBreach(
                                                            elemento: elemento,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Elimina',
                                                      icon: const Icon(
                                                        Icons.delete,
                                                      ),
                                                      onPressed: () =>
                                                          eliminaDataBreach(
                                                            elemento,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
          ],
        ),
      ),
    );
  }
}

class _DataBreachDialog extends StatefulWidget {
  final DataBreach? elemento;

  const _DataBreachDialog({this.elemento});

  @override
  State<_DataBreachDialog> createState() => _DataBreachDialogState();
}

class _DataBreachDialogState extends State<_DataBreachDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController dataEventoController;
  late final TextEditingController dataRilevazioneController;
  late final TextEditingController descrizioneController;
  late final TextEditingController categorieDatiController;
  late final TextEditingController categorieInteressatiController;
  late final TextEditingController numeroInteressatiController;
  late final TextEditingController conseguenzeController;
  late final TextEditingController misureAdottateController;
  late final TextEditingController dataNotificaGaranteController;
  late final TextEditingController dataComunicazioneInteressatiController;
  late final TextEditingController motivazioneMancataNotificaController;
  late final TextEditingController responsabileInternoController;
  late final TextEditingController noteController;

  final List<String> rischi = const ['Da valutare', 'Basso', 'Medio', 'Alto'];

  final List<String> stati = const ['Aperto', 'In valutazione', 'Chiuso'];

  late String rischio;
  late String stato;
  late bool notificatoGarante;
  late bool comunicatoInteressati;

  @override
  void initState() {
    super.initState();

    final elemento = widget.elemento;

    dataEventoController = TextEditingController(
      text: elemento?.dataEvento ?? '',
    );
    dataRilevazioneController = TextEditingController(
      text: elemento?.dataRilevazione ?? '',
    );
    descrizioneController = TextEditingController(
      text: elemento?.descrizione ?? '',
    );
    categorieDatiController = TextEditingController(
      text: elemento?.categorieDati ?? '',
    );
    categorieInteressatiController = TextEditingController(
      text: elemento?.categorieInteressati ?? '',
    );
    numeroInteressatiController = TextEditingController(
      text: elemento?.numeroInteressati ?? '',
    );
    conseguenzeController = TextEditingController(
      text: elemento?.conseguenze ?? '',
    );
    misureAdottateController = TextEditingController(
      text: elemento?.misureAdottate ?? '',
    );
    dataNotificaGaranteController = TextEditingController(
      text: elemento?.dataNotificaGarante ?? '',
    );
    dataComunicazioneInteressatiController = TextEditingController(
      text: elemento?.dataComunicazioneInteressati ?? '',
    );
    motivazioneMancataNotificaController = TextEditingController(
      text: elemento?.motivazioneMancataNotifica ?? '',
    );
    responsabileInternoController = TextEditingController(
      text: elemento?.responsabileInterno ?? '',
    );
    noteController = TextEditingController(text: elemento?.note ?? '');

    rischio = elemento?.rischio ?? 'Da valutare';
    stato = elemento?.stato ?? 'Aperto';
    notificatoGarante = elemento?.notificatoGarante ?? false;
    comunicatoInteressati = elemento?.comunicatoInteressati ?? false;
  }

  @override
  void dispose() {
    dataEventoController.dispose();
    dataRilevazioneController.dispose();
    descrizioneController.dispose();
    categorieDatiController.dispose();
    categorieInteressatiController.dispose();
    numeroInteressatiController.dispose();
    conseguenzeController.dispose();
    misureAdottateController.dispose();
    dataNotificaGaranteController.dispose();
    dataComunicazioneInteressatiController.dispose();
    motivazioneMancataNotificaController.dispose();
    responsabileInternoController.dispose();
    noteController.dispose();
    super.dispose();
  }

  InputDecoration decorazione(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Widget campo(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool obbligatorio = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: decorazione(label),
      validator: obbligatorio
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obbligatorio';
              }

              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.elemento == null
        ? 'Nuovo data breach'
        : 'Modifica data breach';

    return AlertDialog(
      title: Text(titolo),
      content: SizedBox(
        width: 850,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: campo(dataEventoController, 'Data evento')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: campo(
                        dataRilevazioneController,
                        'Data rilevazione',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                campo(
                  descrizioneController,
                  'Descrizione dell’evento',
                  maxLines: 3,
                  obbligatorio: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: campo(
                        categorieDatiController,
                        'Categorie dati coinvolti',
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: campo(
                        categorieInteressatiController,
                        'Categorie interessati',
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                campo(
                  numeroInteressatiController,
                  'Numero interessati/record coinvolti',
                ),
                const SizedBox(height: 12),
                campo(
                  conseguenzeController,
                  'Conseguenze probabili',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                campo(
                  misureAdottateController,
                  'Misure adottate o proposte',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: rischio,
                        decoration: decorazione('Rischio'),
                        items: rischi
                            .map(
                              (valore) => DropdownMenuItem(
                                value: valore,
                                child: Text(valore),
                              ),
                            )
                            .toList(),
                        onChanged: (valore) {
                          setState(() {
                            rischio = valore ?? 'Da valutare';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: stato,
                        decoration: decorazione('Stato'),
                        items: stati
                            .map(
                              (valore) => DropdownMenuItem(
                                value: valore,
                                child: Text(valore),
                              ),
                            )
                            .toList(),
                        onChanged: (valore) {
                          setState(() {
                            stato = valore ?? 'Aperto';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: notificatoGarante,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notificato al Garante'),
                  onChanged: (valore) {
                    setState(() {
                      notificatoGarante = valore ?? false;
                    });
                  },
                ),
                if (notificatoGarante)
                  campo(dataNotificaGaranteController, 'Data notifica Garante'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: comunicatoInteressati,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Comunicazione agli interessati'),
                  onChanged: (valore) {
                    setState(() {
                      comunicatoInteressati = valore ?? false;
                    });
                  },
                ),
                if (comunicatoInteressati)
                  campo(
                    dataComunicazioneInteressatiController,
                    'Data comunicazione interessati',
                  ),
                const SizedBox(height: 12),
                campo(
                  motivazioneMancataNotificaController,
                  'Motivazione mancata notifica/comunicazione',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                campo(responsabileInternoController, 'Responsabile interno'),
                const SizedBox(height: 12),
                campo(noteController, 'Note', maxLines: 3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            final now = DateTime.now().toIso8601String();
            final elemento = widget.elemento;

            final risultato = DataBreach(
              id: elemento?.id,
              dataEvento: dataEventoController.text.trim(),
              dataRilevazione: dataRilevazioneController.text.trim(),
              descrizione: descrizioneController.text.trim(),
              categorieDati: categorieDatiController.text.trim(),
              categorieInteressati: categorieInteressatiController.text.trim(),
              numeroInteressati: numeroInteressatiController.text.trim(),
              conseguenze: conseguenzeController.text.trim(),
              misureAdottate: misureAdottateController.text.trim(),
              rischio: rischio,
              notificatoGarante: notificatoGarante,
              dataNotificaGarante: notificatoGarante
                  ? dataNotificaGaranteController.text.trim()
                  : '',
              comunicatoInteressati: comunicatoInteressati,
              dataComunicazioneInteressati: comunicatoInteressati
                  ? dataComunicazioneInteressatiController.text.trim()
                  : '',
              motivazioneMancataNotifica: motivazioneMancataNotificaController
                  .text
                  .trim(),
              responsabileInterno: responsabileInternoController.text.trim(),
              stato: stato,
              note: noteController.text.trim(),
              createdAt: elemento?.createdAt ?? now,
              updatedAt: now,
            );

            Navigator.pop(context, risultato);
          },
          icon: const Icon(Icons.save),
          label: const Text('Salva'),
        ),
      ],
    );
  }
}
