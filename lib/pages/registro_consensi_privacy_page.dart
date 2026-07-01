import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/consenso_privacy.dart';
import '../models/consenso_privacy_log.dart';
import '../services/app_database.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

class RegistroConsensiPrivacyPage extends StatefulWidget {
  const RegistroConsensiPrivacyPage({super.key});

  @override
  State<RegistroConsensiPrivacyPage> createState() =>
      _RegistroConsensiPrivacyPageState();
}

class _RegistroConsensiPrivacyPageState
    extends State<RegistroConsensiPrivacyPage> {
  final TextEditingController ricercaController = TextEditingController();
  final ScrollController tabellaOrizzontaleController = ScrollController();

  late Future<List<ConsensoPrivacy>> futureConsensi;

  String filtroStato = 'Tutti';
  String filtroTipoSoggetto = 'Tutti';
  bool filtroMinorenniConsensiPrivacy = false;
  String campoOrdinamentoConsensiPrivacy = 'dataConsenso';
  bool ordinamentoConsensiPrivacyCrescente = false;

  static const List<String> statiFiltro = [
    'Tutti',
    'ATTIVO',
    'REVOCATO',
    'SCADUTO',
  ];

  static const List<String> statiForm = ['ATTIVO', 'REVOCATO', 'SCADUTO'];

  static const List<String> tipiSoggettoFiltro = [
    'Tutti',
    'Discente',
    'Impresa',
    'Docente',
    'Fornitore',
    'Altro',
  ];

  static const List<String> tipiSoggettoForm = [
    'Discente',
    'Impresa',
    'Docente',
    'Fornitore',
    'Altro',
  ];

  static const List<String> finalitaForm = [
    'Formazione e gestione corsi',
    'Gestione rapporto contrattuale',
    'Adempimenti amministrativi e fiscali',
    'Sorveglianza sanitaria',
    'Comunicazioni informative',
    'Marketing/comunicazioni commerciali',
    'Altro',
  ];

  static const List<String> basiGiuridicheForm = [
    'Consenso',
    'Contratto',
    'Obbligo legale',
    'Legittimo interesse',
    'Altro',
  ];

  static const List<String> canaliRaccoltaForm = [
    'Modulo cartaceo',
    'Email',
    'Telefono',
    'Sito web',
    'Gestionale',
    'Altro',
  ];

  @override
  void initState() {
    super.initState();
    ricaricaConsensi();
  }

  @override
  void dispose() {
    ricercaController.dispose();
    tabellaOrizzontaleController.dispose();
    super.dispose();
  }

  void ricaricaConsensi() {
    futureConsensi = AppDatabase.instance.getConsensiPrivacy(
      ricerca: ricercaController.text,
      stato: filtroStato,
      tipoSoggetto: filtroTipoSoggetto,
    );

    setState(() {});
  }

  Future<void> mostraDialogConsenso({ConsensoPrivacy? consenso}) async {
    final formKey = GlobalKey<FormState>();

    final nominativoController = TextEditingController(
      text: consenso?.nominativo ?? '',
    );
    final codiceFiscaleController = TextEditingController(
      text: consenso?.codiceFiscale ?? '',
    );
    final emailController = TextEditingController(text: consenso?.email ?? '');
    final telefonoController = TextEditingController(
      text: consenso?.telefono ?? '',
    );
    final versioneInformativaController = TextEditingController(
      text: consenso?.versioneInformativa ?? '',
    );
    final dataConsensoController = TextEditingController(
      text: consenso?.dataConsenso ?? '',
    );
    final dataRevocaController = TextEditingController(
      text: consenso?.dataRevoca ?? '',
    );
    final dataScadenzaController = TextEditingController(
      text: consenso?.dataScadenza ?? '',
    );
    final documentoRiferimentoController = TextEditingController(
      text: consenso?.documentoRiferimento ?? '',
    );
    final noteController = TextEditingController(text: consenso?.note ?? '');
    final genitoreTutoreNomeController = TextEditingController(
      text: consenso?.genitoreTutoreNome ?? '',
    );
    final genitoreTutoreCodiceFiscaleController = TextEditingController(
      text: consenso?.genitoreTutoreCodiceFiscale ?? '',
    );
    final genitoreTutoreQualificaController = TextEditingController(
      text: consenso?.genitoreTutoreQualifica ?? '',
    );

    String tipoSoggetto = consenso?.tipoSoggetto ?? 'Altro';
    String finalita = consenso?.finalita ?? 'Formazione e gestione corsi';
    String baseGiuridica = consenso?.baseGiuridica ?? 'Consenso';
    String canaleRaccolta = consenso?.canaleRaccolta ?? 'Gestionale';
    String stato = consenso?.stato ?? 'ATTIVO';
    bool soggettoMinorenne = consenso?.soggettoMinorenne ?? false;
    String consensoPrestatoDa = consenso?.consensoPrestatoDa ?? 'discente';

    if (!['discente', 'genitore', 'tutore'].contains(consensoPrestatoDa)) {
      consensoPrestatoDa = 'discente';
    }

    if (soggettoMinorenne && consensoPrestatoDa == 'discente') {
      consensoPrestatoDa = 'genitore';
    }

    if (!tipiSoggettoForm.contains(tipoSoggetto)) {
      tipoSoggetto = 'Altro';
    }

    if (!finalitaForm.contains(finalita)) {
      finalita = 'Altro';
    }

    if (!basiGiuridicheForm.contains(baseGiuridica)) {
      baseGiuridica = 'Altro';
    }

    if (!canaliRaccoltaForm.contains(canaleRaccolta)) {
      canaleRaccolta = 'Altro';
    }

    if (!statiForm.contains(stato)) {
      stato = 'ATTIVO';
    }

    final salvato = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                consenso == null
                    ? 'Nuovo consenso/privacy'
                    : 'Modifica consenso/privacy',
              ),
              content: SizedBox(
                width: 780,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: tipoSoggetto,
                            decoration: const InputDecoration(
                              labelText: 'Tipo soggetto',
                              border: OutlineInputBorder(),
                            ),
                            items: tipiSoggettoForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => tipoSoggetto = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 520,
                          child: TextFormField(
                            controller: nominativoController,
                            decoration: const InputDecoration(
                              labelText: 'Nominativo / Ragione sociale',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo obbligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: codiceFiscaleController,
                            decoration: const InputDecoration(
                              labelText: 'Codice fiscale / P.IVA',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Telefono',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 752,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CheckboxListTile(
                                    value: soggettoMinorenne,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Soggetto minorenne'),
                                    subtitle: const Text(
                                      'Attiva se il consenso/privacy è prestato da genitore o tutore.',
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        soggettoMinorenne = value ?? false;

                                        if (soggettoMinorenne) {
                                          if (consensoPrestatoDa ==
                                              'discente') {
                                            consensoPrestatoDa = 'genitore';
                                          }

                                          if (genitoreTutoreQualificaController
                                              .text
                                              .trim()
                                              .isEmpty) {
                                            genitoreTutoreQualificaController
                                                    .text =
                                                'Genitore';
                                          }
                                        } else {
                                          consensoPrestatoDa = 'discente';
                                          genitoreTutoreNomeController.clear();
                                          genitoreTutoreCodiceFiscaleController
                                              .clear();
                                          genitoreTutoreQualificaController
                                              .clear();
                                        }
                                      });
                                    },
                                  ),
                                  if (soggettoMinorenne) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        SizedBox(
                                          width: 220,
                                          child: DropdownButtonFormField<String>(
                                            initialValue: consensoPrestatoDa,
                                            decoration: const InputDecoration(
                                              labelText: 'Consenso prestato da',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'genitore',
                                                child: Text('Genitore'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'tutore',
                                                child: Text('Tutore'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value == null) return;

                                              setModalState(() {
                                                consensoPrestatoDa = value;
                                                genitoreTutoreQualificaController
                                                    .text = value == 'tutore'
                                                    ? 'Tutore'
                                                    : 'Genitore';
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 250,
                                          child: TextFormField(
                                            controller:
                                                genitoreTutoreNomeController,
                                            decoration: const InputDecoration(
                                              labelText: 'Nome genitore/tutore',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (value) {
                                              if (!soggettoMinorenne) {
                                                return null;
                                              }
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Campo obbligatorio';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 220,
                                          child: TextFormField(
                                            controller:
                                                genitoreTutoreCodiceFiscaleController,
                                            decoration: const InputDecoration(
                                              labelText: 'CF genitore/tutore',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 220,
                                          child: TextFormField(
                                            controller:
                                                genitoreTutoreQualificaController,
                                            decoration: const InputDecoration(
                                              labelText: 'Qualifica',
                                              hintText:
                                                  'Genitore, tutore, amministratore...',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (value) {
                                              if (!soggettoMinorenne) {
                                                return null;
                                              }
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Campo obbligatorio';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 360,
                          child: DropdownButtonFormField<String>(
                            initialValue: finalita,
                            decoration: const InputDecoration(
                              labelText: 'Finalità',
                              border: OutlineInputBorder(),
                            ),
                            items: finalitaForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => finalita = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: baseGiuridica,
                            decoration: const InputDecoration(
                              labelText: 'Base giuridica',
                              border: OutlineInputBorder(),
                            ),
                            items: basiGiuridicheForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => baseGiuridica = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: canaleRaccolta,
                            decoration: const InputDecoration(
                              labelText: 'Canale raccolta',
                              border: OutlineInputBorder(),
                            ),
                            items: canaliRaccoltaForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => canaleRaccolta = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: stato,
                            decoration: const InputDecoration(
                              labelText: 'Stato',
                              border: OutlineInputBorder(),
                            ),
                            items: statiForm
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => stato = value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: dataConsensoController,
                            decoration: const InputDecoration(
                              labelText: 'Data consenso',
                              hintText: 'gg/mm/aaaa',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo obbligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: dataRevocaController,
                            decoration: const InputDecoration(
                              labelText: 'Data revoca',
                              hintText: 'gg/mm/aaaa',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: dataScadenzaController,
                            decoration: const InputDecoration(
                              labelText: 'Data scadenza/retention',
                              hintText: 'gg/mm/aaaa',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: versioneInformativaController,
                            decoration: const InputDecoration(
                              labelText: 'Versione informativa',
                              hintText: 'es. Privacy v1.0',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 490,
                          child: TextFormField(
                            controller: documentoRiferimentoController,
                            decoration: const InputDecoration(
                              labelText: 'Documento / riferimento',
                              hintText: 'es. modulo firmato, email, protocollo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 752,
                          child: TextFormField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salva'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final now = DateTime.now().toIso8601String();

                    final record = ConsensoPrivacy(
                      id: consenso?.id,
                      tipoSoggetto: tipoSoggetto,
                      soggettoId: consenso?.soggettoId,
                      nominativo: nominativoController.text.trim(),
                      codiceFiscale: codiceFiscaleController.text.trim(),
                      email: emailController.text.trim(),
                      telefono: telefonoController.text.trim(),
                      finalita: finalita,
                      baseGiuridica: baseGiuridica,
                      versioneInformativa: versioneInformativaController.text
                          .trim(),
                      canaleRaccolta: canaleRaccolta,
                      stato: stato,
                      dataConsenso: dataConsensoController.text.trim(),
                      dataRevoca: dataRevocaController.text.trim(),
                      dataScadenza: dataScadenzaController.text.trim(),
                      documentoRiferimento: documentoRiferimentoController.text
                          .trim(),
                      note: noteController.text.trim(),
                      soggettoMinorenne: soggettoMinorenne,
                      consensoPrestatoDa: soggettoMinorenne
                          ? consensoPrestatoDa
                          : 'discente',
                      genitoreTutoreNome: soggettoMinorenne
                          ? genitoreTutoreNomeController.text.trim()
                          : null,
                      genitoreTutoreCodiceFiscale: soggettoMinorenne
                          ? genitoreTutoreCodiceFiscaleController.text.trim()
                          : null,
                      genitoreTutoreQualifica: soggettoMinorenne
                          ? genitoreTutoreQualificaController.text.trim()
                          : null,
                      createdAt: consenso?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (consenso == null) {
                      final nuovoId = await AppDatabase.instance
                          .insertConsensoPrivacy(record);

                      await AppDatabase.instance.registraLogConsensoPrivacy(
                        consensoPrivacyId: nuovoId,
                        azione: 'CREAZIONE',
                        descrizione:
                            'Creato consenso privacy - ${descrizioneLogConsensoPrivacy(record)}',
                        datiDopo: datiLogConsensoPrivacy(record),
                      );
                    } else {
                      final datiPrima = datiLogConsensoPrivacy(consenso);

                      await AppDatabase.instance.updateConsensoPrivacy(record);

                      await AppDatabase.instance.registraLogConsensoPrivacy(
                        consensoPrivacyId: consenso.id,
                        azione: 'MODIFICA',
                        descrizione:
                            'Modificato consenso privacy - ${descrizioneLogConsensoPrivacy(record)}',
                        datiPrima: datiPrima,
                        datiDopo: datiLogConsensoPrivacy(record),
                      );
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nominativoController.dispose();
    codiceFiscaleController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    versioneInformativaController.dispose();
    dataConsensoController.dispose();
    dataRevocaController.dispose();
    dataScadenzaController.dispose();
    documentoRiferimentoController.dispose();
    noteController.dispose();
    genitoreTutoreNomeController.dispose();
    genitoreTutoreCodiceFiscaleController.dispose();
    genitoreTutoreQualificaController.dispose();

    if (salvato == true && mounted) {
      ricaricaConsensi();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro consensi/privacy aggiornato')),
      );
    }
  }

  Future<void> revocaConsenso(ConsensoPrivacy consenso) async {
    if (consenso.id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Revocare il consenso?'),
          content: Text(
            'Il consenso di "${consenso.nominativo}" verrà impostato come REVOCATO.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.block_outlined),
              label: const Text('Revoca'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    final datiPrima = datiLogConsensoPrivacy(consenso);

    await AppDatabase.instance.revocaConsensoPrivacy(consenso.id!);

    await AppDatabase.instance.registraLogConsensoPrivacy(
      consensoPrivacyId: consenso.id,
      azione: 'REVOCA',
      descrizione:
          'Revocato consenso privacy - ${descrizioneLogConsensoPrivacy(consenso)}',
      datiPrima: datiPrima,
    );

    if (!mounted) return;

    ricaricaConsensi();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consenso revocato')));
  }

  Future<void> eliminaConsenso(ConsensoPrivacy consenso) async {
    if (consenso.id == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminare il consenso?'),
          content: Text(
            'Il record di "${consenso.nominativo}" verrà eliminato definitivamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Elimina'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    final datiPrima = datiLogConsensoPrivacy(consenso);

    await AppDatabase.instance.registraLogConsensoPrivacy(
      consensoPrivacyId: consenso.id,
      azione: 'ELIMINAZIONE',
      descrizione:
          'Eliminato consenso privacy - ${descrizioneLogConsensoPrivacy(consenso)}',
      datiPrima: datiPrima,
    );

    await AppDatabase.instance.deleteConsensoPrivacy(consenso.id!);

    if (!mounted) return;

    ricaricaConsensi();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consenso eliminato')));
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'ATTIVO':
        return Colors.green.shade700;
      case 'REVOCATO':
        return Colors.red.shade700;
      case 'SCADUTO':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget badgeStato(String stato) {
    return Chip(
      label: Text(stato, style: const TextStyle(color: Colors.white)),
      backgroundColor: coloreStato(stato),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget cardKpi(String titolo, String valore, IconData icona) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icona),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titolo, style: const TextStyle(fontSize: 12)),
                  Text(
                    valore,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRiepilogo(List<ConsensoPrivacy> consensi) {
    final attivi = consensi
        .where((elemento) => elemento.stato == 'ATTIVO')
        .length;
    final revocati = consensi
        .where((elemento) => elemento.stato == 'REVOCATO')
        .length;
    final scaduti = consensi
        .where((elemento) => elemento.stato == 'SCADUTO')
        .length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        cardKpi('Totale', consensi.length.toString(), Icons.fact_check),
        cardKpi('Attivi', attivi.toString(), Icons.verified_user_outlined),
        cardKpi('Revocati', revocati.toString(), Icons.block_outlined),
        cardKpi('Scaduti', scaduti.toString(), Icons.warning_amber_outlined),
      ],
    );
  }

  Widget buildFiltri() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 380,
          child: TextField(
            controller: ricercaController,
            decoration: InputDecoration(
              labelText: 'Cerca',
              hintText: 'Nominativo, CF/P.IVA, email, finalità, documento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ricercaController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ricercaController.clear();
                        ricaricaConsensi();
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => ricaricaConsensi(),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            key: ValueKey('stato-$filtroStato'),
            initialValue: filtroStato,
            decoration: const InputDecoration(
              labelText: 'Stato',
              border: OutlineInputBorder(),
            ),
            items: statiFiltro
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              filtroStato = value;
              ricaricaConsensi();
            },
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
            key: ValueKey('tipo-$filtroTipoSoggetto'),
            initialValue: filtroTipoSoggetto,
            decoration: const InputDecoration(
              labelText: 'Tipo soggetto',
              border: OutlineInputBorder(),
            ),
            items: tipiSoggettoFiltro
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              filtroTipoSoggetto = value;
              ricaricaConsensi();
            },
          ),
        ),
        FilterChip(
          avatar: const Icon(Icons.child_care, size: 18),
          label: const Text('Minorenni'),
          selected: filtroMinorenniConsensiPrivacy,
          onSelected: (value) {
            setState(() {
              filtroMinorenniConsensiPrivacy = value;
            });
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Azzera filtro'),
          onPressed: () {
            ricercaController.clear();
            filtroStato = 'Tutti';
            filtroTipoSoggetto = 'Tutti';
            filtroMinorenniConsensiPrivacy = false;
            ricaricaConsensi();
          },
        ),
      ],
    );
  }

  String normalizzaTestoOrdinamentoConsensiPrivacy(String valore) {
    return valore.trim().toLowerCase();
  }

  DateTime? dataOrdinamentoConsensiPrivacy(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';

    if (testo.isEmpty) {
      return null;
    }

    if (valore is DateTime) {
      return valore;
    }

    return DateTime.tryParse(testo);
  }

  int confrontaTestoConsensiPrivacy(String a, String b) {
    return normalizzaTestoOrdinamentoConsensiPrivacy(
      a,
    ).compareTo(normalizzaTestoOrdinamentoConsensiPrivacy(b));
  }

  int confrontaDateConsensiPrivacy(dynamic a, dynamic b) {
    final dataA = dataOrdinamentoConsensiPrivacy(a);
    final dataB = dataOrdinamentoConsensiPrivacy(b);

    if (dataA == null && dataB == null) {
      return 0;
    }

    if (dataA == null) {
      return 1;
    }

    if (dataB == null) {
      return -1;
    }

    return dataA.compareTo(dataB);
  }

  List<ConsensoPrivacy> ordinaConsensiPrivacy(List<ConsensoPrivacy> consensi) {
    final ordinati = List<ConsensoPrivacy>.from(consensi);

    ordinati.sort((a, b) {
      var risultato = 0;

      switch (campoOrdinamentoConsensiPrivacy) {
        case 'nominativo':
          risultato = confrontaTestoConsensiPrivacy(a.nominativo, b.nominativo);
          break;
        case 'tipoSoggetto':
          risultato = confrontaTestoConsensiPrivacy(
            a.tipoSoggetto,
            b.tipoSoggetto,
          );
          break;
        case 'finalita':
          risultato = confrontaTestoConsensiPrivacy(a.finalita, b.finalita);
          break;
        case 'baseGiuridica':
          risultato = confrontaTestoConsensiPrivacy(
            a.baseGiuridica,
            b.baseGiuridica,
          );
          break;
        case 'versioneInformativa':
          risultato = confrontaTestoConsensiPrivacy(
            a.versioneInformativa,
            b.versioneInformativa,
          );
          break;
        case 'canaleRaccolta':
          risultato = confrontaTestoConsensiPrivacy(
            a.canaleRaccolta,
            b.canaleRaccolta,
          );
          break;
        case 'dataConsenso':
          risultato = confrontaDateConsensiPrivacy(
            a.dataConsenso,
            b.dataConsenso,
          );
          break;
        case 'dataRevoca':
          risultato = confrontaDateConsensiPrivacy(a.dataRevoca, b.dataRevoca);
          break;
        case 'stato':
          risultato = confrontaTestoConsensiPrivacy(a.stato, b.stato);
          break;
        default:
          risultato = confrontaDateConsensiPrivacy(
            a.dataConsenso,
            b.dataConsenso,
          );
      }

      if (risultato == 0) {
        risultato = confrontaTestoConsensiPrivacy(a.nominativo, b.nominativo);
      }

      return ordinamentoConsensiPrivacyCrescente ? risultato : -risultato;
    });

    return ordinati;
  }

  Widget intestazioneOrdinabileConsensiPrivacy(
    String campo,
    String etichetta, {
    double? larghezza,
  }) {
    final attivo = campoOrdinamentoConsensiPrivacy == campo;

    final contenuto = InkWell(
      onTap: () {
        setState(() {
          if (campoOrdinamentoConsensiPrivacy == campo) {
            ordinamentoConsensiPrivacyCrescente =
                !ordinamentoConsensiPrivacyCrescente;
          } else {
            campoOrdinamentoConsensiPrivacy = campo;

            if (campo == 'dataConsenso' || campo == 'dataRevoca') {
              ordinamentoConsensiPrivacyCrescente = false;
            } else {
              ordinamentoConsensiPrivacyCrescente = true;
            }
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              etichetta,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            attivo
                ? ordinamentoConsensiPrivacyCrescente
                      ? Icons.arrow_upward
                      : Icons.arrow_downward
                : Icons.unfold_more,
            size: 16,
          ),
        ],
      ),
    );

    if (larghezza == null) {
      return contenuto;
    }

    return SizedBox(width: larghezza, child: contenuto);
  }

  Widget buildTabella(List<ConsensoPrivacy> consensi) {
    if (consensi.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nessun consenso/privacy presente.')),
        ),
      );
    }

    return Card(
      child: Scrollbar(
        controller: tabellaOrizzontaleController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: tabellaOrizzontaleController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 46,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 58,
            columns: [
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'dataConsenso',
                  'Data consenso',
                  larghezza: 130,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'tipoSoggetto',
                  'Soggetto',
                  larghezza: 130,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'nominativo',
                  'Nominativo',
                  larghezza: 180,
                ),
              ),
              const DataColumn(
                label: SizedBox(
                  width: 190,
                  child: Text('Firma / rappresentanza'),
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'finalita',
                  'Finalità',
                  larghezza: 180,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'baseGiuridica',
                  'Base giuridica',
                  larghezza: 160,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'versioneInformativa',
                  'Informativa',
                  larghezza: 130,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'canaleRaccolta',
                  'Canale',
                  larghezza: 120,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'stato',
                  'Stato',
                  larghezza: 100,
                ),
              ),
              DataColumn(
                label: intestazioneOrdinabileConsensiPrivacy(
                  'dataRevoca',
                  'Revoca',
                  larghezza: 120,
                ),
              ),
              const DataColumn(label: Text('Azioni')),
            ],
            rows: consensi.map((consenso) {
              DataCell cellaDettaglio(Widget child) {
                return DataCell(
                  child,
                  onDoubleTap: () => mostraDettaglioConsensoPrivacy(consenso),
                );
              }

              return DataRow(
                cells: [
                  cellaDettaglio(Text(consenso.dataConsenso)),
                  cellaDettaglio(Text(consenso.tipoSoggetto)),
                  cellaDettaglio(
                    SizedBox(
                      width: 240,
                      child: Text(
                        consenso.nominativo,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  cellaDettaglio(
                    SizedBox(
                      width: 210,
                      child: Text(
                        testoRappresentanzaConsensoPrivacy(consenso),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  cellaDettaglio(
                    SizedBox(
                      width: 280,
                      child: Text(
                        consenso.finalita,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  cellaDettaglio(Text(consenso.baseGiuridica)),
                  cellaDettaglio(Text(consenso.versioneInformativa)),
                  cellaDettaglio(Text(consenso.canaleRaccolta)),
                  cellaDettaglio(badgeStato(consenso.stato)),
                  cellaDettaglio(Text(consenso.dataRevoca)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Dettaglio',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () =>
                              mostraDettaglioConsensoPrivacy(consenso),
                        ),
                        IconButton(
                          tooltip: 'Modifica',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              mostraDialogConsenso(consenso: consenso),
                        ),
                        IconButton(
                          tooltip: 'Revoca',
                          icon: const Icon(Icons.block_outlined),
                          onPressed: consenso.stato == 'REVOCATO'
                              ? null
                              : () => revocaConsenso(consenso),
                        ),
                        IconButton(
                          tooltip: 'Elimina',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => eliminaConsenso(consenso),
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
    );
  }

  Widget buildContenuto(List<ConsensoPrivacy> consensi) {
    final consensiFiltrati = filtroMinorenniConsensiPrivacy
        ? consensi.where((consenso) => consenso.soggettoMinorenne).toList()
        : consensi;

    final consensiOrdinati = ordinaConsensiPrivacy(consensiFiltrati);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registro centralizzato consensi/privacy',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Archivio unico per consensi, informative privacy, finalità, base giuridica, revoche e riferimenti documentali.',
        ),
        const SizedBox(height: 16),
        buildRiepilogo(consensiFiltrati),
        const SizedBox(height: 16),
        buildFiltri(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  esportaExcelRegistroConsensiPrivacy(consensiOrdinati),
              icon: const Icon(Icons.table_chart),
              label: const Text('Excel'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  mostraAnteprimaPdfRegistroConsensiPrivacy(consensiOrdinati),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
            FilledButton.icon(
              onPressed: () => stampaRegistroConsensiPrivacy(consensiOrdinati),
              icon: const Icon(Icons.print),
              label: const Text('Stampa'),
            ),
            OutlinedButton.icon(
              onPressed: mostraGuidaRegistroConsensiPrivacy,
              icon: const Icon(Icons.help_outline),
              label: const Text('Guida'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: buildTabella(consensiOrdinati)),
      ],
    );
  }

  String valoreDettaglioConsensoPrivacy(String valore) {
    final testo = valore.trim();
    return testo.isEmpty ? '—' : testo;
  }

  Widget rigaDettaglioConsensoPrivacy(
    String etichetta,
    String valore, {
    bool evidenziata = false,
  }) {
    final tema = Theme.of(context);
    final testo = valoreDettaglioConsensoPrivacy(valore);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compatto = constraints.maxWidth < 520;

          final label = Text(
            etichetta,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          );

          final contenuto = SelectableText(
            testo,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: evidenziata ? FontWeight.w700 : FontWeight.w400,
            ),
          );

          if (compatto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 3), contenuto],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 190, child: label),
              Expanded(child: contenuto),
            ],
          );
        },
      ),
    );
  }

  Widget sezioneDettaglioConsensoPrivacy(String titolo, List<Widget> righe) {
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...righe,
          ],
        ),
      ),
    );
  }

  String datiLogConsensoPrivacy(ConsensoPrivacy consenso) {
    return const JsonEncoder.withIndent('  ').convert(consenso.toMap());
  }

  String descrizioneLogConsensoPrivacy(ConsensoPrivacy consenso) {
    return [
      'Nominativo: ${consenso.nominativo}',
      'Tipo soggetto: ${consenso.tipoSoggetto}',
      'Finalità: ${consenso.finalita}',
      'Stato: ${consenso.stato}',
    ].join(' | ');
  }

  String valoreLogConsensoPrivacy(String? valore) {
    final testo = valore?.trim() ?? '';
    if (testo.isEmpty) {
      return '-';
    }
    return testo;
  }

  String formattaDataOraLogConsensoPrivacy(DateTime data) {
    final giorno = data.day.toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final anno = data.year.toString();
    final ora = data.hour.toString().padLeft(2, '0');
    final minuti = data.minute.toString().padLeft(2, '0');

    return '$giorno/$mese/$anno $ora:$minuti';
  }

  String testoRappresentanzaConsensoPrivacy(ConsensoPrivacy consenso) {
    if (!consenso.soggettoMinorenne) {
      return 'Discente';
    }

    final nomeRappresentante = (consenso.genitoreTutoreNome ?? '').trim();

    final qualifica = consenso.consensoPrestatoDa == 'tutore'
        ? 'Tutore'
        : 'Genitore';

    if (nomeRappresentante.isEmpty) {
      return qualifica;
    }

    return '$qualifica: $nomeRappresentante';
  }

  Future<void> mostraLogConsensoPrivacy(ConsensoPrivacy consenso) async {
    final id = consenso.id;

    if (id == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log non disponibile per un consenso non salvato.'),
        ),
      );
      return;
    }

    final List<ConsensoPrivacyLog> logs = await AppDatabase.instance
        .getConsensiPrivacyLog(consensoPrivacyId: id);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log consenso/privacy'),
          content: SizedBox(
            width: 760,
            child: logs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nessun log disponibile per questo consenso.'),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 520),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: logs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final log = logs[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  label: Text(
                                    valoreLogConsensoPrivacy(log.azione),
                                  ),
                                ),
                                Text(
                                  formattaDataOraLogConsensoPrivacy(
                                    log.dataOra,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Utente: ${valoreLogConsensoPrivacy(log.utente)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              valoreLogConsensoPrivacy(log.descrizione),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if ((log.datiPrima?.trim().isNotEmpty ?? false) ||
                                (log.datiDopo?.trim().isNotEmpty ?? false)) ...[
                              const SizedBox(height: 12),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.zero,
                                title: const Text('Dati modifica'),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Prima:',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    valoreLogConsensoPrivacy(log.datiPrima),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Dopo:',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    valoreLogConsensoPrivacy(log.datiDopo),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  void mostraDettaglioConsensoPrivacy(ConsensoPrivacy consenso) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final larghezzaSchermo = MediaQuery.of(dialogContext).size.width;
        final altezzaSchermo = MediaQuery.of(dialogContext).size.height;

        final larghezzaDialog = larghezzaSchermo >= 1100
            ? 900.0
            : larghezzaSchermo >= 760
            ? 720.0
            : larghezzaSchermo * 0.94;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dettaglio consenso/privacy',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: larghezzaDialog,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altezzaSchermo * 0.78),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sezioneDettaglioConsensoPrivacy('Identificazione', [
                      rigaDettaglioConsensoPrivacy(
                        'ID consenso',
                        consenso.id?.toString() ?? '',
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Tipo soggetto',
                        consenso.tipoSoggetto,
                        evidenziata: true,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'ID soggetto collegato',
                        consenso.soggettoId?.toString() ?? '',
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Nominativo',
                        consenso.nominativo,
                        evidenziata: true,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Codice fiscale',
                        consenso.codiceFiscale,
                      ),
                      rigaDettaglioConsensoPrivacy('Email', consenso.email),
                      rigaDettaglioConsensoPrivacy(
                        'Telefono',
                        consenso.telefono,
                      ),
                    ]),
                    sezioneDettaglioConsensoPrivacy('Soggetto minorenne', [
                      rigaDettaglioConsensoPrivacy(
                        'Soggetto minorenne',
                        consenso.soggettoMinorenne ? 'Sì' : 'No',
                        evidenziata: consenso.soggettoMinorenne,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Consenso prestato da',
                        consenso.consensoPrestatoDa == 'genitore'
                            ? 'Genitore'
                            : consenso.consensoPrestatoDa == 'tutore'
                            ? 'Tutore'
                            : 'Discente',
                        evidenziata: consenso.soggettoMinorenne,
                      ),
                      if (consenso.soggettoMinorenne) ...[
                        rigaDettaglioConsensoPrivacy(
                          'Nome genitore/tutore',
                          consenso.genitoreTutoreNome ?? '',
                          evidenziata: true,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'CF genitore/tutore',
                          consenso.genitoreTutoreCodiceFiscale ?? '',
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Qualifica',
                          consenso.genitoreTutoreQualifica ?? '',
                          evidenziata: true,
                        ),
                      ],
                    ]),
                    sezioneDettaglioConsensoPrivacy(
                      'Consenso e base giuridica',
                      [
                        rigaDettaglioConsensoPrivacy(
                          'Finalità',
                          consenso.finalita,
                          evidenziata: true,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Base giuridica',
                          consenso.baseGiuridica,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Versione informativa',
                          consenso.versioneInformativa,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Canale raccolta',
                          consenso.canaleRaccolta,
                        ),
                        rigaDettaglioConsensoPrivacy(
                          'Stato',
                          consenso.stato,
                          evidenziata: true,
                        ),
                      ],
                    ),
                    sezioneDettaglioConsensoPrivacy('Date', [
                      rigaDettaglioConsensoPrivacy(
                        'Data consenso',
                        consenso.dataConsenso,
                        evidenziata: true,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Data revoca',
                        consenso.dataRevoca,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Data scadenza',
                        consenso.dataScadenza,
                      ),
                    ]),
                    sezioneDettaglioConsensoPrivacy('Documentazione e note', [
                      rigaDettaglioConsensoPrivacy(
                        'Documento riferimento',
                        consenso.documentoRiferimento,
                      ),
                      rigaDettaglioConsensoPrivacy('Note', consenso.note),
                    ]),
                    sezioneDettaglioConsensoPrivacy('Tracciamento tecnico', [
                      rigaDettaglioConsensoPrivacy(
                        'Creato il',
                        consenso.createdAt,
                      ),
                      rigaDettaglioConsensoPrivacy(
                        'Ultimo aggiornamento',
                        consenso.updatedAt,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                mostraLogConsensoPrivacy(consenso);
              },
              icon: const Icon(Icons.history),
              label: const Text('Log'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro consensi/privacy'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            icon: const Icon(Icons.refresh),
            onPressed: ricaricaConsensi,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuovo consenso'),
        onPressed: () => mostraDialogConsenso(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<ConsensoPrivacy>>(
          future: futureConsensi,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Errore caricamento consensi: ${snapshot.error}'),
              );
            }

            final consensi = snapshot.data ?? [];

            return buildContenuto(consensi);
          },
        ),
      ),
    );
  }

  String formattaDataConsensoPrivacy(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';

    if (testo.isEmpty) {
      return '';
    }

    final data = valore is DateTime ? valore : DateTime.tryParse(testo);

    if (data == null) {
      return testo;
    }

    final giorno = data.day.toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final anno = data.year.toString();

    return '$giorno/$mese/$anno';
  }

  Future<Uint8List> generaPdfRegistroConsensiPrivacyBytes(
    List<ConsensoPrivacy> elementiDaEsportare,
  ) async {
    final documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              'Registro consensi/privacy',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Archivio centralizzato consensi, informative privacy, finalità, base giuridica, revoche e riferimenti documentali.',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Elementi esportati: ${elementiDaEsportare.length}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Interessato',
                'Firma / rapp.',
                'Contesto',
                'Finalità',
                'Base giuridica',
                'Consenso',
                'Data consenso',
                'Data revoca',
                'Stato',
                'Note',
              ],
              data: elementiDaEsportare.map((consenso) {
                final stato = consenso.stato.trim();
                final consensoPrestato = stato.toLowerCase() == 'attivo'
                    ? 'Sì'
                    : 'No';

                return [
                  consenso.nominativo,
                  testoRappresentanzaConsensoPrivacy(consenso),
                  consenso.tipoSoggetto,
                  consenso.finalita,
                  consenso.baseGiuridica,
                  consensoPrestato,
                  formattaDataConsensoPrivacy(consenso.dataConsenso),
                  formattaDataConsensoPrivacy(consenso.dataRevoca),
                  stato,
                  consenso.note,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.topLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.45),
                1: pw.FlexColumnWidth(1.35),
                2: pw.FlexColumnWidth(1.0),
                3: pw.FlexColumnWidth(1.65),
                4: pw.FlexColumnWidth(1.3),
                5: pw.FlexColumnWidth(0.75),
                6: pw.FlexColumnWidth(0.95),
                7: pw.FlexColumnWidth(0.95),
                8: pw.FlexColumnWidth(0.8),
                9: pw.FlexColumnWidth(1.45),
              },
            ),
          ];
        },
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          );
        },
      ),
    );

    return documento.save();
  }

  Future<void> mostraAnteprimaPdfRegistroConsensiPrivacy(
    List<ConsensoPrivacy> elementiDaEsportare,
  ) async {
    if (elementiDaEsportare.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun consenso/privacy da esportare in PDF.'),
        ),
      );
      return;
    }

    await AppDatabase.instance.registraLogConsensoPrivacy(
      azione: 'ANTEPRIMA_PDF',
      descrizione:
          'Aperta anteprima PDF Registro consensi/privacy - elementi: ${elementiDaEsportare.length}',
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 1100,
            height: 760,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Anteprima PDF Registro consensi/privacy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    build: (format) => generaPdfRegistroConsensiPrivacyBytes(
                      elementiDaEsportare,
                    ),
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    allowPrinting: false,
                    allowSharing: false,
                    pdfFileName: 'registro_consensi_privacy.pdf',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> stampaRegistroConsensiPrivacy(
    List<ConsensoPrivacy> elementiDaStampare,
  ) async {
    if (elementiDaStampare.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun consenso/privacy da stampare.')),
      );
      return;
    }

    await AppDatabase.instance.registraLogConsensoPrivacy(
      azione: 'STAMPA',
      descrizione:
          'Aperta anteprima stampa Registro consensi/privacy - elementi: ${elementiDaStampare.length}',
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 1100,
            height: 760,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Anteprima stampa Registro consensi/privacy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    build: (format) => generaPdfRegistroConsensiPrivacyBytes(
                      elementiDaStampare,
                    ),
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    allowPrinting: true,
                    allowSharing: false,
                    pdfFileName: 'registro_consensi_privacy_stampa.pdf',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> esportaExcelRegistroConsensiPrivacy(
    List<ConsensoPrivacy> elementiDaEsportare,
  ) async {
    if (elementiDaEsportare.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun consenso/privacy da esportare.')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Registro consensi privacy'];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final intestazioni = <String>[
      'Interessato',
      'Firma / rappresentanza',
      'Contesto',
      'Finalità',
      'Base giuridica',
      'Consenso prestato',
      'Data consenso',
      'Data revoca',
      'Stato',
      'Note',
    ];

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 0))
          .value = TextCellValue(
        intestazioni[colonna],
      );
    }

    for (var riga = 0; riga < elementiDaEsportare.length; riga++) {
      final consenso = elementiDaEsportare[riga];
      final rowIndex = riga + 1;

      final stato = consenso.stato.trim();
      final consensoPrestato = stato.toLowerCase() == 'attivo' ? 'Sì' : 'No';

      final valori = <String>[
        consenso.nominativo,
        testoRappresentanzaConsensoPrivacy(consenso),
        consenso.tipoSoggetto,
        consenso.finalita,
        consenso.baseGiuridica,
        consensoPrestato,
        formattaDataConsensoPrivacy(consenso.dataConsenso),
        formattaDataConsensoPrivacy(consenso.dataRevoca),
        stato,
        consenso.note,
      ];

      for (var colonna = 0; colonna < valori.length; colonna++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colonna,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          valori[colonna],
        );
      }
    }

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet.setColumnWidth(colonna, 24);
    }

    final bytes = excel.encode();

    if (bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la generazione del file Excel.'),
        ),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}Gestionale Sicurezza${Platform.pathSeparator}Export',
    );

    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}registro_consensi_privacy_$timestamp.xlsx',
    );

    await file.writeAsBytes(bytes, flush: true);

    await AppDatabase.instance.registraLogConsensoPrivacy(
      azione: 'EXPORT_EXCEL',
      descrizione:
          'Esportato Excel Registro consensi/privacy - elementi: ${elementiDaEsportare.length} - file: ${file.path}',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export Excel creato: ${file.path}')),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export Excel creato: ${file.path}')),
    );
  }

  Future<void> mostraGuidaRegistroConsensiPrivacy() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Guida rapida Registro consensi/privacy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'A cosa serve',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Il registro consensi/privacy consente di mantenere un archivio centralizzato dei consensi, delle informative privacy, delle finalità di trattamento, della base giuridica e delle eventuali revoche.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Gestione dei consensi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ogni riga rappresenta un consenso o una registrazione privacy collegata a un soggetto. È possibile registrare nominativo, tipo soggetto, finalità, base giuridica, data consenso, stato, eventuale revoca e note interne.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Stati principali',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'ATTIVO: consenso valido o registrazione privacy attiva.\n'
                          'REVOCATO: consenso revocato o non più utilizzabile.\n'
                          'Gli stati aiutano a distinguere rapidamente le posizioni valide da quelle non più operative.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Ricerca e filtri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Usare la ricerca e i filtri disponibili per individuare rapidamente consensi per nominativo, tipologia soggetto, finalità, base giuridica o stato. Il pulsante di azzeramento filtri consente di tornare alla vista completa.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Dettaglio consenso/privacy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Il dettaglio in sola lettura permette di verificare tutti i dati del consenso senza modificare accidentalmente il record. Può essere aperto dalla riga o dal pulsante dedicato, se presente.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Revoca',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'La revoca deve essere usata quando un consenso non è più valido. La registrazione della data di revoca permette di conservare la tracciabilità storica della scelta dell’interessato.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Export e stampa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Excel: esporta il registro in formato .xlsx.\n'
                          'PDF: apre l’anteprima del registro in formato PDF.\n'
                          'Stampa: apre l’anteprima di stampa e consente l’invio alla stampante.',
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Nota operativa GDPR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Il registro non sostituisce l’informativa privacy o il registro dei trattamenti, ma aiuta a documentare in modo ordinato le evidenze relative ai consensi e alle basi giuridiche collegate.',
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Ho capito'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
