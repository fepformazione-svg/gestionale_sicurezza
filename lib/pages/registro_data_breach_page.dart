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
  bool caricamento = true;
  List<DataBreach> elencoDataBreach = [];

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

    final elenco = await AppDatabase.instance.getDataBreach(
      filtroStato: filtroStato,
      ricerca: ricercaController.text,
    );

    if (!mounted) return;

    setState(() {
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

  void azzeraFiltri() {
    ricercaController.clear();
    setState(() {
      filtroStato = 'Tutti';
    });
    caricaDataBreach();
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

  @override
  Widget build(BuildContext context) {
    final filtroAttivo =
        filtroStato != 'Tutti' || ricercaController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Data Breach'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: caricamento || elencoDataBreach.isEmpty
                  ? null
                  : esportaExcelDataBreach,
              icon: const Icon(Icons.table_view),
              label: const Text('Excel'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: caricamento || elencoDataBreach.isEmpty
                  ? null
                  : mostraAnteprimaPdfDataBreach,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => mostraDialogDataBreach(),
              icon: const Icon(Icons.add),
              label: const Text('Nuovo data breach'),
            ),
          ),
        ],
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
                    final compatto = constraints.maxWidth < 850;

                    final ricerca = TextField(
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
                    );

                    final filtro = DropdownButtonFormField<String>(
                      initialValue: filtroStato,
                      decoration: const InputDecoration(
                        labelText: 'Stato',
                        border: OutlineInputBorder(),
                      ),
                      items: stati
                          .map(
                            (stato) => DropdownMenuItem(
                              value: stato,
                              child: Text(stato),
                            ),
                          )
                          .toList(),
                      onChanged: (valore) {
                        setState(() {
                          filtroStato = valore ?? 'Tutti';
                        });
                        caricaDataBreach();
                      },
                    );

                    final azzera = OutlinedButton.icon(
                      onPressed: filtroAttivo ? azzeraFiltri : null,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Azzera filtri'),
                    );

                    if (compatto) {
                      return Column(
                        children: [
                          ricerca,
                          const SizedBox(height: 12),
                          filtro,
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: azzera,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 3, child: ricerca),
                        const SizedBox(width: 12),
                        SizedBox(width: 220, child: filtro),
                        const SizedBox(width: 12),
                        azzera,
                      ],
                    );
                  },
                ),
              ),
            ),
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
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Data evento',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          'Rilevazione',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 290,
                                        child: Text(
                                          'Descrizione',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 170,
                                        child: Text(
                                          'Categorie dati',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Rischio',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          'Garante',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: Text(
                                          'Interessati',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: Text(
                                          'Stato',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
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
