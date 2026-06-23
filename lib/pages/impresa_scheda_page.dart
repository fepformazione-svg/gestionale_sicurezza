import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/discente.dart';
import '../models/impresa.dart';
import '../services/database_service.dart';
import 'discente_scheda_page.dart';
import '../dialogs/discente_dialog.dart' as dialog_discente;
import '../services/app_database.dart';
import '../utils/pdf_azienda_helper.dart';

class ImpresaSchedaPage extends StatefulWidget {
  final Impresa impresa;

  const ImpresaSchedaPage({super.key, required this.impresa});

  @override
  State<ImpresaSchedaPage> createState() => _ImpresaSchedaPageState();
}

class _ImpresaSchedaPageState extends State<ImpresaSchedaPage> {
  String? documentoPrivacyImpresaPath;
  List<Discente> discentiAssociati = [];
  bool schedaModificata = false;

  late bool privacyImpresaFirmata;
  String? dataFirmaPrivacyImpresa;
  String? notePrivacyImpresa;

  @override
  void initState() {
    super.initState();

    privacyImpresaFirmata =
        widget.impresa.informativaPrivacyImpresaFirmata == 1;
    dataFirmaPrivacyImpresa = widget.impresa.dataFirmaInformativaPrivacyImpresa;
    notePrivacyImpresa = widget.impresa.notePrivacyImpresa;
    documentoPrivacyImpresaPath = widget.impresa.documentoPrivacyImpresaPath;

    caricaDiscentiAssociati();
  }

