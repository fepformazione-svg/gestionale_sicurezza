import 'package:flutter/material.dart';
import '../models/prezzario.dart';
import '../services/database_service.dart';

class PrezzarioPage extends StatefulWidget {
  const PrezzarioPage({super.key});

  @override
  State<PrezzarioPage> createState() => _PrezzarioPageState();
}

class _PrezzarioPageState extends State<PrezzarioPage> {
  bool caricamento = true;
  List<Prezzario> vociPrezzario = [];
  List<Map<String, dynamic>> impreseLookup = [];
  List<Map<String, dynamic>> corsiLookup = [];

  @override
  void initState() {
    super.initState();
    caricaPrezzario();
  }

  Future<void> caricaPrezzario() async {
    setState(() {
      caricamento = true;
    });

    final dati = await DatabaseService.instance.getPrezzario();
    final imprese = await DatabaseService.instance.getImpreseLookup();
    final corsi = await DatabaseService.instance.getCorsiLookup();

    if (!mounted) return;

    setState(() {
      vociPrezzario = dati;
      impreseLookup = imprese;
      corsiLookup = corsi;
      caricamento = false;
    });
  }

  String formattaPrezzo(double valore) {
    return '€ ${valore.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> apriDialogNuovaVoce() async {
    final salvato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _NuovaVocePrezzarioDialog(
          impreseLookup: impreseLookup,
          corsiLookup: corsiLookup,
        );
      },
    );

    if (salvato == true) {
      await caricaPrezzario();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voce prezzario salvata.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> apriDialogModificaVoce(Prezzario voce) async {
    final salvato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _ModificaVocePrezzarioDialog(
          voce: voce,
          impreseLookup: impreseLookup,
          corsiLookup: corsiLookup,
        );
      },
    );

    if (salvato == true) {
      await caricaPrezzario();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voce prezzario aggiornata.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> confermaEliminaVoce(Prezzario voce) async {
    if (voce.id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare voce prezzario?'),
          content: Text(
            'Vuoi eliminare la voce per "${voce.impresa ?? '-'}" - "${voce.corso ?? '-'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await DatabaseService.instance.deletePrezzario(voce.id!);

    await caricaPrezzario();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voce prezzario eliminata.'),
        backgroundColor: Color(0xFF475569),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.price_change_rounded,
              color: Color(0xFF0F172A),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Prezzario',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: apriDialogNuovaVoce,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuova voce'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: caricaPrezzario,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Aggiorna'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Prezzi personalizzati per impresa e corso.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
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
                : vociPrezzario.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.price_check_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nessuna voce di prezzario presente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Aggiungeremo inserimento e modifica nel prossimo step.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF1F5F9),
                      ),
                      columns: const [
                        DataColumn(label: Text('Impresa')),
                        DataColumn(label: Text('Corso')),
                        DataColumn(label: Text('Prezzo')),
                        DataColumn(label: Text('Note')),
                        DataColumn(label: Text('Azioni')),
                      ],
                      rows: vociPrezzario.map((voce) {
                        return DataRow(
                          cells: [
                            DataCell(Text(voce.impresa ?? '-')),
                            DataCell(Text(voce.corso ?? '-')),
                            DataCell(Text(formattaPrezzo(voce.prezzo))),
                            DataCell(Text(voce.note.isEmpty ? '-' : voce.note)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Modifica voce prezzario',
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                    ),
                                    color: const Color(0xFF475569),
                                    onPressed: () {
                                      apriDialogModificaVoce(voce);
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Elimina voce prezzario',
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                    ),
                                    color: const Color(0xFFDC2626),
                                    onPressed: () {
                                      confermaEliminaVoce(voce);
                                    },
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
      ],
    );
  }
}

class _NuovaVocePrezzarioDialog extends StatefulWidget {
  final List<Map<String, dynamic>> impreseLookup;
  final List<Map<String, dynamic>> corsiLookup;

  const _NuovaVocePrezzarioDialog({
    required this.impreseLookup,
    required this.corsiLookup,
  });

  @override
  State<_NuovaVocePrezzarioDialog> createState() =>
      _NuovaVocePrezzarioDialogState();
}

class _NuovaVocePrezzarioDialogState extends State<_NuovaVocePrezzarioDialog> {
  int? impresaId;
  int? corsoId;
  bool salvataggioInCorso = false;
  String? errore;

  final prezzoController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void dispose() {
    prezzoController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> salvaVoce() async {
    if (salvataggioInCorso) return;

    setState(() {
      errore = null;
    });

    if (impresaId == null || corsoId == null) {
      setState(() {
        errore = 'Seleziona impresa e corso.';
      });
      return;
    }

    final prezzo = double.tryParse(
      prezzoController.text.trim().replaceAll(',', '.'),
    );

    if (prezzo == null || prezzo < 0) {
      setState(() {
        errore = 'Inserisci un prezzo valido.';
      });
      return;
    }

    setState(() {
      salvataggioInCorso = true;
    });

    try {
      final esistente = await DatabaseService.instance
          .getPrezzarioByImpresaCorso(impresaId: impresaId!, corsoId: corsoId!);

      if (!mounted) return;

      if (esistente != null) {
        setState(() {
          errore = 'Esiste già una voce per questa impresa e questo corso.';
          salvataggioInCorso = false;
        });
        return;
      }

      await DatabaseService.instance.insertPrezzario(
        Prezzario(
          impresaId: impresaId!,
          corsoId: corsoId!,
          prezzo: prezzo,
          note: noteController.text.trim(),
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errore = 'Errore durante il salvataggio della voce prezzario.';
        salvataggioInCorso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova voce prezzario'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: impresaId,
              decoration: const InputDecoration(
                labelText: 'Impresa',
                border: OutlineInputBorder(),
              ),
              items: widget.impreseLookup.map((impresa) {
                return DropdownMenuItem<int>(
                  value: impresa['id'] as int,
                  child: Text(
                    (impresa['intestazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        impresaId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: corsoId,
              decoration: const InputDecoration(
                labelText: 'Corso',
                border: OutlineInputBorder(),
              ),
              items: widget.corsiLookup.map((corso) {
                return DropdownMenuItem<int>(
                  value: corso['id'] as int,
                  child: Text(
                    (corso['denominazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        corsoId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prezzoController,
              enabled: !salvataggioInCorso,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Prezzo',
                hintText: 'Es. 120,00',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              enabled: !salvataggioInCorso,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            if (errore != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errore!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvataggioInCorso
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: salvataggioInCorso ? null : salvaVoce,
          icon: salvataggioInCorso
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(salvataggioInCorso ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}

class _ModificaVocePrezzarioDialog extends StatefulWidget {
  final Prezzario voce;
  final List<Map<String, dynamic>> impreseLookup;
  final List<Map<String, dynamic>> corsiLookup;

  const _ModificaVocePrezzarioDialog({
    required this.voce,
    required this.impreseLookup,
    required this.corsiLookup,
  });

  @override
  State<_ModificaVocePrezzarioDialog> createState() =>
      _ModificaVocePrezzarioDialogState();
}

class _ModificaVocePrezzarioDialogState
    extends State<_ModificaVocePrezzarioDialog> {
  late int? impresaId;
  late int? corsoId;
  bool salvataggioInCorso = false;
  String? errore;

  late final TextEditingController prezzoController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    impresaId = widget.voce.impresaId;
    corsoId = widget.voce.corsoId;
    prezzoController = TextEditingController(
      text: widget.voce.prezzo.toStringAsFixed(2).replaceAll('.', ','),
    );
    noteController = TextEditingController(text: widget.voce.note);
  }

  @override
  void dispose() {
    prezzoController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> salvaVoce() async {
    if (salvataggioInCorso) return;

    setState(() {
      errore = null;
    });

    if (impresaId == null || corsoId == null) {
      setState(() {
        errore = 'Seleziona impresa e corso.';
      });
      return;
    }

    final prezzo = double.tryParse(
      prezzoController.text.trim().replaceAll(',', '.'),
    );

    if (prezzo == null || prezzo < 0) {
      setState(() {
        errore = 'Inserisci un prezzo valido.';
      });
      return;
    }

    setState(() {
      salvataggioInCorso = true;
    });

    try {
      final combinazioneCambiata =
          impresaId != widget.voce.impresaId || corsoId != widget.voce.corsoId;

      if (combinazioneCambiata) {
        final esistente = await DatabaseService.instance
            .getPrezzarioByImpresaCorso(
              impresaId: impresaId!,
              corsoId: corsoId!,
            );

        if (!mounted) return;

        if (esistente != null && esistente.id != widget.voce.id) {
          setState(() {
            errore = 'Esiste già una voce per questa impresa e questo corso.';
            salvataggioInCorso = false;
          });
          return;
        }
      }

      await DatabaseService.instance.updatePrezzario(
        widget.voce.copyWith(
          impresaId: impresaId,
          corsoId: corsoId,
          prezzo: prezzo,
          note: noteController.text.trim(),
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errore = 'Errore durante l’aggiornamento della voce prezzario.';
        salvataggioInCorso = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica voce prezzario'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: impresaId,
              decoration: const InputDecoration(
                labelText: 'Impresa',
                border: OutlineInputBorder(),
              ),
              items: widget.impreseLookup.map((impresa) {
                return DropdownMenuItem<int>(
                  value: impresa['id'] as int,
                  child: Text(
                    (impresa['intestazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        impresaId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: corsoId,
              decoration: const InputDecoration(
                labelText: 'Corso',
                border: OutlineInputBorder(),
              ),
              items: widget.corsiLookup.map((corso) {
                return DropdownMenuItem<int>(
                  value: corso['id'] as int,
                  child: Text(
                    (corso['denominazione'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: salvataggioInCorso
                  ? null
                  : (value) {
                      setState(() {
                        corsoId = value;
                        errore = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prezzoController,
              enabled: !salvataggioInCorso,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Prezzo',
                hintText: 'Es. 120,00',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              enabled: !salvataggioInCorso,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            if (errore != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  errore!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvataggioInCorso
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: salvataggioInCorso ? null : salvaVoce,
          icon: salvataggioInCorso
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(salvataggioInCorso ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}
