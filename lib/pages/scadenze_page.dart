import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_service.dart';

class ScadenzePage extends StatefulWidget {
  const ScadenzePage({super.key});

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
      final data = DateTime.parse(valore.toString());

      return DateFormat(
        'dd/MM/yyyy',
        'it_IT',
      ).format(data);
    } catch (_) {
      return valore.toString();
    }
  }

  String calcolaStato(Map<String, dynamic> riga) {
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

    final differenza =
        scadenza.difference(oggi).inDays;

    if (differenza < 0) {
      return 'Scaduto';
    }

    if (differenza <= 60) {
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
    await DatabaseService.instance.rinnovaCorso(
      idDiscente: riga['id_discente'],
      idImpresa: riga['id_impresa'],
      idCorso: riga['id_corso'],
    );

    await caricaScadenze();
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
                      itemCount: _scadenze.length,
                      itemBuilder: (context, index) {
                        final riga =
                            _scadenze[index];

                        final testoRicerca =
                            _cercaController.text
                                .toLowerCase();

                        final discente = riga[
                                    'discente']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                        final impresa = riga[
                                    'impresa']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                        final corso = riga[
                                    'corso']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                        if (testoRicerca
                                .isNotEmpty &&
                            !discente.contains(
                                testoRicerca) &&
                            !impresa.contains(
                                testoRicerca) &&
                            !corso.contains(
                                testoRicerca)) {
                          return const SizedBox();
                        }

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