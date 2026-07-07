import 'package:flutter/material.dart';

import '../services/app_database.dart';
import '../widgets/app_action_button.dart';

class MediciStrutturePage extends StatefulWidget {
  const MediciStrutturePage({super.key});

  @override
  State<MediciStrutturePage> createState() => _MediciStrutturePageState();
}

class _MediciStrutturePageState extends State<MediciStrutturePage> {
  final TextEditingController _cercaController = TextEditingController();

  List<Map<String, dynamic>> mediciStrutture = [];
  bool caricamento = true;
  bool soloAttivi = false;

  @override
  void initState() {
    super.initState();
    caricaMediciStrutture();
  }

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  Future<void> caricaMediciStrutture() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getMediciStrutture(
      ricerca: _cercaController.text,
      soloAttivi: soloAttivi,
    );

    if (!mounted) return;

    setState(() {
      mediciStrutture = dati;
      caricamento = false;
    });
  }

  Future<void> apriDialogNuovaVoce() async {
    final risultato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MedicoStrutturaDialog(),
    );

    if (risultato != true) return;

    await caricaMediciStrutture();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Text('Voce medico/struttura salvata.'),
      ),
    );
  }

  Future<void> apriDialogModificaVoce(Map<String, dynamic> voce) async {
    final risultato = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MedicoStrutturaDialog(voce: voce),
    );

    if (risultato != true) return;

    await caricaMediciStrutture();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Text('Voce medico/struttura aggiornata.'),
      ),
    );
  }

  Future<void> cambiaStatoVoce(Map<String, dynamic> voce) async {
    final id = int.parse(voce['id'].toString());
    final attivoAttuale =
        (int.tryParse(voce['attivo']?.toString() ?? '1') ?? 1) == 1;
    final nuovoAttivo = attivoAttuale ? 0 : 1;

    await AppDatabase.instance.aggiornaMedicoStruttura(
      id: id,
      tipo: voce['tipo']?.toString() ?? 'Medico',
      denominazione: voce['denominazione']?.toString() ?? '',
      referente: voce['referente']?.toString(),
      telefono: voce['telefono']?.toString(),
      email: voce['email']?.toString(),
      indirizzo: voce['indirizzo']?.toString(),
      note: voce['note']?.toString(),
      attivo: nuovoAttivo,
    );

    await caricaMediciStrutture();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: nuovoAttivo == 1
            ? const Color(0xFF16A34A)
            : const Color(0xFF64748B),
        content: Text(
          nuovoAttivo == 1
              ? 'Voce medico/struttura riattivata.'
              : 'Voce medico/struttura disattivata.',
        ),
      ),
    );
  }

  Color coloreTipo(String tipo) {
    final tipoNormalizzato = tipo.toLowerCase().trim();

    if (tipoNormalizzato.contains('struttura')) {
      return const Color(0xFF7C3AED);
    }

    return const Color(0xFF2563EB);
  }

  Widget badgeTipo(String tipo) {
    final colore = coloreTipo(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colore.withValues(alpha: 0.25)),
      ),
      child: Text(
        tipo.isEmpty ? 'Medico' : tipo,
        style: TextStyle(
          color: colore,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget badgeAttivo(int attivo) {
    final isAttivo = attivo == 1;
    final colore = isAttivo ? const Color(0xFF16A34A) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colore.withValues(alpha: 0.25)),
      ),
      child: Text(
        isAttivo ? 'ATTIVO' : 'NON ATTIVO',
        style: TextStyle(
          color: colore,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Medici / Strutture mediche'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cercaController,
                    onChanged: (_) => caricaMediciStrutture(),
                    decoration: InputDecoration(
                      hintText:
                          'Cerca medico, struttura, referente, telefono, email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _cercaController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Azzera ricerca',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _cercaController.clear();
                                caricaMediciStrutture();
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  selected: soloAttivi,
                  label: const Text('Solo attivi'),
                  avatar: const Icon(Icons.check_circle_rounded, size: 18),
                  onSelected: (valore) {
                    setState(() {
                      soloAttivi = valore;
                    });
                    caricaMediciStrutture();
                  },
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Crea una nuova voce medico/struttura',
                  child: AppActionButton(
                    type: AppActionButtonType.nuovo,
                    onPressed: apriDialogNuovaVoce,
                    label: 'Nuova voce',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                    : mediciStrutture.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.medical_services_rounded,
                                size: 52,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _cercaController.text.trim().isEmpty
                                    ? 'Nessun medico o struttura presente'
                                    : 'Nessun risultato trovato',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _cercaController.text.trim().isEmpty
                                    ? 'Aggiungi medici competenti o strutture mediche per gestire le visite del lavoro.'
                                    : 'Prova a modificare o azzerare la ricerca.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          columns: const [
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Denominazione')),
                            DataColumn(label: Text('Referente')),
                            DataColumn(label: Text('Telefono')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Note')),
                            DataColumn(label: Text('Stato')),
                            DataColumn(label: Text('Azioni')),
                          ],
                          rows: mediciStrutture.map((voce) {
                            final tipo = voce['tipo']?.toString() ?? 'Medico';
                            final attivo =
                                int.tryParse(
                                  voce['attivo']?.toString() ?? '1',
                                ) ??
                                1;

                            return DataRow(
                              cells: [
                                DataCell(badgeTipo(tipo)),
                                DataCell(
                                  Text(
                                    voce['denominazione']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(voce['referente']?.toString() ?? ''),
                                ),
                                DataCell(
                                  Text(voce['telefono']?.toString() ?? ''),
                                ),
                                DataCell(Text(voce['email']?.toString() ?? '')),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Text(
                                      voce['note']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                DataCell(badgeAttivo(attivo)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Modifica voce',
                                        icon: const Icon(Icons.edit_rounded),
                                        color: const Color(0xFF2563EB),
                                        onPressed: () =>
                                            apriDialogModificaVoce(voce),
                                      ),
                                      IconButton(
                                        tooltip: attivo == 1
                                            ? 'Disattiva voce'
                                            : 'Riattiva voce',
                                        icon: Icon(
                                          attivo == 1
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                        color: attivo == 1
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF16A34A),
                                        onPressed: () => cambiaStatoVoce(voce),
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
        ),
      ),
    );
  }
}

class _MedicoStrutturaDialog extends StatefulWidget {
  final Map<String, dynamic>? voce;

  const _MedicoStrutturaDialog({this.voce});

  @override
  State<_MedicoStrutturaDialog> createState() => _MedicoStrutturaDialogState();
}

class _MedicoStrutturaDialogState extends State<_MedicoStrutturaDialog> {
  final _formKey = GlobalKey<FormState>();

  final _denominazioneController = TextEditingController();
  final _referenteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _indirizzoController = TextEditingController();
  final _noteController = TextEditingController();

  String tipo = 'Medico';
  bool attivo = true;
  bool salvataggio = false;

  @override
  void initState() {
    super.initState();

    final voce = widget.voce;
    if (voce == null) return;

    tipo = voce['tipo']?.toString() ?? 'Medico';
    attivo = (int.tryParse(voce['attivo']?.toString() ?? '1') ?? 1) == 1;

    _denominazioneController.text = voce['denominazione']?.toString() ?? '';
    _referenteController.text = voce['referente']?.toString() ?? '';
    _telefonoController.text = voce['telefono']?.toString() ?? '';
    _emailController.text = voce['email']?.toString() ?? '';
    _indirizzoController.text = voce['indirizzo']?.toString() ?? '';
    _noteController.text = voce['note']?.toString() ?? '';
  }

  @override
  void dispose() {
    _denominazioneController.dispose();
    _referenteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _indirizzoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> salva() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      salvataggio = true;
    });

    try {
      final voce = widget.voce;

      if (voce == null) {
        await AppDatabase.instance.inserisciMedicoStruttura(
          tipo: tipo,
          denominazione: _denominazioneController.text,
          referente: _referenteController.text,
          telefono: _telefonoController.text,
          email: _emailController.text,
          indirizzo: _indirizzoController.text,
          note: _noteController.text,
          attivo: attivo ? 1 : 0,
        );
      } else {
        await AppDatabase.instance.aggiornaMedicoStruttura(
          id: int.parse(voce['id'].toString()),
          tipo: tipo,
          denominazione: _denominazioneController.text,
          referente: _referenteController.text,
          telefono: _telefonoController.text,
          email: _emailController.text,
          indirizzo: _indirizzoController.text,
          note: _noteController.text,
          attivo: attivo ? 1 : 0,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (errore) {
      if (!mounted) return;

      setState(() {
        salvataggio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Errore durante il salvataggio: $errore'),
        ),
      );
    }
  }

  InputDecoration decorazioneCampo(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.voce == null
            ? 'Nuova voce medico/struttura'
            : 'Modifica voce medico/struttura',
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Medico',
                      icon: Icon(Icons.person_rounded),
                      label: Text('Medico'),
                    ),
                    ButtonSegment(
                      value: 'Struttura',
                      icon: Icon(Icons.local_hospital_rounded),
                      label: Text('Struttura'),
                    ),
                  ],
                  selected: {tipo},
                  onSelectionChanged: salvataggio
                      ? null
                      : (valori) {
                          setState(() {
                            tipo = valori.first;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _denominazioneController,
                  enabled: !salvataggio,
                  decoration: decorazioneCampo(
                    tipo == 'Medico'
                        ? 'Nome medico / denominazione'
                        : 'Denominazione struttura',
                    hint: tipo == 'Medico'
                        ? 'Es. Dott. Mario Rossi'
                        : 'Es. Centro Medico Roma',
                  ),
                  validator: (valore) {
                    if (valore == null || valore.trim().isEmpty) {
                      return 'Inserisci la denominazione';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenteController,
                  enabled: !salvataggio,
                  decoration: decorazioneCampo(
                    'Referente',
                    hint: 'Nome referente o contatto interno',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        enabled: !salvataggio,
                        decoration: decorazioneCampo('Telefono'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        enabled: !salvataggio,
                        decoration: decorazioneCampo('Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _indirizzoController,
                  enabled: !salvataggio,
                  decoration: decorazioneCampo('Indirizzo'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  enabled: !salvataggio,
                  minLines: 2,
                  maxLines: 4,
                  decoration: decorazioneCampo('Note'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: attivo,
                  onChanged: salvataggio
                      ? null
                      : (valore) {
                          setState(() {
                            attivo = valore;
                          });
                        },
                  title: const Text('Voce attiva'),
                  subtitle: const Text(
                    'Le voci non attive restano archiviate ma possono essere filtrate.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: salvataggio
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: salvataggio ? null : salva,
          icon: salvataggio
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(salvataggio ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}
