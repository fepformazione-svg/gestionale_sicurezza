import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

class VisiteMedichePage extends StatefulWidget {
  final String? ricercaIniziale;
  final String filtroStatoIniziale;

  const VisiteMedichePage({
    super.key,
    this.ricercaIniziale,
    this.filtroStatoIniziale = 'Tutte',
  });

  @override
  State<VisiteMedichePage> createState() => _VisiteMedichePageState();
}

class _VisiteMedichePageState extends State<VisiteMedichePage> {
  final TextEditingController _cercaController = TextEditingController();

  final ScrollController visiteHorizontalController = ScrollController();
  final ScrollController visiteVerticalController = ScrollController();

  List<Map<String, dynamic>> visite = [];
  List<Map<String, dynamic>> visiteFiltrate = [];
  List<Map<String, dynamic>> discenti = [];
  List<Map<String, dynamic>> mediciStrutture = [];
  bool caricamento = true;

  String filtroStatoVisita = 'Tutte';

  @override
  void initState() {
    super.initState();

    final ricercaIniziale = widget.ricercaIniziale?.trim() ?? '';
    if (ricercaIniziale.isNotEmpty) {
      _cercaController.text = ricercaIniziale;
    }

    final filtroIniziale = widget.filtroStatoIniziale.trim();
    if ([
      'Tutte',
      'Valide',
      'In scadenza',
      'Scadute',
    ].contains(filtroIniziale)) {
      filtroStatoVisita = filtroIniziale;
    }

    caricaVisite();
  }

  @override
  void dispose() {
    _cercaController.dispose();
    visiteHorizontalController.dispose();
    visiteVerticalController.dispose();
    super.dispose();
  }

  Future<void> caricaVisite() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getVisiteMediche();
    final elencoDiscenti = await AppDatabase.instance
        .getDiscentiPerVisiteMediche();
    final elencoMediciStrutture = await AppDatabase.instance
        .getMediciStrutture();

    if (!mounted) return;

