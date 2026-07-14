import 'package:flutter/material.dart';

import '../models/corso.dart';
import '../models/corso_piattaforma.dart';
import '../services/database_service.dart';

class CorsoPiattaformeDialog extends StatefulWidget {
  final Corso corso;

  const CorsoPiattaformeDialog({super.key, required this.corso});

  @override
  State<CorsoPiattaformeDialog> createState() => _CorsoPiattaformeDialogState();
}

class _CorsoPiattaformeDialogState extends State<CorsoPiattaformeDialog> {
  List<CorsoPiattaforma> collegamenti = [];
  bool caricamento = true;
  bool modificato = false;

  int? get corsoId => widget.corso.id;

  @override
  void initState() {
    super.initState();
    caricaCollegamenti();
  }

  Future<void> caricaCollegamenti() async {
    final id = corsoId;

    if (id == null) {
      if (!mounted) return;

      setState(() {
        collegamenti = [];
        caricamento = false;
      });

      return;
    }

    final dati = await DatabaseService.instance.getCorsoPiattaforme(
      corsoId: id,
    );

    if (!mounted) return;

    setState(() {
      collegamenti = dati;
      caricamento = false;
    });
  }

  Future<void> apriEditor({CorsoPiattaforma? collegamento}) async {
    final idCorso = corsoId;

    if (idCorso == null) return;

    final piattaformaController = TextEditingController(
      text: collegamento?.piattaforma ?? '',
    );
    final codiceController = TextEditingController(
      text: collegamento?.codice ?? '',
    );
    final noteController = TextEditingController(
      text: collegamento?.note ?? '',
    );

    var attivo = collegamento?.attivo ?? true;
    String? errore;

    final risultato = await showDialog<CorsoPiattaforma>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                collegamento == null
                    ? 'Nuovo codice piattaforma'
                    : 'Modifica codice piattaforma',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: piattaformaController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Piattaforma',
                          hintText: 'Es. Mega Italia, AiFOS, Moodle',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codiceController,
                        decoration: const InputDecoration(
                          labelText: 'Codice corso',
                          hintText: 'Codice utilizzato sulla piattaforma',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'Informazioni facoltative',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Codice attivo'),
                        subtitle: const Text(
                          'Disattiva il codice per conservarlo come storico.',
                        ),
                        value: attivo,
                        onChanged: (valore) {
                          setDialogState(() {
                            attivo = valore;
                          });
                        },
                      ),
                      if (errore != null) ...[
                        const SizedBox(height: 8),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final piattaforma = piattaformaController.text.trim();
                    final codice = codiceController.text.trim();

                    if (piattaforma.isEmpty || codice.isEmpty) {
                      setDialogState(() {
                        errore = 'Piattaforma e codice corso sono obbligatori.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      CorsoPiattaforma(
                        id: collegamento?.id,
                        corsoId: idCorso,
                        piattaforma: piattaforma,
                        codice: codice,
                        note: noteController.text.trim(),
                        attivo: attivo,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );

    piattaformaController.dispose();
    codiceController.dispose();
    noteController.dispose();

    if (risultato == null) return;

    try {
      if (collegamento == null) {
        await DatabaseService.instance.insertCorsoPiattaforma(risultato);
      } else {
        await DatabaseService.instance.updateCorsoPiattaforma(risultato);
      }

      modificato = true;
      await caricaCollegamenti();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossibile salvare: verifica che lo stesso codice non sia già presente.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> cambiaStato(CorsoPiattaforma collegamento, bool attivo) async {
    try {
      await DatabaseService.instance.updateCorsoPiattaforma(
        collegamento.copyWith(attivo: attivo),
      );

      modificato = true;
      await caricaCollegamenti();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aggiornare lo stato del codice.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> eliminaCollegamento(CorsoPiattaforma collegamento) async {
    final id = collegamento.id;

    if (id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare il codice?'),
          content: Text(
            'Vuoi eliminare definitivamente il codice '
            '"${collegamento.codice}" della piattaforma '
            '"${collegamento.piattaforma}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (conferma != true) return;

    await DatabaseService.instance.deleteCorsoPiattaforma(id);

    modificato = true;
    await caricaCollegamenti();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.hub_outlined,
                    color: Color(0xFF2563EB),
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Piattaforme e codici',
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
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: corsoId == null ? null : () => apriEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi codice'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : collegamenti.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun codice piattaforma configurato.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: collegamenti.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final collegamento = collegamenti[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            leading: Icon(
                              collegamento.attivo
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              color: collegamento.attivo
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFF59E0B),
                            ),
                            title: Text(
                              collegamento.piattaforma,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: collegamento.attivo
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                SelectableText(
                                  'Codice: ${collegamento.codice}',
                                ),
                                if ((collegamento.note ?? '').trim().isNotEmpty)
                                  Text(
                                    collegamento.note!.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: collegamento.attivo
                                      ? 'Disattiva codice'
                                      : 'Riattiva codice',
                                  child: Switch(
                                    value: collegamento.attivo,
                                    onChanged: (valore) {
                                      cambiaStato(collegamento, valore);
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: 'Modifica codice',
                                  child: IconButton(
                                    onPressed: () =>
                                        apriEditor(collegamento: collegamento),
                                    icon: const Icon(Icons.edit_outlined),
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Elimina codice',
                                  child: IconButton(
                                    onPressed: () =>
                                        eliminaCollegamento(collegamento),
                                    icon: const Icon(Icons.delete_outline),
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, modificato);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Chiudi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
