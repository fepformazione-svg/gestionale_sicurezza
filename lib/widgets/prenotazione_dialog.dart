import 'dart:async';

import 'package:flutter/material.dart';

import '../services/database_service.dart';

class PrenotazioneDialog extends StatefulWidget {
  final Map<String, dynamic>? prenotazione;

  const PrenotazioneDialog({super.key, this.prenotazione});

  @override
  State<PrenotazioneDialog> createState() => _PrenotazioneDialogState();
}

class _PrenotazioneDialogState extends State<PrenotazioneDialog> {
  final formKey = GlobalKey<FormState>();

  final dataController = TextEditingController();
  final protController = TextEditingController();
  final noteController = TextEditingController();

  final discenteController = TextEditingController();
  final impresaController = TextEditingController();
  final corsoController = TextEditingController();

  List<Map<String, dynamic>> discenti = [];
  List<Map<String, dynamic>> imprese = [];
  List<Map<String, dynamic>> corsi = [];

  List<Map<String, dynamic>> docenti = [];
  List<Map<String, dynamic>> auleSedi = [];
  List<Map<String, dynamic>> entiAttestati = [];

  List<Map<String, dynamic>> discentiFiltrati = [];
  List<Map<String, dynamic>> impreseFiltrate = [];
  List<Map<String, dynamic>> corsiFiltrati = [];

  int? discenteId;
  int? impresaId;
  int? corsoId;

  int? docenteId;
  int? aulaSedeId;
  int? enteAttestatiId;

  bool aperto = true;
  bool conferma = false;
  bool registro = false;

  bool loading = true;

  Timer? debounceDiscente;
  Timer? debounceImpresa;
  Timer? debounceCorso;

  @override
  void initState() {
    super.initState();
    caricaDati();
  }

  @override
  void dispose() {
    dataController.dispose();
    protController.dispose();
    noteController.dispose();
    discenteController.dispose();
    impresaController.dispose();
    corsoController.dispose();

    debounceDiscente?.cancel();
    debounceImpresa?.cancel();
    debounceCorso?.cancel();

    super.dispose();
  }

  String nomeDiscente(Map<String, dynamic> item) {
    final cognome = (item['cognome'] ?? '').toString().trim();
    final nome = (item['nome'] ?? '').toString().trim();
    return '$cognome $nome'.trim();
  }

  String nomeImpresa(Map<String, dynamic> item) {
    return (item['intestazione'] ?? item['nome'] ?? '').toString();
  }

  String nomeCorso(Map<String, dynamic> item) {
    return (item['denominazione'] ?? item['nome'] ?? '').toString();
  }

