import 'package:flutter/material.dart';

import '../models/discente.dart';
import '../models/impresa.dart';
import '../services/database_service.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class DiscentiPage extends StatefulWidget {
  final String globalSearch;

  const DiscentiPage({super.key, this.globalSearch = ''});

  @override
  State<DiscentiPage> createState() => _DiscentiPageState();
}

class _DiscentiPageState extends State<DiscentiPage> {
  List<Discente> discenti = [];
  List<Discente> discentiFiltrati = [];
  List<Impresa> imprese = [];

  bool loading = true;
  int? sortColumnIndex;
  bool sortAscending = true;

  int? discenteSelezionatoId;

  @override
  void initState() {
    super.initState();
    caricaDati();
  }

  @override
  void didUpdateWidget(covariant DiscentiPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.globalSearch != widget.globalSearch) {
      cercaDiscenti(widget.globalSearch);
    }
  }

  Future<void> caricaDati() async {
    final datiDiscenti = await DatabaseService.instance.getDiscenti();
    final datiImprese = await DatabaseService.instance.getImprese();

    setState(() {
      discenti = datiDiscenti;
      discentiFiltrati = datiDiscenti;
      imprese = datiImprese;
      loading = false;
    });

    if (widget.globalSearch.trim().isNotEmpty) {
      cercaDiscenti(widget.globalSearch);
    }
  }

  void cercaDiscenti(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        discentiFiltrati = discenti;
        return;
      }

      discentiFiltrati = discenti.where((d) {
        final nome = d.nome.toLowerCase();
        final cognome = d.cognome.toLowerCase();
        final nominativo = d.nominativoCompleto.toLowerCase();
        final luogo = (d.luogoNascita ?? '').toLowerCase();
        final data = (d.dataNascita ?? '').toLowerCase();
        final codiceFiscale = (d.codiceFiscale ?? '').toLowerCase();
        final impresa = (d.nomeImpresa ?? '').toLowerCase();

        return nome.contains(query) ||
            cognome.contains(query) ||
            nominativo.contains(query) ||
            luogo.contains(query) ||
            data.contains(query) ||
            codiceFiscale.contains(query) ||
            impresa.contains(query);
      }).toList();
    });
  }

  void ordinaNominativo(int columnIndex, bool ascending) {
    discentiFiltrati.sort((a, b) {
      final nominativoA = a.nominativoCompleto.toLowerCase();
      final nominativoB = b.nominativoCompleto.toLowerCase();

      final result = nominativoA.compareTo(nominativoB);

      return ascending ? result : -result;
    });

    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }

  Future<void> apriDialogDiscente({Discente? discente}) async {
    final nomeController = TextEditingController(text: discente?.nome ?? '');
    final cognomeController = TextEditingController(
      text: discente?.cognome ?? '',
    );
    final luogoController = TextEditingController(
      text: discente?.luogoNascita ?? '',
    );
    final dataController = TextEditingController(
      text: discente?.dataNascita ?? '',
    );
    final cfController = TextEditingController(
      text: discente?.codiceFiscale ?? '',
    );

    int? impresaId = discente?.impresaId;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 720,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discente == null
                            ? 'Nuovo discente'
                            : 'Modifica discente',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Anagrafica completa del partecipante.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cognomeController,
                              decoration: _inputDecoration('Cognome *'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: nomeController,
                              decoration: _inputDecoration('Nome *'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: luogoController,
                              decoration: _inputDecoration('Luogo di nascita'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: dataController,
                              decoration: _inputDecoration('Data nascita'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: cfController,
                        decoration: _inputDecoration('Codice fiscale'),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<int?>(
                        value: impresaId,
                        decoration: _inputDecoration('Impresa di appartenenza'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Nessuna impresa'),
                          ),
                          ...imprese.map(
                            (impresa) => DropdownMenuItem<int?>(
                              value: impresa.id,
                              child: Text(impresa.nome),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            impresaId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final nome = nomeController.text.trim();
                              final cognome = cognomeController.text.trim();

                              if (nome.isEmpty || cognome.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nome e cognome sono obbligatori',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final nuovoDiscente = Discente(
                                id: discente?.id,
                                nome: nome,
                                cognome: cognome,
                                luogoNascita: luogoController.text.trim(),
                                dataNascita: dataController.text.trim(),
                                codiceFiscale: cfController.text.trim(),
                                impresaId: impresaId,
                              );

                              if (discente == null) {
                                await DatabaseService.instance.insertDiscente(
                                  nuovoDiscente,
                                );
                              } else {
                                await DatabaseService.instance.updateDiscente(
                                  nuovoDiscente,
                                );
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Salva'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nomeController.dispose();
    cognomeController.dispose();
    luogoController.dispose();
    dataController.dispose();
    cfController.dispose();

    if (salvato == true) {
      await caricaDati();
    }
  }

  Future<void> eliminaDiscente(Discente discente) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina discente'),
          content: Text('Vuoi eliminare ${discente.nominativoCompleto}?'),
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

    if (conferma != true || discente.id == null) return;

    await DatabaseService.instance.deleteDiscente(discente.id!);
    await caricaDati();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  String testoVuoto(String? valore) {
    if (valore == null || valore.trim().isEmpty) return '-';
    return valore.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Discenti',
          subtitle: 'Archivio partecipanti, anagrafiche e storico formativo.',
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hintText: 'Cerca per nome, cognome, codice fiscale, impresa...',
                onChanged: cercaDiscenti,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => apriDialogDiscente(),
              icon: const Icon(Icons.add),
              label: const Text('Nuovo discente'),
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
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Archivio Discenti',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Text(
                            '${discentiFiltrati.length} record',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: discentiFiltrati.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nessun discente trovato',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: Colors.white,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      sortColumnIndex: sortColumnIndex,
                                      sortAscending: sortAscending,
                                      headingRowColor: WidgetStateProperty.all(
                                        const Color(0xFFF3F4F6),
                                      ),
                                      dataRowMinHeight: 62,
                                      dataRowMaxHeight: 62,
                                      columnSpacing: 34,
                                      horizontalMargin: 20,
                                      columns: [
                                        const DataColumn(label: Text('')),
                                        DataColumn(
                                          label: const Text('Discente'),
                                          onSort: ordinaNominativo,
                                        ),
                                        const DataColumn(
                                          label: Text('Impresa'),
                                        ),
                                        const DataColumn(
                                          label: Text('Codice fiscale'),
                                        ),
                                        const DataColumn(
                                          label: Text('Data nascita'),
                                        ),
                                        const DataColumn(label: Text('Azioni')),
                                      ],
                                      rows: discentiFiltrati.map((d) {
                                        return DataRow(
                                          color:
                                              WidgetStateProperty.resolveWith<
                                                Color?
                                              >((states) {
                                                if (discenteSelezionatoId ==
                                                    d.id) {
                                                  return const Color(
                                                    0xFFE0ECFF,
                                                  );
                                                }
                                                return null;
                                              }),
                                          cells: [
                                            const DataCell(
                                              Icon(
                                                Icons.person_outline,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            DataCell(
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    discenteSelezionatoId =
                                                        d.id;
                                                  });
                                                },
                                                onDoubleTap: () =>
                                                    apriDialogDiscente(
                                                      discente: d,
                                                    ),
                                                child: Text(
                                                  d.nominativoCompleto,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: const Color(
                                                      0xFF111827,
                                                    ),
                                                    fontWeight:
                                                        discenteSelezionatoId ==
                                                            d.id
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(testoVuoto(d.nomeImpresa)),
                                            ),
                                            DataCell(
                                              Text(testoVuoto(d.codiceFiscale)),
                                            ),
                                            DataCell(
                                              Text(testoVuoto(d.dataNascita)),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    tooltip: 'Modifica',
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                    onPressed: () =>
                                                        apriDialogDiscente(
                                                          discente: d,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Elimina',
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                    onPressed: () =>
                                                        eliminaDiscente(d),
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
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
