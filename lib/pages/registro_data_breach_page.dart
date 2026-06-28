import 'package:flutter/material.dart';

import '../models/data_breach.dart';
import '../services/app_database.dart';

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
                            width: 1450,
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
                                        width: 130,
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
                                                width: 130,
                                                child: Row(
                                                  children: [
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
