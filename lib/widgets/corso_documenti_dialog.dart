import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../models/corso.dart';
import '../services/database_service.dart';

class CorsoDocumentiDialog extends StatefulWidget {
  final Corso corso;

  const CorsoDocumentiDialog({super.key, required this.corso});

  @override
  State<CorsoDocumentiDialog> createState() => _CorsoDocumentiDialogState();
}

class _CorsoDocumentiDialogState extends State<CorsoDocumentiDialog> {
  String? modelloTestWordPath;
  String? modelloGradimentoWordPath;

  bool salvataggio = false;
  bool modificato = false;

  @override
  void initState() {
    super.initState();

    modelloTestWordPath = widget.corso.modelloTestWordPath;
    modelloGradimentoWordPath = widget.corso.modelloGradimentoWordPath;
  }

  Future<void> selezionaModello({required bool test}) async {
    final risultato = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      allowMultiple: false,
    );

    if (risultato == null || risultato.files.single.path == null) {
      return;
    }

    final percorso = risultato.files.single.path!.trim();

    if (percorso.isEmpty) return;

    await aggiornaPercorso(test: test, percorso: percorso);
  }

  Future<void> aggiornaPercorso({
    required bool test,
    required String? percorso,
  }) async {
    if (salvataggio) return;

    if (widget.corso.id == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossibile salvare i modelli: il corso non ha un ID.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );

      return;
    }

    final nuovoTestPath = test ? percorso : modelloTestWordPath;

    final nuovoGradimentoPath = test ? modelloGradimentoWordPath : percorso;

    final corsoAggiornato = Corso(
      id: widget.corso.id,
      denominazione: widget.corso.denominazione,
      durataOre: widget.corso.durataOre,
      validitaAnni: widget.corso.validitaAnni,
      modelloTestWordPath: nuovoTestPath,
      modelloGradimentoWordPath: nuovoGradimentoPath,
    );

    setState(() {
      salvataggio = true;
    });

    try {
      await DatabaseService.instance.updateCorso(corsoAggiornato);

      if (!mounted) return;

      setState(() {
        modelloTestWordPath = nuovoTestPath;
        modelloGradimentoWordPath = nuovoGradimentoPath;
        modificato = true;
        salvataggio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            percorso == null
                ? 'Modello Word rimosso.'
                : 'Modello Word salvato.',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        salvataggio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il salvataggio del modello Word.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> apriModello(String percorso) async {
    final file = File(percorso);

    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il file Word associato non è stato trovato.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );

      return;
    }

    await OpenFile.open(percorso);
  }

  Future<void> rimuoviModello({required bool test}) async {
    final percorso = test ? modelloTestWordPath : modelloGradimentoWordPath;

    if (percorso == null || percorso.trim().isEmpty) {
      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rimuovere il modello?'),
          content: Text(
            test
                ? 'Vuoi rimuovere il modello Word associato al Test?'
                : 'Vuoi rimuovere il modello Word associato al Gradimento?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Rimuovi'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await aggiornaPercorso(test: test, percorso: null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 30,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modelli documenti corso',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.corso.denominazione,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  if (salvataggio) ...[
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),

              _DocumentoSection(
                titolo: 'Modello Test',
                descrizione:
                    'Documento Word utilizzato come modello '
                    'per il test del corso.',
                icona: Icons.quiz_outlined,
                percorso: modelloTestWordPath,
                disabilitato: salvataggio,
                onSeleziona: () => selezionaModello(test: true),
                onApri: modelloTestWordPath == null
                    ? null
                    : () => apriModello(modelloTestWordPath!),
                onRimuovi: modelloTestWordPath == null
                    ? null
                    : () => rimuoviModello(test: true),
              ),

              const SizedBox(height: 16),

              _DocumentoSection(
                titolo: 'Modello Gradimento',
                descrizione:
                    'Documento Word utilizzato come modello '
                    'per il questionario di gradimento.',
                icona: Icons.rate_review_outlined,
                percorso: modelloGradimentoWordPath,
                disabilitato: salvataggio,
                onSeleziona: () => selezionaModello(test: false),
                onApri: modelloGradimentoWordPath == null
                    ? null
                    : () => apriModello(modelloGradimentoWordPath!),
                onRimuovi: modelloGradimentoWordPath == null
                    ? null
                    : () => rimuoviModello(test: false),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: salvataggio
                      ? null
                      : () => Navigator.pop(context, modificato),
                  icon: const Icon(Icons.close),
                  label: const Text('Chiudi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentoSection extends StatelessWidget {
  final String titolo;
  final String descrizione;
  final IconData icona;
  final String? percorso;
  final bool disabilitato;
  final VoidCallback onSeleziona;
  final VoidCallback? onApri;
  final VoidCallback? onRimuovi;

  const _DocumentoSection({
    required this.titolo,
    required this.descrizione,
    required this.icona,
    required this.percorso,
    required this.disabilitato,
    required this.onSeleziona,
    required this.onApri,
    required this.onRimuovi,
  });

  @override
  Widget build(BuildContext context) {
    final percorsoPulito = percorso?.trim() ?? '';
    final associato = percorsoPulito.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icona, color: const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titolo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descrizione,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 10),
                Text(
                  associato ? percorsoPulito : 'Nessun modello associato.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: associato
                        ? const Color(0xFF374151)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: disabilitato ? null : onSeleziona,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(associato ? 'Sostituisci' : 'Seleziona'),
                    ),
                    if (associato)
                      OutlinedButton.icon(
                        onPressed: disabilitato ? null : onApri,
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('Apri'),
                      ),
                    if (associato)
                      TextButton.icon(
                        onPressed: disabilitato ? null : onRimuovi,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Rimuovi'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
