import 'package:flutter/material.dart';

import '../services/app_database.dart';

class VisiteMedichePage extends StatefulWidget {
  const VisiteMedichePage({super.key});

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

  @override
  void initState() {
    super.initState();
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

    if (ricerca.isEmpty) {
      visiteFiltrate = List<Map<String, dynamic>>.from(visite);
      return;
    }

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

      return discente.contains(ricerca) ||
          medico.contains(ricerca) ||
          tipo.contains(ricerca) ||
          esito.contains(ricerca) ||
          giudizio.contains(ricerca);
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
                  onPressed: apriDialogNuovaVisita,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuova visita'),
                ),
              ],
            ),
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
                            width: 1500,
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
                                      child: DataTable(
                                        headingRowHeight: 0,
                                        columnSpacing: 18,
                                        horizontalMargin: 14,
                                        columns: const [
                                          DataColumn(
                                            label: SizedBox(width: 170),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 210),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 80),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 105),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 105),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 110),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 170),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 220),
                                          ),
                                          DataColumn(
                                            label: SizedBox(width: 86),
                                          ),
                                        ],
                                        rows: visiteFiltrate.map((visita) {
                                          final nome = testoValore(
                                            visita['discente_nome'],
                                          );
                                          final cognome = testoValore(
                                            visita['discente_cognome'],
                                          );

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                SizedBox(
                                                  width: 170,
                                                  child: Text(
                                                    '$cognome $nome',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 210,
                                                  child: Text(
                                                    testoValore(
                                                      visita['medico_struttura_denominazione'],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    testoValore(
                                                      visita['medico_struttura_tipo'],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 105,
                                                  child: Text(
                                                    testoValore(
                                                      visita['data_visita'],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 105,
                                                  child: Text(
                                                    testoValore(
                                                      visita['data_scadenza'],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    testoValore(
                                                      visita['esito'],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 170,
                                                  child: Text(
                                                    testoValore(
                                                      visita['giudizio'],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 220,
                                                  child: Text(
                                                    testoValore(visita['note']),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
