import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/app_database.dart';

class DatiAziendaPage extends StatefulWidget {
  const DatiAziendaPage({super.key});

  @override
  State<DatiAziendaPage> createState() => _DatiAziendaPageState();
}

class _DatiAziendaPageState extends State<DatiAziendaPage> {
  final _formKey = GlobalKey<FormState>();

  final _ragioneSocialeController = TextEditingController();
  final _nomeCommercialeController = TextEditingController();
  final _partitaIvaController = TextEditingController();
  final _codiceFiscaleController = TextEditingController();
  final _indirizzoController = TextEditingController();
  final _capController = TextEditingController();
  final _comuneController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _pecController = TextEditingController();
  final _sitoWebController = TextEditingController();
  final _noteController = TextEditingController();

  bool caricamento = true;
  bool salvataggio = false;

  String? logoPath;

  @override
  void initState() {
    super.initState();
    caricaDatiAzienda();
  }

  @override
  void dispose() {
    _ragioneSocialeController.dispose();
    _nomeCommercialeController.dispose();
    _partitaIvaController.dispose();
    _codiceFiscaleController.dispose();
    _indirizzoController.dispose();
    _capController.dispose();
    _comuneController.dispose();
    _provinciaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _pecController.dispose();
    _sitoWebController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> caricaDatiAzienda() async {
    final dati = await AppDatabase.instance.getDatiAzienda();

    if (!mounted) return;

    if (dati != null) {
      _ragioneSocialeController.text =
          dati['ragione_sociale']?.toString() ?? '';
      _nomeCommercialeController.text =
          dati['nome_commerciale']?.toString() ?? '';
      _partitaIvaController.text = dati['partita_iva']?.toString() ?? '';
      _codiceFiscaleController.text = dati['codice_fiscale']?.toString() ?? '';
      _indirizzoController.text = dati['indirizzo']?.toString() ?? '';
      _capController.text = dati['cap']?.toString() ?? '';
      _comuneController.text = dati['comune']?.toString() ?? '';
      _provinciaController.text = dati['provincia']?.toString() ?? '';
      _telefonoController.text = dati['telefono']?.toString() ?? '';
      _emailController.text = dati['email']?.toString() ?? '';
      _pecController.text = dati['pec']?.toString() ?? '';
      _sitoWebController.text = dati['sito_web']?.toString() ?? '';
      _noteController.text = dati['note']?.toString() ?? '';

      logoPath = dati['logo_path']?.toString();
      if (logoPath != null && logoPath!.trim().isEmpty) {
        logoPath = null;
      }
    }

    setState(() {
      caricamento = false;
    });
  }

  Future<void> salvaDatiAzienda() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      salvataggio = true;
    });

    try {
      await AppDatabase.instance.salvaDatiAzienda(
        ragioneSociale: _ragioneSocialeController.text,
        nomeCommerciale: _nomeCommercialeController.text,
        partitaIva: _partitaIvaController.text,
        codiceFiscale: _codiceFiscaleController.text,
        indirizzo: _indirizzoController.text,
        cap: _capController.text,
        comune: _comuneController.text,
        provincia: _provinciaController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        pec: _pecController.text,
        sitoWeb: _sitoWebController.text,
        logoPath: logoPath,
        note: _noteController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('Dati azienda salvati.'),
        ),
      );
    } catch (errore) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Errore durante il salvataggio: $errore'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvataggio = false;
        });
      }
    }
  }

  Future<void> selezionaLogo() async {
    final risultato = await FilePickerWindows().pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );

    if (risultato == null || risultato.files.single.path == null) return;

    setState(() {
      logoPath = risultato.files.single.path;
    });
  }

  void rimuoviLogo() {
    setState(() {
      logoPath = null;
    });
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

  Widget campoTesto(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !salvataggio,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: decorazioneCampo(label, hint: hint),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dati azienda'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: caricamento
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configurazione aziendale',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Questi dati verranno usati progressivamente in intestazioni, esportazioni, stampe e documenti.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 22),
                            campoTesto(
                              _ragioneSocialeController,
                              'Ragione sociale',
                              hint: 'Es. F&P Formazione e Prevenzione S.r.l.',
                              validator: (valore) {
                                if (valore == null || valore.trim().isEmpty) {
                                  return 'Inserisci la ragione sociale';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            campoTesto(
                              _nomeCommercialeController,
                              'Nome commerciale',
                              hint: 'Es. F&P Formazione e Prevenzione',
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: campoTesto(
                                    _partitaIvaController,
                                    'Partita IVA',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: campoTesto(
                                    _codiceFiscaleController,
                                    'Codice fiscale',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            campoTesto(_indirizzoController, 'Indirizzo'),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: campoTesto(_capController, 'CAP'),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: campoTesto(
                                    _comuneController,
                                    'Comune',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: 130,
                                  child: campoTesto(
                                    _provinciaController,
                                    'Provincia',
                                    hint: 'RM',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: campoTesto(
                                    _telefonoController,
                                    'Telefono',
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: campoTesto(
                                    _emailController,
                                    'Email',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: campoTesto(
                                    _pecController,
                                    'PEC',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: campoTesto(
                                    _sitoWebController,
                                    'Sito web',
                                    hint: 'www.esempio.it',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            campoTesto(_noteController, 'Note', maxLines: 3),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Logo aziendale / marchio',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Il logo verrà usato progressivamente in PDF, stampe e intestazioni. Può essere rimosso per usare il gestionale senza marchio.',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  if (logoPath != null &&
                                      File(logoPath!).existsSync()) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(12),
                                        child: Image.file(
                                          File(logoPath!),
                                          height: 90,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      logoPath!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      height: 90,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: const Text(
                                        'Nessun logo selezionato',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: salvataggio
                                            ? null
                                            : selezionaLogo,
                                        icon: const Icon(Icons.image_rounded),
                                        label: const Text('Seleziona logo'),
                                      ),
                                      if (logoPath != null)
                                        OutlinedButton.icon(
                                          onPressed: salvataggio
                                              ? null
                                              : rimuoviLogo,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          label: const Text('Rimuovi logo'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: salvataggio
                                    ? null
                                    : salvaDatiAzienda,
                                icon: salvataggio
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  salvataggio
                                      ? 'Salvataggio...'
                                      : 'Salva dati azienda',
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
            ),
    );
  }
}
