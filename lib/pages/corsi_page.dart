import 'package:flutter/material.dart';

import '../models/corso.dart';
import '../services/database_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class CorsiPage extends StatefulWidget {
  const CorsiPage({super.key});

  @override
  State<CorsiPage> createState() => _CorsiPageState();
}

class _CorsiPageState extends State<CorsiPage> {
  List<Corso> corsi = [];
  List<Corso> corsiFiltrati = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    caricaCorsi();
  }

  Future<void> caricaCorsi() async {
    final dati = await DatabaseService.instance.getCorsi();

    setState(() {
      corsi = dati;
      corsiFiltrati = dati;
      loading = false;
    });
  }

  void cercaCorsi(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      corsiFiltrati = corsi.where((c) {
        return c.denominazione
            .toLowerCase()
            .contains(query);
      }).toList();
    });
  }

  Future<void> apriDialogNuovoCorso() async {
    final nomeController = TextEditingController();
    final durataController = TextEditingController();
    final validitaController = TextEditingController();

    final risultato = await showDialog<Corso>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuovo corso',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Inserisci i dati del corso.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Denominazione corso',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            durataController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Durata ore',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: TextField(
                        controller:
                            validitaController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Validità anni',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      child: const Text(
                        'Annulla',
                      ),
                    ),

                    const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        final nome =
                            nomeController.text
                                .trim();

                        if (nome.isEmpty) return;

                        final durata =
                            int.tryParse(
                                  durataController
                                      .text
                                      .trim(),
                                ) ??
                                0;

                        final validita =
                            int.tryParse(
                                  validitaController
                                      .text
                                      .trim(),
                                ) ??
                                0;

                        Navigator.pop(
                          context,
                          Corso(
                            denominazione: nome,
                            durataOre:
                                durata,
                            validitaAnni:
                                validita,
                          ),
                        );
                      },
                      icon:
                          const Icon(Icons.save),
                      label: const Text(
                        'Salva corso',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF2563EB,
                        ),
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    nomeController.dispose();
    durataController.dispose();
    validitaController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance
        .insertCorso(risultato);

    await caricaCorsi();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Corso salvato nel database',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Corsi',
            subtitle:
                'Archivio corsi, formazione e configurazioni didattiche.',
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText:
                      'Cerca corso...',
                  onChanged:
                      cercaCorsi,
                ),
              ),

              const SizedBox(width: 16),

              ElevatedButton.icon(
                onPressed:
                    apriDialogNuovoCorso,
                icon:
                    const Icon(Icons.add),
                label: const Text(
                  'Nuovo corso',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF2563EB,
                  ),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
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
                      child:
                          CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Elenco corsi',
                                style:
                                    TextStyle(
                                  fontSize:
                                      18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color: Color(
                                    0xFF111827,
                                  ),
                                ),
                              ),
                            ),

                            Text(
                              '${corsiFiltrati.length} record',
                              style:
                                  const TextStyle(
                                color: Color(
                                  0xFF6B7280,
                                ),
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        Expanded(
                          child:
                              corsiFiltrati
                                      .isEmpty
                                  ? const Center(
                                      child:
                                          Text(
                                        'Nessun corso presente',
                                        style:
                                            TextStyle(
                                          color:
                                              Color(
                                            0xFF9CA3AF,
                                          ),
                                          fontSize:
                                              15,
                                        ),
                                      ),
                                    )
                                  : ListView
                                      .separated(
                                      itemCount:
                                          corsiFiltrati
                                              .length,
                                      separatorBuilder:
                                          (_, __) =>
                                              const Divider(
                                        height:
                                            1,
                                        color:
                                            Color(
                                          0xFFE5E7EB,
                                        ),
                                      ),
                                      itemBuilder:
                                          (
                                        context,
                                        index,
                                      ) {
                                        final item =
                                            corsiFiltrati[
                                                index];

                                        return Container(
                                          height:
                                              72,
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal:
                                                14,
                                          ),
                                          child:
                                              Row(
                                            children: [
                                              const Icon(
                                                Icons
                                                    .school_outlined,
                                                color:
                                                    Color(0xFF2563EB),
                                              ),

                                              const SizedBox(
                                                width:
                                                    14,
                                              ),

                                              Expanded(
                                                child:
                                                    Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.denominazione,
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            15,
                                                        color:
                                                            Color(0xFF111827),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                      height:
                                                          4,
                                                    ),

                                                    Text(
                                                      'Durata: ${item.durataOre} h • Validità: ${item.validitaAnni} anni',
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            13,
                                                        color:
                                                            Color(0xFF6B7280),
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
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}