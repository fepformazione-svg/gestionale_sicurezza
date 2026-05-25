import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_service.dart';

class ScadenzePage extends StatefulWidget {
  final String filtro;

  const ScadenzePage({
    super.key,
    this.filtro = 'tutte',
  });

  @override
  State<ScadenzePage> createState() => _ScadenzePageState();
}

class _ScadenzePageState extends State<ScadenzePage> {
  final TextEditingController _cercaController =
      TextEditingController();

  List<Map<String, dynamic>> _scadenze = [];
  bool _caricamento = true;

  @override
  void initState() {
    super.initState();
    caricaScadenze();
  }

  Future<void> caricaScadenze() async {
  setState(() {
    _caricamento = true;
  });

  try {
    final dati =
        await DatabaseService.instance.caricaScadenze();

    setState(() {
      _scadenze = dati;
      _caricamento = false;
    });
  } catch (e) {
    debugPrint(
      'ERRORE CARICA SCADENZE: $e',
    );

    setState(() {
      _scadenze = [];
      _caricamento = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore scadenze: $e',
          ),
        ),
      );
    }
  }
}

  String formattaData(dynamic valore) {
  if (valore == null || valore.toString().isEmpty) {
    return '-';
  }

  try {
    final testo = valore.toString();

    DateTime data;

    // SQLITE YYYY-MM-DD
    if (testo.contains('-')) {
      data = DateTime.parse(testo);
    } else {
      return testo;
    }

    return
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  } catch (_) {
    return valore.toString();
  }
}

  String calcolaStato(Map<String, dynamic> riga) {
  final statoDb = riga['stato']?.toString().toUpperCase();

  if (statoDb == 'SCADUTO') {
    return 'Scaduto';
  }

  if (statoDb == 'IN SCADENZA') {
    return 'In scadenza';
  }

  if (statoDb == 'VALIDO') {
    return 'Valido';
  }

  final valore = riga['scadenza'];

  if (valore == null || valore.toString().isEmpty) {
    return 'N/D';
  }

  final scadenza = DateTime.tryParse(
    valore.toString(),
  );

  if (scadenza == null) {
    return 'N/D';
  }

  final oggi = DateTime.now();
  final oggiPulito = DateTime(
    oggi.year,
    oggi.month,
    oggi.day,
  );

  final scadenzaPulita = DateTime(
    scadenza.year,
    scadenza.month,
    scadenza.day,
  );

  final differenza =
      scadenzaPulita.difference(oggiPulito).inDays;

  if (differenza < 0) {
    return 'Scaduto';
  }

  if (differenza <= 90) {
    return 'In scadenza';
  }

  return 'Valido';
}

  Color coloreStato(String stato) {
    switch (stato) {
      case 'Scaduto':
        return Colors.red;

      case 'In scadenza':
        return Colors.orange;

      case 'Valido':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Future<void> rinnovaCorso(
  Map<String, dynamic> riga,
) async {
  final conferma = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Rinnovo corso'),
        content: Text(
          'Vuoi creare un nuovo rinnovo per:\n\n'
          '${riga['discente']}\n'
          '${riga['corso']}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Rinnova'),
          ),
        ],
      );
    },
  );

  if (conferma != true) return;

  await DatabaseService.instance.rinnovaCorso(
    idDiscente: riga['id_discente'],
    idImpresa: riga['id_impresa'],
    idCorso: riga['id_corso'],
  );

  await caricaScadenze();

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Rinnovo creato correttamente',
        ),
      ),
    );
  }
}
List<Map<String, dynamic>> get scadenzeFiltrate {
  final testoRicerca =
      _cercaController.text.toLowerCase();

  return _scadenze.where((riga) {
    final stato = calcolaStato(riga);

    if (widget.filtro == 'scaduti' &&
        stato != 'Scaduto') {
      return false;
    }

    if (widget.filtro == 'in_scadenza' &&
        stato != 'In scadenza') {
      return false;
    }

    final discente =
        riga['discente']
                ?.toString()
                .toLowerCase() ??
            '';

    final impresa =
        riga['impresa']
                ?.toString()
                .toLowerCase() ??
            '';

    final corso =
        riga['corso']
                ?.toString()
                .toLowerCase() ??
            '';

    if (testoRicerca.isNotEmpty &&
        !discente.contains(testoRicerca) &&
        !impresa.contains(testoRicerca) &&
        !corso.contains(testoRicerca)) {
      return false;
    }

    return true;
  }).toList();
}
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Scadenze',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _cercaController,
            decoration: InputDecoration(
              hintText:
                  'Cerca discente, impresa o corso',
              prefixIcon:
                  const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _caricamento
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      itemCount: scadenzeFiltrate.length,
                      itemBuilder: (context, index) {
                        final riga = scadenzeFiltrate[index];
                       
                        final stato =
                            calcolaStato(riga);

                        final colore =
                            coloreStato(stato);

                        return Container(
                          padding:
                              const EdgeInsets.all(
                                  18),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors
                                    .grey.shade200,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  riga['discente']
                                          ?.toString() ??
                                      '-',
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  riga['impresa']
                                          ?.toString() ??
                                      '-',
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  riga['corso']
                                          ?.toString() ??
                                      '-',
                                ),
                              ),

                              Expanded(
                                child: Text(
                                  formattaData(
                                    riga[
                                        'data_corso'],
                                  ),
                                ),
                              ),

                              Expanded(
                                child: Text(
                                  formattaData(
                                    riga[
                                        'scadenza'],
                                  ),
                                ),
                              ),

                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: colore
                                        .withOpacity(
                                            0.12),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                999),
                                  ),
                                  child: Text(
                                    stato,
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        TextStyle(
                                      color: colore,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ),

                              IconButton(
                                onPressed: () {
                                  rinnovaCorso(
                                      riga);
                                },
                                icon: const Icon(
                                  Icons.refresh,
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
    );
  }
}