  Future<void> apriDialogPrivacyImpresa() async {
    bool firmata = privacyImpresaFirmata;

    final dataController = TextEditingController(
      text: dataFirmaPrivacyImpresa ?? '',
    );

    final noteController = TextEditingController(
      text: notePrivacyImpresa ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Gestione Privacy / GDPR impresa'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Informativa privacy impresa firmata'),
                      value: firmata,
                      onChanged: (value) {
                        setDialogState(() {
                          firmata = value;
                          if (!firmata) {
                            dataController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dataController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Data firma',
                        prefixIcon: const Icon(Icons.event),
                        suffixIcon: dataController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Svuota data',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    dataController.clear();
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final oggi = DateTime.now();

                        final dataSelezionata = await showDatePicker(
                          context: dialogContext,
                          initialDate: oggi,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (dataSelezionata != null) {
                          final giorno = dataSelezionata.day.toString().padLeft(
                            2,
                            '0',
                          );
                          final mese = dataSelezionata.month.toString().padLeft(
                            2,
                            '0',
                          );
                          final anno = dataSelezionata.year.toString();

                          setDialogState(() {
                            dataController.text = '$giorno/$mese/$anno';
                            firmata = true;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note privacy impresa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                  onPressed: () async {
                    await AppDatabase.instance.aggiornaPrivacyImpresa(
                      impresaId: widget.impresa.id!,
                      informativaPrivacyImpresaFirmata: firmata,
                      dataFirmaInformativaPrivacyImpresa:
                          dataController.text.trim().isEmpty
                          ? null
                          : dataController.text.trim(),
                      notePrivacyImpresa: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;
                    if (!mounted) return;

                    setState(() {
                      privacyImpresaFirmata = firmata;
                      dataFirmaPrivacyImpresa =
                          dataController.text.trim().isEmpty
                          ? null
                          : dataController.text.trim();
                      notePrivacyImpresa = noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim();
                      schedaModificata = true;
                    });

                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dati Privacy/GDPR impresa aggiornati.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    dataController.dispose();
    noteController.dispose();
  }

  Future<void> caricaDiscentiAssociati() async {
    final idImpresa = widget.impresa.id;
    if (idImpresa == null) return;

    final risultato = await DatabaseService.instance.getDiscentiByImpresaId(
      idImpresa,
    );

    if (!mounted) return;

    setState(() {
      discentiAssociati = risultato;
    });
  }

  String valore(String? testo) {
    final v = testo?.trim() ?? '';
    return v.isEmpty ? '-' : v;
  }

  DateTime? parseData(String? data) {
    if (data == null || data.trim().isEmpty) return null;

    try {
      final parti = data.split('/');
      if (parti.length == 3) {
        return DateTime(
          int.parse(parti[2]),
          int.parse(parti[1]),
          int.parse(parti[0]),
        );
      }

      return DateTime.tryParse(data);
    } catch (_) {
      return null;
    }
  }

  String statoVisitaMedica(Discente discente) {
    if (discente.visitaMedicaSvolta != 1) {
      return 'Non svolta';
    }

    final scadenza = parseData(discente.scadenzaVisitaMedica);

    if (scadenza == null) {
      return 'Senza scadenza';
    }

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(
      scadenza.year,
      scadenza.month,
      scadenza.day,
    );

    if (scadenzaPulita.isBefore(oggiPulito)) {
      return 'Scaduta';
    }

    final giorniMancanti = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorniMancanti <= 60) {
      return 'In scadenza';
    }

    return 'Valida';
  }

  Color coloreStatoVisita(String stato) {
    switch (stato) {
      case 'Valida':
        return const Color(0xFF16A34A);
      case 'In scadenza':
        return const Color(0xFFF59E0B);
      case 'Scaduta':
      case 'Non svolta':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void modificaImpresa(BuildContext context) {
    Navigator.pop(context, 'modifica');
  }

  Future<void> eliminaImpresa(BuildContext context) async {
    final idImpresa = widget.impresa.id;

    if (idImpresa == null) return;

    final haCollegamenti = await DatabaseService.instance.impresaHaCollegamenti(
      idImpresa,
    );

    if (!context.mounted) return;

    if (haCollegamenti) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Eliminazione non consentita'),
            content: const Text(
              'Questa impresa non può essere eliminata perché è collegata a discenti, prenotazioni o storico diario.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina impresa'),
          content: Text(
            'Vuoi eliminare definitivamente ${widget.impresa.intestazione}?',
          ),
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

    if (conferma != true) return;

    await DatabaseService.instance.deleteImpresa(idImpresa);

    if (!context.mounted) return;

    Navigator.pop(context, 'eliminata');
  }

  Future<void> apriSchedaDiscente(Discente discente) async {
    final risultato = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscenteSchedaPage(discente: discente)),
    );

    if (risultato == 'modifica') {
      await apriDialogDiscenteDaSchedaImpresa(discente: discente);
    }

    await caricaDiscentiAssociati();
  }

  Future<void> apriDialogDiscenteDaSchedaImpresa({Discente? discente}) async {
    final salvato = await dialog_discente.apriDialogDiscente(
      context: context,
      discente: discente,
      impresaIdPreselezionata: widget.impresa.id,
    );

    if (salvato) {
      await caricaDiscentiAssociati();
    }
  }

  @override
  Widget build(BuildContext context) {
    final impresa = widget.impresa;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Torna alle imprese',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, schedaModificata ? 'aggiorna' : null);
          },
        ),
        title: const Text('Scheda impresa'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Modifica impresa',
            onPressed: () => modificaImpresa(context),
            icon: const Icon(Icons.edit_outlined),
          ),

          IconButton(
            tooltip: 'Elimina impresa',
            onPressed: () => eliminaImpresa(context),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                impresa.intestazione,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anagrafica aziendale',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),
              _InfoRiga(
                label: 'Partita IVA',
                value: valore(impresa.partitaIva),
              ),
              _InfoRiga(
                label: 'Codice fiscale',
                value: valore(impresa.codiceFiscale),
              ),
              _InfoRiga(label: 'Referente', value: valore(impresa.referente)),
              _InfoRiga(label: 'Telefono', value: valore(impresa.telefono)),
              _InfoRiga(label: 'Indirizzo', value: valore(impresa.indirizzo)),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Privacy / GDPR impresa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data firma: ${valore(dataFirmaPrivacyImpresa)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            documentoPrivacyImpresaPath == null ||
                                    documentoPrivacyImpresaPath!.trim().isEmpty
                                ? 'Documento privacy: non collegato'
                                : 'Documento privacy: ${p.basename(documentoPrivacyImpresaPath!)}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: generaInformativaPrivacyImpresaPdf,
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 18,
                                ),
                                label: const Text('Genera informativa'),
                              ),
                              OutlinedButton.icon(
                                onPressed: allegaDocumentoPrivacyImpresa,
                                icon: const Icon(Icons.attach_file, size: 18),
                                label: const Text('Allega documento'),
                              ),
                              if (documentoPrivacyImpresaPath != null &&
                                  documentoPrivacyImpresaPath!
                                      .trim()
                                      .isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: apriDocumentoPrivacyImpresa,
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: const Text('Apri documento'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: privacyImpresaFirmata
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            privacyImpresaFirmata ? 'FIRMATA' : 'NON FIRMATA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: privacyImpresaFirmata
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Modifica dati Privacy/GDPR impresa',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Color(0xFF2563EB),
                          ),
                          onPressed: apriDialogPrivacyImpresa,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Discenti associati',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      discentiAssociati.length.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  ElevatedButton.icon(
                    onPressed: () => apriDialogDiscenteDaSchedaImpresa(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuovo discente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Expanded(
                child: discentiAssociati.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun discente associato a questa impresa.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: discentiAssociati.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final discente = discentiAssociati[index];
                          final statoVisita = statoVisitaMedica(discente);
                          final coloreVisita = coloreStatoVisita(statoVisita);

                          return InkWell(
                            onDoubleTap: () => apriSchedaDiscente(discente),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          discente.nomeCompleto,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Data visita: ${valore(discente.dataVisitaMedica)}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Scadenza visita: ${valore(discente.scadenzaVisitaMedica)}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: coloreVisita.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                statoVisita,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: coloreVisita,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Modifica discente',
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: Color(0xFF2563EB),
                                        ),
                                        onPressed: () async {
                                          await apriDialogDiscenteDaSchedaImpresa(
                                            discente: discente,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Elimina discente',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Color(0xFFDC2626),
                                        ),
                                        onPressed: () async {
                                          final conferma = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Elimina discente',
                                                ),
                                                content: Text(
                                                  'Vuoi eliminare definitivamente ${discente.nomeCompleto}?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      'Annulla',
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFDC2626,
                                                              ),
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text(
                                                      'Elimina',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (conferma != true) return;

                                          if (discente.id != null) {
                                            await DatabaseService.instance
                                                .deleteDiscente(discente.id!);

                                            await caricaDiscentiAssociati();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> generaInformativaPrivacyImpresaPdf() async {
    if (widget.impresa.id == null) return;

    try {
      final datiAzienda = await caricaIntestazioneAziendaPdf();
      final pdf = pw.Document();

      String valorePdf(String? valore) {
        final testo = valore?.trim();
        if (testo == null || testo.isEmpty) return '-';
        return testo;
      }

      String pulisciNomeFile(String valore) {
        return valore
            .trim()
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
            .replaceAll(RegExp(r'\s+'), '_');
      }

      pw.Widget sezione(String titolo, List<String> righe) {
        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titolo,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 6),
              ...righe.map(
                (riga) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    riga,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final dataDocumento = DateTime.now();
      final dataDocumentoTesto =
          '${dataDocumento.day.toString().padLeft(2, '0')}/'
          '${dataDocumento.month.toString().padLeft(2, '0')}/'
          '${dataDocumento.year}';

      final ragioneSocialeImpresa = valorePdf(widget.impresa.intestazione);
      final partitaIvaImpresa = valorePdf(widget.impresa.partitaIva);
      final codiceFiscaleImpresa = valorePdf(widget.impresa.codiceFiscale);
      final referenteImpresa = valorePdf(widget.impresa.referente);
      final telefonoImpresa = valorePdf(widget.impresa.telefono);
      final indirizzoImpresa = valorePdf(widget.impresa.indirizzo);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          build: (context) => [
            intestazioneAziendaPdfWidget(datiAzienda),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'INFORMATIVA PRIVACY / GDPR IMPRESA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Informativa ai sensi del Regolamento UE 2016/679',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Documento generato il $dataDocumentoTesto',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            sezione('Impresa destinataria', [
              'Ragione sociale: $ragioneSocialeImpresa',
              'Partita IVA: $partitaIvaImpresa',
              'Codice fiscale: $codiceFiscaleImpresa',
              'Referente: $referenteImpresa',
              'Telefono: $telefonoImpresa',
              'Indirizzo: $indirizzoImpresa',
            ]),
            sezione('Premessa', [
              'La presente informativa descrive le modalita con cui F&P tratta i dati personali comunicati dall’impresa cliente nell’ambito della gestione dei rapporti formativi, amministrativi e documentali.',
              'Il trattamento puo riguardare i dati identificativi e di contatto dei referenti aziendali, nonche i dati dei lavoratori/discenti trasmessi dall’impresa per l’organizzazione dei corsi, la gestione delle presenze e il rilascio degli attestati.',
            ]),
            sezione('Finalita del trattamento', [
              'I dati sono trattati per organizzare e gestire le attivita formative richieste dall’impresa cliente.',
              'I dati dei discenti possono essere utilizzati per predisporre registri, attestati, verbali, documentazione didattica e comunicazioni connesse alla formazione in materia di salute e sicurezza sul lavoro.',
              'Quando necessario, i dati dei discenti possono essere comunicati agli enti di rilascio attestati o ad altri soggetti coinvolti nella gestione documentale del corso, limitatamente a quanto necessario per l’emissione e la tracciabilita degli attestati.',
              'I dati possono inoltre essere trattati per adempimenti amministrativi, fiscali, contabili, contrattuali e per la conservazione della documentazione prevista dalla normativa applicabile.',
            ]),
            sezione('Base giuridica', [
              'Il trattamento e effettuato per l’esecuzione del rapporto contrattuale o precontrattuale con l’impresa cliente, per l’adempimento di obblighi di legge e per il legittimo interesse alla corretta gestione documentale e organizzativa delle attivita formative.',
              'La presente informativa non costituisce richiesta di consenso generico, salvo i casi specifici in cui una distinta base giuridica renda necessario acquisire un consenso separato.',
            ]),
            sezione('Categorie di dati trattati', [
              'Possono essere trattati dati anagrafici, dati di contatto, dati aziendali, dati relativi alla mansione o al ruolo, dati relativi alla partecipazione ai corsi, esiti formativi, registri presenze, attestati e altra documentazione strettamente collegata alla formazione.',
              'L’impresa cliente si impegna a comunicare a F&P dati corretti, aggiornati e pertinenti rispetto alle finalita formative richieste.',
            ]),
            sezione('Comunicazione dei dati', [
              'I dati possono essere comunicati a enti di rilascio attestati, docenti, consulenti, collaboratori, fornitori di servizi informatici, soggetti incaricati della gestione amministrativa e altri destinatari autorizzati, nei limiti necessari alla gestione del servizio richiesto.',
              'I dati non sono oggetto di diffusione indiscriminata.',
            ]),
            sezione('Conservazione', [
              'I dati sono conservati per il tempo necessario alla gestione del rapporto, all’emissione e conservazione degli attestati, alla tutela dei diritti delle parti e all’adempimento degli obblighi normativi, amministrativi e fiscali applicabili.',
            ]),
            sezione('Diritti dell’interessato', [
              'Gli interessati possono esercitare i diritti previsti dagli articoli 15 e seguenti del Regolamento UE 2016/679, tra cui accesso, rettifica, cancellazione, limitazione, opposizione e portabilita, nei limiti previsti dalla normativa applicabile.',
              'Per comunicazioni privacy e possibile utilizzare i recapiti indicati da F&P nella propria documentazione aziendale.',
            ]),
            sezione('Dichiarazione dell’impresa cliente', [
              'L’impresa cliente dichiara di aver ricevuto la presente informativa e di essere consapevole che i dati dei propri lavoratori/discenti potranno essere trattati da F&P per le finalita formative, documentali e amministrative sopra descritte.',
              'L’impresa cliente si impegna, ove necessario, a rendere ai propri lavoratori/discenti le informazioni opportune in merito alla comunicazione dei dati a F&P per la gestione dei corsi e degli attestati.',
            ]),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Luogo e data',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(height: 1, color: PdfColors.grey500),
                    ],
                  ),
                ),
                pw.SizedBox(width: 32),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Firma per presa visione',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(height: 1, color: PdfColors.grey500),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final cartellaPrivacy = Directory(
        p.join(
          documentsDirectory.path,
          'Gestionale Sicurezza',
          'Privacy GDPR Imprese',
        ),
      );

      if (!await cartellaPrivacy.exists()) {
        await cartellaPrivacy.create(recursive: true);
      }

      final nomeImpresaPulito = pulisciNomeFile(ragioneSocialeImpresa);
      final timestamp =
          '${dataDocumento.year}'
          '${dataDocumento.month.toString().padLeft(2, '0')}'
          '${dataDocumento.day.toString().padLeft(2, '0')}_'
          '${dataDocumento.hour.toString().padLeft(2, '0')}'
          '${dataDocumento.minute.toString().padLeft(2, '0')}';

      final percorso = p.join(
        cartellaPrivacy.path,
        'informativa_privacy_impresa_${nomeImpresaPulito}_$timestamp.pdf',
      );

      final file = File(percorso);
      await file.writeAsBytes(await pdf.save());

      final righeAggiornate = await AppDatabase.instance
          .aggiornaDocumentoPrivacyImpresa(
            impresaId: widget.impresa.id!,
            documentoPrivacyImpresaPath: percorso,
          );

      if (!mounted) return;

      if (righeAggiornate == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informativa generata ma non collegata all’impresa.'),
            backgroundColor: Colors.orange,
          ),
        );
        await OpenFile.open(percorso);
        return;
      }

      setState(() {
        documentoPrivacyImpresaPath = percorso;
        schedaModificata = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informativa Privacy/GDPR impresa generata correttamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await OpenFile.open(percorso);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la generazione informativa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> allegaDocumentoPrivacyImpresa() async {
    if (widget.impresa.id == null) return;

    final risultato = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (risultato == null || risultato.files.single.path == null) {
      return;
    }

    final percorso = risultato.files.single.path!;

    final righeAggiornate = await AppDatabase.instance
        .aggiornaDocumentoPrivacyImpresa(
          impresaId: widget.impresa.id!,
          documentoPrivacyImpresaPath: percorso,
        );

    if (!mounted) return;

    if (righeAggiornate == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento privacy impresa non aggiornato.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      documentoPrivacyImpresaPath = percorso;
      schedaModificata = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Documento privacy impresa collegato correttamente.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> apriDocumentoPrivacyImpresa() async {
    final percorso = documentoPrivacyImpresaPath;

    if (percorso == null || percorso.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun documento privacy impresa collegato.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = File(percorso);

    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il file collegato non è stato trovato.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await OpenFile.open(percorso);
  }
}

class _InfoRiga extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRiga({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
