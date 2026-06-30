import 'package:flutter/material.dart';

import '../models/consenso_privacy.dart';
import '../services/app_database.dart';

class RegistroConsensiPrivacyPage extends StatefulWidget {
  const RegistroConsensiPrivacyPage({super.key});

  @override
  State<RegistroConsensiPrivacyPage> createState() =>
      _RegistroConsensiPrivacyPageState();
}

class _RegistroConsensiPrivacyPageState
    extends State<RegistroConsensiPrivacyPage> {
  final TextEditingController ricercaController = TextEditingController();
  final ScrollController tabellaOrizzontaleController = ScrollController();

  late Future<List<ConsensoPrivacy>> futureConsensi;

  String filtroStato = 'Tutti';
  String filtroTipoSoggetto = 'Tutti';

  static const List<String> statiFiltro = [
    'Tutti',
    'ATTIVO',
    'REVOCATO',
    'SCADUTO',
  ];

  static const List<String> statiForm = ['ATTIVO', 'REVOCATO', 'SCADUTO'];

  static const List<String> tipiSoggettoFiltro = [
    'Tutti',
    'Discente',
    'Impresa',
    'Docente',
    'Fornitore',
    'Altro',
  ];

  static const List<String> tipiSoggettoForm = [
    'Discente',
    'Impresa',
    'Docente',
    'Fornitore',
    'Altro',
  ];

  static const List<String> finalitaForm = [
    'Formazione e gestione corsi',
    'Gestione rapporto contrattuale',
    'Adempimenti amministrativi e fiscali',
    'Sorveglianza sanitaria',
    'Comunicazioni informative',
    'Marketing/comunicazioni commerciali',
    'Altro',
  ];

  static const List<String> basiGiuridicheForm = [
    'Consenso',
    'Contratto',
    'Obbligo legale',
    'Legittimo interesse',
    'Altro',
  ];

  static const List<String> canaliRaccoltaForm = [
    'Modulo cartaceo',
    'Email',
    'Telefono',
    'Sito web',
    'Gestionale',
    'Altro',
  ];

  @override
  void initState() {
    super.initState();
    ricaricaConsensi();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    tabellaOrizzontaleController.dispose();
    super.dispose();
  }

  void ricaricaConsensi() {
    futureConsensi = AppDatabase.instance.getConsensiPrivacy(
      ricerca: ricercaController.text,
      stato: filtroStato,
      tipoSoggetto: filtroTipoSoggetto,
    );

    setState(() {});
  }

  Future<void> mostraDialogConsenso({ConsensoPrivacy? consenso}) async {
    final formKey = GlobalKey<FormState>();

    final nominativoController = TextEditingController(
      text: consenso?.nominativo ?? '',
    );
    final codiceFiscaleController = TextEditingController(
      text: consenso?.codiceFiscale ?? '',
    );
    final emailController = TextEditingController(text: consenso?.email ?? '');
    final telefonoController = TextEditingController(
      text: consenso?.telefono ?? '',
    );
    final versioneInformativaController = TextEditingController(
      text: consenso?.versioneInformativa ?? '',
    );
    final dataConsensoController = TextEditingController(
      text: consenso?.dataConsenso ?? '',
    );
    final dataRevocaController = TextEditingController(
      text: consenso?.dataRevoca ?? '',
    );
    final dataScadenzaController = TextEditingController(
      text: consenso?.dataScadenza ?? '',
    );
    final documentoRiferimentoController = TextEditingController(
      text: consenso?.documentoRiferimento ?? '',
    );
    final noteController = TextEditingController(text: consenso?.note ?? '');

    String tipoSoggetto = consenso?.tipoSoggetto ?? 'Altro';
    String finalita = consenso?.finalita ?? 'Formazione e gestione corsi';
    String baseGiuridica = consenso?.baseGiuridica ?? 'Consenso';
    String canaleRaccolta = consenso?.canaleRaccolta ?? 'Gestionale';
    String stato = consenso?.stato ?? 'ATTIVO';

    if (!tipiSoggettoForm.contains(tipoSoggetto)) {
      tipoSoggetto = 'Altro';
    }

    if (!finalitaForm.contains(finalita)) {
      finalita = 'Altro';
    }

    if (!basiGiuridicheForm.contains(baseGiuridica)) {
      baseGiuridica = 'Altro';
    }

    if (!canaliRaccoltaForm.contains(canaleRaccolta)) {
      canaleRaccolta = 'Altro';
    }

    if (!statiForm.contains(stato)) {
      stato = 'ATTIVO';
    }

    final salvato = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                consenso == null
                    ? 'Nuovo consenso/privacy'
                    : 'Modifica consenso/privacy',
              ),
              content: SizedBox(
                width: 780,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: tipoSoggetto,
                            decoration: const InputDecoration(
                              labelText: 'Tipo soggetto',
                              border: OutlineInputBorder(),
                            ),
                            items: tipiSoggettoForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => tipoSoggetto = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 520,
                          child: TextFormField(
                            controller: nominativoController,
                            decoration: const InputDecoration(
                              labelText: 'Nominativo / Ragione sociale',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo obbligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: codiceFiscaleController,
                            decoration: const InputDecoration(
                              labelText: 'Codice fiscale / P.IVA',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Telefono',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 360,
                          child: DropdownButtonFormField<String>(
                            initialValue: finalita,
                            decoration: const InputDecoration(
                              labelText: 'Finalità',
                              border: OutlineInputBorder(),
                            ),
                            items: finalitaForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => finalita = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: baseGiuridica,
                            decoration: const InputDecoration(
                              labelText: 'Base giuridica',
                              border: OutlineInputBorder(),
                            ),
                            items: basiGiuridicheForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => baseGiuridica = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: canaleRaccolta,
                            decoration: const InputDecoration(
                              labelText: 'Canale raccolta',
                              border: OutlineInputBorder(),
                            ),
                            items: canaliRaccoltaForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => canaleRaccolta = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: stato,
                            decoration: const InputDecoration(
                              labelText: 'Stato',
                              border: OutlineInputBorder(),
                            ),
                            items: statiForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => stato = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: dataConsensoController,
                            decoration: const InputDecoration(
                              labelText: 'Data consenso',
                              hintText: 'gg/mm/aaaa',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo obbligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: dataRevocaController,
                            decoration: const InputDecoration(
                              labelText: 'Data revoca',
                              hintText: 'gg/mm/aaaa',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: dataScadenzaController,
                            decoration: const InputDecoration(
                              labelText: 'Data scadenza/retention',
                              hintText: 'gg/mm/aaaa',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: versioneInformativaController,
                            decoration: const InputDecoration(
                              labelText: 'Versione informativa',
                              hintText: 'es. Privacy v1.0',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 490,
                          child: TextFormField(
                            controller: documentoRiferimentoController,
                            decoration: const InputDecoration(
                              labelText: 'Documento / riferimento',
                              hintText: 'es. modulo firmato, email, protocollo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 752,
                          child: TextFormField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salva'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final now = DateTime.now().toIso8601String();

                    final record = ConsensoPrivacy(
                      id: consenso?.id,
                      tipoSoggetto: tipoSoggetto,
                      soggettoId: consenso?.soggettoId,
                      nominativo: nominativoController.text.trim(),
                      codiceFiscale: codiceFiscaleController.text.trim(),
                      email: emailController.text.trim(),
                      telefono: telefonoController.text.trim(),
                      finalita: finalita,
                      baseGiuridica: baseGiuridica,
                      versioneInformativa: versioneInformativaController.text
                          .trim(),
                      canaleRaccolta: canaleRaccolta,
                      stato: stato,
                      dataConsenso: dataConsensoController.text.trim(),
                      dataRevoca: dataRevocaController.text.trim(),
                      dataScadenza: dataScadenzaController.text.trim(),
                      documentoRiferimento: documentoRiferimentoController.text
                          .trim(),
                      note: noteController.text.trim(),
                      createdAt: consenso?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (consenso == null) {
                      await AppDatabase.instance.insertConsensoPrivacy(record);
                    } else {
                      await AppDatabase.instance.updateConsensoPrivacy(record);
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nominativoController.dispose();
    codiceFiscaleController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    versioneInformativaController.dispose();
    dataConsensoController.dispose();
    dataRevocaController.dispose();
    dataScadenzaController.dispose();
    documentoRiferimentoController.dispose();
    noteController.dispose();

    if (salvato == true && mounted) {
      ricaricaConsensi();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro consensi/privacy aggiornato')),
      );
    }
  }

  Future<void> revocaConsenso(ConsensoPrivacy consenso) async {
    if (consenso.id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Revocare il consenso?'),
          content: Text(
            'Il consenso di "${consenso.nominativo}" verrà impostato come REVOCATO.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.block_outlined),
              label: const Text('Revoca'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await AppDatabase.instance.revocaConsensoPrivacy(consenso.id!);

    if (!mounted) return;

    ricaricaConsensi();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consenso revocato')));
  }

  Future<void> eliminaConsenso(ConsensoPrivacy consenso) async {
    if (consenso.id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare il consenso?'),
          content: Text(
            'Il record di "${consenso.nominativo}" verrà eliminato definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await AppDatabase.instance.deleteConsensoPrivacy(consenso.id!);

    if (!mounted) return;

    ricaricaConsensi();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consenso eliminato')));
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'ATTIVO':
        return Colors.green.shade700;
      case 'REVOCATO':
        return Colors.red.shade700;
      case 'SCADUTO':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget badgeStato(String stato) {
    return Chip(
      label: Text(stato, style: const TextStyle(color: Colors.white)),
      backgroundColor: coloreStato(stato),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget cardKpi(String titolo, String valore, IconData icona) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icona),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titolo, style: const TextStyle(fontSize: 12)),
                  Text(
                    valore,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRiepilogo(List<ConsensoPrivacy> consensi) {
    final attivi = consensi
        .where((elemento) => elemento.stato == 'ATTIVO')
        .length;
    final revocati = consensi
        .where((elemento) => elemento.stato == 'REVOCATO')
        .length;
    final scaduti = consensi
        .where((elemento) => elemento.stato == 'SCADUTO')
        .length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        cardKpi('Totale', consensi.length.toString(), Icons.fact_check),
        cardKpi('Attivi', attivi.toString(), Icons.verified_user_outlined),
        cardKpi('Revocati', revocati.toString(), Icons.block_outlined),
        cardKpi('Scaduti', scaduti.toString(), Icons.warning_amber_outlined),
      ],
    );
  }

  Widget buildFiltri() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 380,
          child: TextField(
            controller: ricercaController,
            decoration: InputDecoration(
              labelText: 'Cerca',
              hintText: 'Nominativo, CF/P.IVA, email, finalità, documento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ricercaController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ricercaController.clear();
                        ricaricaConsensi();
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => ricaricaConsensi(),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            key: ValueKey('stato-$filtroStato'),
            initialValue: filtroStato,
            decoration: const InputDecoration(
              labelText: 'Stato',
              border: OutlineInputBorder(),
            ),
            items: statiFiltro
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              filtroStato = value;
              ricaricaConsensi();
            },
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
            key: ValueKey('tipo-$filtroTipoSoggetto'),
            initialValue: filtroTipoSoggetto,
            decoration: const InputDecoration(
              labelText: 'Tipo soggetto',
              border: OutlineInputBorder(),
            ),
            items: tipiSoggettoFiltro
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              filtroTipoSoggetto = value;
              ricaricaConsensi();
            },
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Azzera filtro'),
          onPressed: () {
            ricercaController.clear();
            filtroStato = 'Tutti';
            filtroTipoSoggetto = 'Tutti';
            ricaricaConsensi();
          },
        ),
      ],
    );
  }

  Widget buildTabella(List<ConsensoPrivacy> consensi) {
    if (consensi.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nessun consenso/privacy presente.')),
        ),
      );
    }

    return Card(
      child: Scrollbar(
        controller: tabellaOrizzontaleController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: tabellaOrizzontaleController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 46,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 58,
            columns: const [
              DataColumn(label: Text('Data consenso')),
              DataColumn(label: Text('Soggetto')),
              DataColumn(label: Text('Nominativo')),
              DataColumn(label: Text('Finalità')),
              DataColumn(label: Text('Base giuridica')),
              DataColumn(label: Text('Informativa')),
              DataColumn(label: Text('Canale')),
              DataColumn(label: Text('Stato')),
              DataColumn(label: Text('Revoca')),
              DataColumn(label: Text('Azioni')),
            ],
            rows: consensi.map((consenso) {
              DataCell cellaDettaglio(Widget child) {
                return DataCell(
                  child,
                  onDoubleTap: () => mostraDettaglioConsensoPrivacy(consenso),
                );
              }

              return DataRow(
                cells: [
                  cellaDettaglio(Text(consenso.dataConsenso)),
                  cellaDettaglio(Text(consenso.tipoSoggetto)),
                  cellaDettaglio(
                    SizedBox(
                      width: 240,
                      child: Text(
                        consenso.nominativo,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  cellaDettaglio(
                    SizedBox(
                      width: 280,
                      child: Text(
                        consenso.finalita,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  cellaDettaglio(Text(consenso.baseGiuridica)),
                  cellaDettaglio(Text(consenso.versioneInformativa)),
                  cellaDettaglio(Text(consenso.canaleRaccolta)),
                  cellaDettaglio(badgeStato(consenso.stato)),
                  cellaDettaglio(Text(consenso.dataRevoca)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Dettaglio',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () =>
                              mostraDettaglioConsensoPrivacy(consenso),
                        ),
                        IconButton(
                          tooltip: 'Modifica',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              mostraDialogConsenso(consenso: consenso),
                        ),
                        IconButton(
                          tooltip: 'Revoca',
                          icon: const Icon(Icons.block_outlined),
                          onPressed: consenso.stato == 'REVOCATO'
                              ? null
                              : () => revocaConsenso(consenso),
                        ),
                        IconButton(
                          tooltip: 'Elimina',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => eliminaConsenso(consenso),
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

  Widget buildContenuto(List<ConsensoPrivacy> consensi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registro centralizzato consensi/privacy',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Archivio unico per consensi, informative privacy, finalità, base giuridica, revoche e riferimenti documentali.',
        ),
        const SizedBox(height: 16),
        buildRiepilogo(consensi),
        const SizedBox(height: 16),
        buildFiltri(),
        const SizedBox(height: 16),
        Expanded(child: buildTabella(consensi)),
      ],
    );
  }

  String valoreDettaglioConsensoPrivacy(String valore) {
    final testo = valore.trim();
    return testo.isEmpty ? '—' : testo;
  }

  Widget rigaDettaglioConsensoPrivacy(
    String etichetta,
    String valore, {
    bool evidenziata = false,
  }) {
    final tema = Theme.of(context);
    final testo = valoreDettaglioConsensoPrivacy(valore);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compatto = constraints.maxWidth < 520;

          final label = Text(
            etichetta,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          );

          final contenuto = SelectableText(
            testo,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: evidenziata ? FontWeight.w700 : FontWeight.w400,
            ),
          );

          if (compatto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 3), contenuto],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 190, child: label),
              Expanded(child: contenuto),
            ],
          );
        },
      ),
    );
  }

  Widget sezioneDettaglioConsensoPrivacy(String titolo, List<Widget> righe) {
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...righe,
          ],
        ),
      ),
    );
  }

  void mostraDettaglioConsensoPrivacy(ConsensoPrivacy consenso) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final larghezzaSchermo = MediaQuery.of(dialogContext).size.width;
        final altezzaSchermo = MediaQuery.of(dialogContext).size.height;

        final larghezzaDialog = larghezzaSchermo >= 1100
            ? 900.0
            : larghezzaSchermo >= 760
            ? 720.0
            : larghezzaSchermo * 0.94;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dettaglio consenso/privacy',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: larghezzaDialog,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altezzaSchermo * 0.78),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sezioneDettaglioConsensoPrivacy('Identificazione', [
                      rigaDettaglioConsensoPrivacy(
                        'ID consenso',
                        consenso.id?.toString() ?? '',
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Tipo soggetto',
                        consenso.tipoSoggetto,
                        evidenziata: true,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'ID soggetto collegato',
                        consenso.soggettoId?.toString() ?? '',
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Nominativo',
                        consenso.nominativo,
                        evidenziata: true,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Codice fiscale',
                        consenso.codiceFiscale,
                      ),
                      rigaDettaglioConsensoPrivacy('Email', consenso.email),
                      rigaDettaglioConsensoPrivacy(
                        'Telefono',
                        consenso.telefono,
                      ),
                    ]),
                    sezioneDettaglioConsensoPrivacy(
                      'Consenso e base giuridica',
                      [
                        rigaDettaglioConsensoPrivacy(
                          'Finalità',
                          consenso.finalita,
                          evidenziata: true,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Base giuridica',
                          consenso.baseGiuridica,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Versione informativa',
                          consenso.versioneInformativa,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Canale raccolta',
                          consenso.canaleRaccolta,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Stato',
                          consenso.stato,
                          evidenziata: true,
                        ),
                      ],
                    ),
                    sezioneDettaglioConsensoPrivacy('Date', [
                      rigaDettaglioConsensoPrivacy(
                        'Data consenso',
                        consenso.dataConsenso,
                        evidenziata: true,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Data revoca',
                        consenso.dataRevoca,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Data scadenza',
                        consenso.dataScadenza,
                      ),
                    ]),
                    sezioneDettaglioConsensoPrivacy('Documentazione e note', [
                      rigaDettaglioConsensoPrivacy(
                        'Documento riferimento',
                        consenso.documentoRiferimento,
                      ),
                      rigaDettaglioConsensoPrivacy('Note', consenso.note),
                    ]),
                    sezioneDettaglioConsensoPrivacy('Tracciamento tecnico', [
                      rigaDettaglioConsensoPrivacy(
                        'Creato il',
                        consenso.createdAt,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Ultimo aggiornamento',
                        consenso.updatedAt,
                      ),
                    ]),
                  ],
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro consensi/privacy'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            icon: const Icon(Icons.refresh),
            onPressed: ricaricaConsensi,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuovo consenso'),
        onPressed: () => mostraDialogConsenso(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<ConsensoPrivacy>>(
          future: futureConsensi,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Errore caricamento consensi: ${snapshot.error}'),
              );
            }

            final consensi = snapshot.data ?? [];

            return buildContenuto(consensi);
          },
        ),
      ),
    );
  }
}