    setState(() {
      visite = dati;
      discenti = elencoDiscenti;
      mediciStrutture = elencoMediciStrutture
          .where((voce) => voce['attivo']?.toString() != '0')
          .toList();
      applicaFiltro();
      caricamento = false;
    });
  }

  void applicaFiltro() {
    final ricerca = _cercaController.text.trim().toLowerCase();

    visiteFiltrate = visite.where((visita) {
      final nome = visita['discente_nome']?.toString().toLowerCase() ?? '';
      final cognome =
          visita['discente_cognome']?.toString().toLowerCase() ?? '';
      final discente = '$cognome $nome $nome $cognome';
      final medico =
          visita['medico_struttura_denominazione']?.toString().toLowerCase() ??
          '';
      final tipo =
          visita['medico_struttura_tipo']?.toString().toLowerCase() ?? '';
      final esito = visita['esito']?.toString().toLowerCase() ?? '';
      final giudizio = visita['giudizio']?.toString().toLowerCase() ?? '';

      final passaRicerca =
          ricerca.isEmpty ||
          discente.contains(ricerca) ||
          medico.contains(ricerca) ||
          tipo.contains(ricerca) ||
          esito.contains(ricerca) ||
          giudizio.contains(ricerca);

      final passaStato = passaFiltroStatoVisita(visita);

      return passaRicerca && passaStato;
    }).toList();
  }

  String testoValore(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  Widget cellaHeaderVisite(
    String testo,
    double larghezza, {
    bool centro = false,
  }) {
    return SizedBox(
      width: larghezza,
      child: Align(
        alignment: centro ? Alignment.center : Alignment.centerLeft,
        child: Text(
          testo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget cellaTestoVisite(
    String testo,
    double larghezza, {
    bool centro = false,
  }) {
    return SizedBox(
      width: larghezza,
      child: Align(
        alignment: centro ? Alignment.center : Alignment.centerLeft,
        child: Text(
          testo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
        ),
      ),
    );
  }

  DateTime? parseDataItaliana(String valore) {
    final testo = valore.trim();

    if (testo.isEmpty || testo == '-') return null;

    final parti = testo.split('/');
    if (parti.length != 3) return null;

    final giorno = int.tryParse(parti[0]);
    final mese = int.tryParse(parti[1]);
    final anno = int.tryParse(parti[2]);

    if (giorno == null || mese == null || anno == null) return null;

    return DateTime(anno, mese, giorno);
  }

  String statoVisitaMedica(dynamic dataScadenza) {
    final scadenza = parseDataItaliana(testoValore(dataScadenza));

    if (scadenza == null) return 'NON DISP.';

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(
      scadenza.year,
      scadenza.month,
      scadenza.day,
    );

    final giorniRimanenti = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorniRimanenti < 0) return 'SCADUTA';
    if (giorniRimanenti <= 60) return 'IN SCADENZA';
    return 'VALIDA';
  }

  Color coloreStatoVisita(String stato) {
    switch (stato) {
      case 'SCADUTA':
        return const Color(0xFFDC2626);
      case 'IN SCADENZA':
        return const Color(0xFFF59E0B);
      case 'VALIDA':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  bool passaFiltroStatoVisita(Map<String, dynamic> visita) {
    if (filtroStatoVisita == 'Tutte') {
      return true;
    }

    final stato = statoVisitaMedica(visita['data_scadenza']);

    if (filtroStatoVisita == 'Valide') {
      return stato == 'VALIDA';
    }

    if (filtroStatoVisita == 'In scadenza') {
      return stato == 'IN SCADENZA';
    }

    if (filtroStatoVisita == 'Scadute') {
      return stato == 'SCADUTA';
    }

    return true;
  }

  Widget badgeStatoVisita(String stato) {
    return Container(
      width: 104,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: coloreStatoVisita(stato).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: coloreStatoVisita(stato).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        stato,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: coloreStatoVisita(stato),
        ),
      ),
    );
  }

  Future<void> apriDialogNuovaVisita() async {
    if (discenti.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun discente disponibile per creare una visita.'),
        ),
      );
      return;
    }

    if (mediciStrutture.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun medico o struttura attiva disponibile. Aggiungine una da Impostazioni.',
          ),
        ),
      );
      return;
    }

    int? discenteSelezionatoId;
    int? medicoStrutturaSelezionatoId;

    final dataVisitaController = TextEditingController();
    final dataScadenzaController = TextEditingController();
    final esitoController = TextEditingController();
    final giudizioController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova visita medica'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: discenteSelezionatoId,
                        decoration: const InputDecoration(
                          labelText: 'Discente',
                          border: OutlineInputBorder(),
                        ),
                        items: discenti.map((discente) {
                          final id = discente['id'] as int;
                          final nome = discente['nome']?.toString() ?? '';
                          final cognome = discente['cognome']?.toString() ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$cognome $nome'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            discenteSelezionatoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: medicoStrutturaSelezionatoId,
                        decoration: const InputDecoration(
                          labelText: 'Medico / Struttura',
                          border: OutlineInputBorder(),
                        ),
                        items: mediciStrutture.map((voce) {
                          final id = voce['id'] as int;
                          final tipo = voce['tipo']?.toString() ?? '';
                          final denominazione =
                              voce['denominazione']?.toString() ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$tipo - $denominazione'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            medicoStrutturaSelezionatoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataVisitaController,
                        decoration: const InputDecoration(
                          labelText: 'Data visita',
                          hintText: 'Es. 17/06/2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataScadenzaController,
                        decoration: const InputDecoration(
                          labelText: 'Data scadenza',
                          hintText: 'Es. 17/06/2027',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: esitoController,
                        decoration: const InputDecoration(
                          labelText: 'Esito',
                          hintText: 'Es. Idoneo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: giudizioController,
                        decoration: const InputDecoration(
                          labelText: 'Giudizio',
                          hintText: 'Es. Idoneità alla mansione',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    if (discenteSelezionatoId == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Seleziona un discente.')),
                      );
                      return;
                    }

                    if (medicoStrutturaSelezionatoId == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Seleziona un medico o una struttura.'),
                        ),
                      );
                      return;
                    }

                    await AppDatabase.instance.inserisciVisitaMedica(
                      discenteId: discenteSelezionatoId!,
                      medicoStrutturaId: medicoStrutturaSelezionatoId,
                      dataVisita: dataVisitaController.text.trim(),
                      dataScadenza: dataScadenzaController.text.trim(),
                      esito: esitoController.text.trim(),
                      giudizio: giudizioController.text.trim(),
                      note: noteController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    await caricaVisite();

                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Visita medica salvata.')),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );

    dataVisitaController.dispose();
    dataScadenzaController.dispose();
    esitoController.dispose();
    giudizioController.dispose();
    noteController.dispose();
  }

  Future<void> apriDialogModificaVisita(Map<String, dynamic> visita) async {
    if (discenti.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun discente disponibile per modificare la visita.',
          ),
        ),
      );
      return;
    }

    if (mediciStrutture.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun medico o struttura attiva disponibile. Aggiungine una da Impostazioni.',
          ),
        ),
      );
      return;
    }

    final visitaId = visita['id'] as int;

    int? discenteSelezionatoId = visita['discente_id'] as int?;
    int? medicoStrutturaSelezionatoId = visita['medico_struttura_id'] as int?;

    final dataVisitaController = TextEditingController(
      text: testoValore(visita['data_visita']),
    );
    final dataScadenzaController = TextEditingController(
      text: testoValore(visita['data_scadenza']),
    );
    final esitoController = TextEditingController(
      text: testoValore(visita['esito']),
    );
    final giudizioController = TextEditingController(
      text: testoValore(visita['giudizio']),
    );
    final noteController = TextEditingController(
      text: testoValore(visita['note']),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica visita medica'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: discenteSelezionatoId,
                        decoration: const InputDecoration(
                          labelText: 'Discente',
                          border: OutlineInputBorder(),
                        ),
                        items: discenti.map((discente) {
                          final id = discente['id'] as int;
                          final nome = discente['nome']?.toString() ?? '';
                          final cognome = discente['cognome']?.toString() ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$cognome $nome'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            discenteSelezionatoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: medicoStrutturaSelezionatoId,
                        decoration: const InputDecoration(
                          labelText: 'Medico / Struttura',
                          border: OutlineInputBorder(),
                        ),
                        items: mediciStrutture.map((voce) {
                          final id = voce['id'] as int;
                          final tipo = voce['tipo']?.toString() ?? '';
                          final denominazione =
                              voce['denominazione']?.toString() ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$tipo - $denominazione'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            medicoStrutturaSelezionatoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataVisitaController,
                        decoration: const InputDecoration(
                          labelText: 'Data visita',
                          hintText: 'Es. 17/06/2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataScadenzaController,
                        decoration: const InputDecoration(
                          labelText: 'Data scadenza',
                          hintText: 'Es. 17/06/2027',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: esitoController,
                        decoration: const InputDecoration(
                          labelText: 'Esito',
                          hintText: 'Es. Idoneo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: giudizioController,
                        decoration: const InputDecoration(
                          labelText: 'Giudizio',
                          hintText: 'Es. Idoneità alla mansione',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    if (discenteSelezionatoId == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Seleziona un discente.')),
                      );
                      return;
                    }

                    if (medicoStrutturaSelezionatoId == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Seleziona un medico o una struttura.'),
                        ),
                      );
                      return;
                    }

                    await AppDatabase.instance.aggiornaVisitaMedica(
                      id: visitaId,
                      discenteId: discenteSelezionatoId!,
                      medicoStrutturaId: medicoStrutturaSelezionatoId,
                      dataVisita: dataVisitaController.text.trim(),
                      dataScadenza: dataScadenzaController.text.trim(),
                      esito: esitoController.text.trim(),
                      giudizio: giudizioController.text.trim(),
                      note: noteController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    await caricaVisite();

                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Visita medica aggiornata.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Salva modifiche'),
                ),
              ],
            );
          },
        );
      },
    );

    dataVisitaController.dispose();
    dataScadenzaController.dispose();
    esitoController.dispose();
    giudizioController.dispose();
    noteController.dispose();
  }

  Future<void> confermaEliminaVisita(Map<String, dynamic> visita) async {
    final visitaId = visita['id'] as int;
    final nome = testoValore(visita['discente_nome']);
    final cognome = testoValore(visita['discente_cognome']);
    final dataVisita = testoValore(visita['data_visita']);

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare visita medica?'),
          content: Text(
            'Vuoi eliminare la visita medica di $cognome $nome'
            '${dataVisita.isEmpty ? '' : ' del $dataVisita'}?\n\n'
            'Questa operazione non può essere annullata.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await AppDatabase.instance.eliminaVisitaMedica(visitaId);
    await caricaVisite();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Visita medica eliminata.')));
  }

  Future<void> esportaExcelVisiteMediche() async {
    if (visiteFiltrate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna visita medica da esportare.')),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Visite mediche'];
    excel.delete('Sheet1');

    final ora = DateTime.now();
    final dataOra = DateFormat('dd/MM/yyyy HH:mm').format(ora);
    final timestampFile = DateFormat('yyyy_MM_dd_HHmm').format(ora);

    final ricercaAttiva = _cercaController.text.trim().isNotEmpty;
    final filtroAttivo = filtroStatoVisita != 'Tutte';
    final vistaFiltrata = ricercaAttiva || filtroAttivo;

    final infoExport = vistaFiltrata
        ? 'Export visite mediche filtrato - ${visiteFiltrate.length} record - $dataOra'
        : 'Export visite mediche - ${visiteFiltrate.length} record - $dataOra';

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xls.TextCellValue(
      infoExport,
    );

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = xls.CellStyle(
      bold: true,
    );

    final intestazioni = [
      'Discente',
      'Medico / Struttura',
      'Tipo',
      'Data visita',
      'Scadenza',
      'Stato',
      'Esito',
      'Giudizio',
      'Note',
    ];

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      final cella = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 2),
      );

      cella.value = xls.TextCellValue(intestazioni[colonna]);
      cella.cellStyle = xls.CellStyle(bold: true);
    }

    for (var indice = 0; indice < visiteFiltrate.length; indice++) {
      final visita = visiteFiltrate[indice];
      final riga = indice + 3;

      final nome = testoValore(visita['discente_nome']);
      final cognome = testoValore(visita['discente_cognome']);
      final discente = '$cognome $nome'.trim();
      final stato = statoVisitaMedica(visita['data_scadenza']);

      final valori = [
        discente,
        testoValore(visita['medico_struttura_denominazione']),
        testoValore(visita['medico_struttura_tipo']),
        testoValore(visita['data_visita']),
        testoValore(visita['data_scadenza']),
        stato,
        testoValore(visita['esito']),
        testoValore(visita['giudizio']),
        testoValore(visita['note']),
      ];

      for (var colonna = 0; colonna < valori.length; colonna++) {
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: colonna,
                rowIndex: riga,
              ),
            )
            .value = xls.TextCellValue(
          valori[colonna],
        );
      }
    }

    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 34);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 18);
    sheet.setColumnWidth(7, 34);
    sheet.setColumnWidth(8, 42);

    final directory = await getApplicationDocumentsDirectory();
    final nomeFile = vistaFiltrata
        ? 'visite_mediche_export_filtrato_$timestampFile.xlsx'
        : 'visite_mediche_export_$timestampFile.xlsx';

    final file = File('${directory.path}/$nomeFile');
    final bytes = excel.encode();

    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la creazione del file Excel.'),
        ),
      );
      return;
    }

    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export Excel filtrato creato: ${visiteFiltrate.length} visite.'
              : 'Export Excel creato: ${visiteFiltrate.length} visite.',
        ),
      ),
    );
  }

  Future<void> esportaPdfVisiteMediche() async {
    if (visiteFiltrate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna visita medica da esportare.')),
      );
      return;
    }

    final pdf = pw.Document();
    final intestazione = await caricaIntestazioneAziendaPdf();

    final ora = DateTime.now();
    final dataOra = DateFormat('dd/MM/yyyy HH:mm').format(ora);
    final timestampFile = DateFormat('yyyy_MM_dd_HHmm').format(ora);

    final ricercaAttiva = _cercaController.text.trim().isNotEmpty;
    final filtroAttivo = filtroStatoVisita != 'Tutte';
    final vistaFiltrata = ricercaAttiva || filtroAttivo;

    final infoExport = vistaFiltrata
        ? 'Export visite mediche filtrato - ${visiteFiltrate.length} record - $dataOra'
        : 'Export visite mediche - ${visiteFiltrate.length} record - $dataOra';

    final righe = visiteFiltrate.map((visita) {
      final nome = testoValore(visita['discente_nome']);
      final cognome = testoValore(visita['discente_cognome']);
      final discente = '$cognome $nome'.trim();
      final stato = statoVisitaMedica(visita['data_scadenza']);

      return [
        discente,
        testoValore(visita['medico_struttura_denominazione']),
        testoValore(visita['medico_struttura_tipo']),
        testoValore(visita['data_visita']),
        testoValore(visita['data_scadenza']),
        stato,
        testoValore(visita['esito']),
        testoValore(visita['giudizio']),
        testoValore(visita['note']),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
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
            intestazioneAziendaPdfWidget(intestazione),
            pw.SizedBox(height: 8),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(dataOra, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'VISITE MEDICHE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              infoExport,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Discente',
                'Medico / Struttura',
                'Tipo',
                'Data visita',
                'Scadenza',
                'Stato',
                'Esito',
                'Giudizio',
                'Note',
              ],
              data: righe,
              border: pw.TableBorder.all(
                color: PdfColors.blueGrey100,
                width: 0.5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(1.9),
                2: pw.FlexColumnWidth(0.9),
                3: pw.FlexColumnWidth(0.9),
                4: pw.FlexColumnWidth(0.9),
                5: pw.FlexColumnWidth(1.1),
                6: pw.FlexColumnWidth(1.0),
                7: pw.FlexColumnWidth(1.7),
                8: pw.FlexColumnWidth(2.0),
              },
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final nomeFile = vistaFiltrata
        ? 'visite_mediche_export_filtrato_$timestampFile.pdf'
        : 'visite_mediche_export_$timestampFile.pdf';

    final file = File('${directory.path}/$nomeFile');
    await file.writeAsBytes(await pdf.save(), flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export PDF filtrato creato: ${visiteFiltrate.length} visite.'
              : 'Export PDF creato: ${visiteFiltrate.length} visite.',
        ),
      ),
    );
  }

  Future<void> stampaVisiteMediche() async {
    if (visiteFiltrate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna visita medica da stampare.')),
      );
      return;
    }

    final intestazione = await caricaIntestazioneAziendaPdf();

    final ora = DateTime.now();
    final dataOra = DateFormat('dd/MM/yyyy HH:mm').format(ora);

    final ricercaAttiva = _cercaController.text.trim().isNotEmpty;
    final filtroAttivo = filtroStatoVisita != 'Tutte';
    final vistaFiltrata = ricercaAttiva || filtroAttivo;

    final infoExport = vistaFiltrata
        ? 'Stampa visite mediche filtrata - ${visiteFiltrate.length} record - $dataOra'
        : 'Stampa visite mediche - ${visiteFiltrate.length} record - $dataOra';

    final righe = visiteFiltrate.map((visita) {
      final nome = testoValore(visita['discente_nome']);
      final cognome = testoValore(visita['discente_cognome']);
      final discente = '$cognome $nome'.trim();
      final stato = statoVisitaMedica(visita['data_scadenza']);

      return [
        discente,
        testoValore(visita['medico_struttura_denominazione']),
        testoValore(visita['medico_struttura_tipo']),
        testoValore(visita['data_visita']),
        testoValore(visita['data_scadenza']),
        stato,
        testoValore(visita['esito']),
        testoValore(visita['giudizio']),
        testoValore(visita['note']),
      ];
    }).toList();

    await Printing.layoutPdf(
      name: vistaFiltrata
          ? 'stampa_visite_mediche_filtrata.pdf'
          : 'stampa_visite_mediche.pdf',
      format: PdfPageFormat.a4.landscape,
      onLayout: (format) async {
        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(24),
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
                intestazioneAziendaPdfWidget(intestazione),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    dataOra,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'VISITE MEDICHE',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  infoExport,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'Discente',
                    'Medico / Struttura',
                    'Tipo',
                    'Data visita',
                    'Scadenza',
                    'Stato',
                    'Esito',
                    'Giudizio',
                    'Note',
                  ],
                  data: righe,
                  border: pw.TableBorder.all(
                    color: PdfColors.blueGrey100,
                    width: 0.5,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.centerLeft,
                  oddRowDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.6),
                    1: pw.FlexColumnWidth(1.9),
                    2: pw.FlexColumnWidth(0.9),
                    3: pw.FlexColumnWidth(0.9),
                    4: pw.FlexColumnWidth(0.9),
                    5: pw.FlexColumnWidth(1.1),
                    6: pw.FlexColumnWidth(1.0),
                    7: pw.FlexColumnWidth(1.7),
                    8: pw.FlexColumnWidth(2.0),
                  },
                ),
              ];
            },
          ),
        );

        return pdf.save();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visite Mediche'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cercaController,
                    decoration: InputDecoration(
                      hintText:
                          'Cerca discente, medico, struttura, esito o giudizio...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _cercaController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Azzera ricerca',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                setState(() {
                                  _cercaController.clear();
                                  applicaFiltro();
                                });
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        applicaFiltro();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: visiteFiltrate.isEmpty
                      ? null
                      : esportaExcelVisiteMediche,
                  icon: const Icon(Icons.table_chart_rounded),
                  label: Text('Export Excel (${visiteFiltrate.length})'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: visiteFiltrate.isEmpty
                      ? null
                      : esportaPdfVisiteMediche,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text('Export PDF (${visiteFiltrate.length})'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: visiteFiltrate.isEmpty
                      ? null
                      : stampaVisiteMediche,
                  icon: const Icon(Icons.print_rounded),
                  label: Text('Stampa (${visiteFiltrate.length})'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: apriDialogNuovaVisita,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuova visita'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tutte'),
                  selected: filtroStatoVisita == 'Tutte',
                  onSelected: (_) {
                    setState(() {
                      filtroStatoVisita = 'Tutte';
                      applicaFiltro();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Valide'),
                  selected: filtroStatoVisita == 'Valide',
                  onSelected: (_) {
                    setState(() {
                      filtroStatoVisita = 'Valide';
                      applicaFiltro();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('In scadenza'),
                  selected: filtroStatoVisita == 'In scadenza',
                  onSelected: (_) {
                    setState(() {
                      filtroStatoVisita = 'In scadenza';
                      applicaFiltro();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Scadute'),
                  selected: filtroStatoVisita == 'Scadute',
                  onSelected: (_) {
                    setState(() {
                      filtroStatoVisita = 'Scadute';
                      applicaFiltro();
                    });
                  },
                ),
              ],
            ),

            if (filtroStatoVisita != 'Tutte') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('Filtro stato: $filtroStatoVisita'),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    onDeleted: () {
                      setState(() {
                        filtroStatoVisita = 'Tutte';
                        applicaFiltro();
                      });
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : visiteFiltrate.isEmpty
                    ? Center(
                        child: Text(
                          _cercaController.text.trim().isEmpty
                              ? 'Nessuna visita medica presente'
                              : 'Nessuna visita medica trovata',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: visiteHorizontalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        notificationPredicate: (notification) {
                          return notification.metrics.axis == Axis.horizontal;
                        },
                        child: SingleChildScrollView(
                          controller: visiteHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1580,
                            child: Column(
                              children: [
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      cellaHeaderVisite('Discente', 170),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite(
                                        'Medico / Struttura',
                                        210,
                                      ),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite('Tipo', 80),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite('Data visita', 105),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite('Scadenza', 105),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite(
                                        'Stato',
                                        104,
                                        centro: true,
                                      ),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite('Esito', 110),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite('Giudizio', 170),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite('Note', 220),
                                      const SizedBox(width: 18),
                                      cellaHeaderVisite(
                                        'Azioni',
                                        86,
                                        centro: true,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Scrollbar(
                                    controller: visiteVerticalController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    interactive: true,
                                    child: SingleChildScrollView(
                                      controller: visiteVerticalController,
                                      child: Column(
                                        children: visiteFiltrate.map((visita) {
                                          final nome = testoValore(
                                            visita['discente_nome'],
                                          );
                                          final cognome = testoValore(
                                            visita['discente_cognome'],
                                          );
                                          final stato = statoVisitaMedica(
                                            visita['data_scadenza'],
                                          );

                                          return Container(
                                            height: 52,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Color(0xFFE2E8F0),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                cellaTestoVisite(
                                                  '$cognome $nome',
                                                  170,
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(
                                                    visita['medico_struttura_denominazione'],
                                                  ),
                                                  210,
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(
                                                    visita['medico_struttura_tipo'],
                                                  ),
                                                  80,
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(
                                                    visita['data_visita'],
                                                  ),
                                                  105,
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(
                                                    visita['data_scadenza'],
                                                  ),
                                                  105,
                                                ),
                                                const SizedBox(width: 18),
                                                SizedBox(
                                                  width: 104,
                                                  child: Center(
                                                    child: badgeStatoVisita(
                                                      stato,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(visita['esito']),
                                                  110,
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(
                                                    visita['giudizio'],
                                                  ),
                                                  170,
                                                ),
                                                const SizedBox(width: 18),
                                                cellaTestoVisite(
                                                  testoValore(visita['note']),
                                                  220,
                                                ),
                                                const SizedBox(width: 18),
                                                SizedBox(
                                                  width: 86,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip:
                                                            'Modifica visita medica',
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 36,
                                                              minHeight: 36,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.edit_rounded,
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          apriDialogModificaVisita(
                                                            visita,
                                                          );
                                                        },
                                                      ),
                                                      IconButton(
                                                        tooltip:
                                                            'Elimina visita medica',
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 36,
                                                              minHeight: 36,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.delete_rounded,
                                                          color: Color(
                                                            0xFFDC2626,
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          confermaEliminaVisita(
                                                            visita,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