  Future<void> caricaDati() async {
    final db = DatabaseService.instance;

    discenti = await db.getDiscentiLookup();
    imprese = await db.getImpreseLookup();
    corsi = await db.getCorsiLookup();

    docenti = await db.getDocentiLookup();
    auleSedi = await db.getAuleSediLookup();
    entiAttestati = await db.getEntiAttestatiLookup();

    if (widget.prenotazione != null) {
      final p = widget.prenotazione!;

      discenteId = p['discente_id'];
      impresaId = p['impresa_id'];
      corsoId = p['corso_id'];

      docenteId = p['docente_id'];
      aulaSedeId = p['aula_sede_id'];
      enteAttestatiId = p['ente_attestato_id'];

      final discenteNome = (p['discente_nome'] ?? '').toString();
      final discenteCognome = (p['discente_cognome'] ?? '').toString();

      discenteController.text = '$discenteCognome $discenteNome'.trim();
      impresaController.text = (p['impresa_nome'] ?? '').toString();
      corsoController.text = (p['corso_nome'] ?? '').toString();

      dataController.text = (p['data'] ?? '').toString();
      protController.text = (p['prot'] ?? '').toString();
      noteController.text = (p['note'] ?? '').toString();

      aperto = p['aperto'] == 1;
      conferma = p['conferma'] == 1;
      registro = p['registro'] == 1;
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void filtraDiscenti(String query) {
    debounceDiscente?.cancel();

    debounceDiscente = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        if (query.trim().isEmpty) {
          discentiFiltrati = [];
          return;
        }

        final ricerca = query.toLowerCase();

        discentiFiltrati = discenti
            .where((d) {
              final testo =
                  '${d['nome'] ?? ''} ${d['cognome'] ?? ''} ${d['nome_impresa'] ?? ''}'
                      .toLowerCase();

              return testo.contains(ricerca);
            })
            .take(8)
            .toList();
      });
    });
  }

  void filtraImprese(String query) {
    debounceImpresa?.cancel();

    debounceImpresa = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        if (query.trim().isEmpty) {
          impreseFiltrate = [];
          return;
        }

        final ricerca = query.toLowerCase();

        impreseFiltrate = imprese
            .where((i) {
              return nomeImpresa(i).toLowerCase().contains(ricerca);
            })
            .take(8)
            .toList();
      });
    });
  }

  void filtraCorsi(String query) {
    debounceCorso?.cancel();

    debounceCorso = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        if (query.trim().isEmpty) {
          corsiFiltrati = [];
          return;
        }

        final ricerca = query.toLowerCase();

        corsiFiltrati = corsi
            .where((c) {
              return nomeCorso(c).toLowerCase().contains(ricerca);
            })
            .take(8)
            .toList();
      });
    });
  }

  Widget buildAutocompleteBox({
    required TextEditingController controller,
    required String label,
    required List<Map<String, dynamic>> risultati,
    required Function(String) onChanged,
    required Function(Map<String, dynamic>) onSelect,
    required String Function(Map<String, dynamic>) getTitle,
    String Function(Map<String, dynamic>)? getSubtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Campo obbligatorio';
            }

            return null;
          },
        ),
        if (risultati.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: risultati.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = risultati[index];
                final subtitle = getSubtitle?.call(item) ?? '';

                return ListTile(
                  dense: true,
                  title: Text(
                    getTitle(item),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  onTap: () => onSelect(item),
                );
              },
            ),
          ),
      ],
    );
  }

  void salva() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'discente_id': discenteId,
      'impresa_id': impresaId,
      'corso_id': corsoId,
      'docente_id': docenteId,
      'aula_sede_id': aulaSedeId,
      'ente_attestato_id': enteAttestatiId,
      'data': dataController.text.trim(),
      'prot': protController.text.trim(),
      'note': noteController.text.trim(),
      'aperto': aperto ? 1 : 0,
      'conferma': conferma ? 1 : 0,
      'registro': registro ? 1 : 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Dialog(
        child: SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 760,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.prenotazione == null
                            ? 'Nuova prenotazione'
                            : 'Modifica prenotazione',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                buildAutocompleteBox(
                  controller: discenteController,
                  label: 'Discente',
                  risultati: discentiFiltrati,
                  onChanged: filtraDiscenti,
                  getTitle: nomeDiscente,
                  getSubtitle: (item) =>
                      (item['nome_impresa'] ?? '').toString(),
                  onSelect: (item) {
                    discenteId = item['id'];
                    impresaId = item['impresa_id'];

                    discenteController.text = nomeDiscente(item);
                    impresaController.text = (item['nome_impresa'] ?? '')
                        .toString();

                    discentiFiltrati = [];

                    setState(() {});
                  },
                ),

                const SizedBox(height: 18),

                buildAutocompleteBox(
                  controller: impresaController,
                  label: 'Impresa',
                  risultati: impreseFiltrate,
                  onChanged: filtraImprese,
                  getTitle: nomeImpresa,
                  onSelect: (item) {
                    impresaId = item['id'];
                    impresaController.text = nomeImpresa(item);

                    impreseFiltrate = [];

                    setState(() {});
                  },
                ),

                const SizedBox(height: 18),

                buildAutocompleteBox(
                  controller: corsoController,
                  label: 'Corso',
                  risultati: corsiFiltrati,
                  onChanged: filtraCorsi,
                  getTitle: nomeCorso,
                  onSelect: (item) {
                    corsoId = item['id'];
                    corsoController.text = nomeCorso(item);

                    corsiFiltrati = [];

                    setState(() {});
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<int?>(
                  initialValue: docenti.any((item) => item['id'] == docenteId)
                      ? docenteId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Docente',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nessun docente selezionato'),
                    ),
                    ...docenti.map((item) {
                      final cognome = (item['cognome'] ?? '').toString();
                      final nome = (item['nome'] ?? '').toString();
                      final testo = '$cognome $nome'.trim();

                      return DropdownMenuItem<int?>(
                        value: item['id'] as int,
                        child: Text(
                          testo.isEmpty ? 'Docente senza nome' : testo,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      docenteId = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<int?>(
                  initialValue: auleSedi.any((item) => item['id'] == aulaSedeId)
                      ? aulaSedeId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Aula/Sede',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nessuna aula/sede selezionata'),
                    ),
                    ...auleSedi.map((item) {
                      final denominazione = (item['denominazione'] ?? '')
                          .toString();
                      final tipo = (item['tipo'] ?? '').toString();
                      final comune = (item['comune'] ?? '').toString();

                      final dettagli = [
                        if (tipo.isNotEmpty) tipo,
                        if (comune.isNotEmpty) comune,
                      ].join(' - ');

                      return DropdownMenuItem<int?>(
                        value: item['id'] as int,
                        child: Text(
                          dettagli.isEmpty
                              ? denominazione
                              : '$denominazione ($dettagli)',
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      aulaSedeId = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<int?>(
                  initialValue:
                      entiAttestati.any((item) => item['id'] == enteAttestatiId)
                      ? enteAttestatiId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Ente attestati',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nessun ente selezionato'),
                    ),
                    ...entiAttestati.map((item) {
                      final denominazione = (item['denominazione'] ?? '')
                          .toString();
                      final tipo = (item['tipo'] ?? '').toString();

                      return DropdownMenuItem<int?>(
                        value: item['id'] as int,
                        child: Text(
                          tipo.isEmpty
                              ? denominazione
                              : '$denominazione ($tipo)',
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      enteAttestatiId = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dataController,
                        decoration: InputDecoration(
                          labelText: 'Data corso',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: protController,
                        decoration: InputDecoration(
                          labelText: 'Protocollo',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilterChip(
                      selected: aperto,
                      label: const Text('Aperto'),
                      onSelected: (value) {
                        setState(() {
                          aperto = value;
                        });
                      },
                    ),
                    FilterChip(
                      selected: conferma,
                      label: const Text('Chiuso'),
                      onSelected: (value) {
                        setState(() {
                          conferma = value;
                        });
                      },
                    ),
                    FilterChip(
                      selected: registro,
                      label: const Text('Registro'),
                      onSelected: (value) {
                        setState(() {
                          registro = value;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Annulla'),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: salva,
                      icon: const Icon(Icons.save),
                      label: const Text('Salva'),
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
