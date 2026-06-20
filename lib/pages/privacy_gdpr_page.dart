import 'package:flutter/material.dart';

import '../models/privacy_gdpr.dart';
import '../services/app_database.dart';

class PrivacyGdprPage extends StatefulWidget {
  const PrivacyGdprPage({super.key});

  @override
  State<PrivacyGdprPage> createState() => _PrivacyGdprPageState();
}

class _PrivacyGdprPageState extends State<PrivacyGdprPage> {
  List<PrivacyGdpr> vociPrivacy = [];
  bool caricamento = true;
  bool soloAttive = true;

  @override
  void initState() {
    super.initState();
    caricaPrivacyGdpr();
  }

  Future<void> caricaPrivacyGdpr() async {
    setState(() {
      caricamento = true;
    });

    final dati = await AppDatabase.instance.getPrivacyGdpr(
      soloAttivi: soloAttive,
    );

    if (!mounted) return;

    setState(() {
      vociPrivacy = dati.map((mappa) => PrivacyGdpr.fromMap(mappa)).toList();
      caricamento = false;
    });
  }

  Future<void> mostraDialogNuovaVoce() async {
    final formKey = GlobalKey<FormState>();

    final titoloController = TextEditingController();
    final titolareController = TextEditingController();
    final referenteController = TextEditingController();
    final baseGiuridicaController = TextEditingController();
    final finalitaController = TextEditingController();
    final categorieDatiController = TextEditingController();
    final periodoConservazioneController = TextEditingController();
    final misureSicurezzaController = TextEditingController();
    final noteController = TextEditingController();

    bool voceAttiva = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova voce Privacy/GDPR'),
              content: SizedBox(
                width: 760,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titoloController,
                          decoration: const InputDecoration(
                            labelText: 'Titolo *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valore) {
                            if (valore == null || valore.trim().isEmpty) {
                              return 'Inserisci il titolo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titolareController,
                          decoration: const InputDecoration(
                            labelText: 'Titolare trattamento',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: referenteController,
                          decoration: const InputDecoration(
                            labelText: 'Referente privacy',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: baseGiuridicaController,
                          decoration: const InputDecoration(
                            labelText: 'Base giuridica',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: finalitaController,
                          decoration: const InputDecoration(
                            labelText: 'Finalità trattamento',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: categorieDatiController,
                          decoration: const InputDecoration(
                            labelText: 'Categorie dati',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: periodoConservazioneController,
                          decoration: const InputDecoration(
                            labelText: 'Periodo conservazione',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: misureSicurezzaController,
                          decoration: const InputDecoration(
                            labelText: 'Misure sicurezza',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voce attiva'),
                          subtitle: const Text(
                            'Le voci non attive restano archiviate ma vengono nascoste dal filtro Solo attive.',
                          ),
                          value: voceAttiva,
                          onChanged: (valore) {
                            setDialogState(() {
                              voceAttiva = valore;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annulla'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    await AppDatabase.instance.insertPrivacyGdpr(
                      titolo: titoloController.text,
                      titolareTrattamento: titolareController.text,
                      referentePrivacy: referenteController.text,
                      baseGiuridica: baseGiuridicaController.text,
                      finalitaTrattamento: finalitaController.text,
                      categorieDati: categorieDatiController.text,
                      periodoConservazione: periodoConservazioneController.text,
                      misureSicurezza: misureSicurezzaController.text,
                      note: noteController.text,
                      attivo: voceAttiva,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    await caricaPrivacyGdpr();

                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Voce Privacy/GDPR salvata.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );

    titoloController.dispose();
    titolareController.dispose();
    referenteController.dispose();
    baseGiuridicaController.dispose();
    finalitaController.dispose();
    categorieDatiController.dispose();
    periodoConservazioneController.dispose();
    misureSicurezzaController.dispose();
    noteController.dispose();
  }

  Color coloreStato(bool attivo) {
    return attivo ? Colors.green.shade700 : Colors.grey.shade600;
  }

  Widget badgeStato(bool attivo) {
    final testo = attivo ? 'Attiva' : 'Non attiva';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: attivo ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coloreStato(attivo)),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: coloreStato(attivo),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget statoVuoto() {
    return Center(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 56,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Privacy / GDPR 679/2016',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                soloAttive
                    ? 'Nessuna voce privacy/GDPR attiva inserita.'
                    : 'Nessuna voce privacy/GDPR inserita.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: mostraDialogNuovaVoce,
                icon: const Icon(Icons.add),
                label: const Text('Nuova voce'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tabellaPrivacy() {
    return Card(
      elevation: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
          columns: const [
            DataColumn(label: Text('Titolo')),
            DataColumn(label: Text('Titolare trattamento')),
            DataColumn(label: Text('Referente privacy')),
            DataColumn(label: Text('Base giuridica')),
            DataColumn(label: Text('Periodo conservazione')),
            DataColumn(label: Text('Stato')),
          ],
          rows: vociPrivacy.map((voce) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(voce.titolo, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      voce.titolareTrattamento ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 190,
                    child: Text(
                      voce.referentePrivacy ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      voce.baseGiuridica ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 210,
                    child: Text(
                      voce.periodoConservazione ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(badgeStato(voce.attivo)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totale = vociPrivacy.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy / GDPR 679/2016'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Text('Solo attive'),
                Switch(
                  value: soloAttive,
                  onChanged: (valore) {
                    setState(() {
                      soloAttive = valore;
                    });
                    caricaPrivacyGdpr();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: caricamento
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            color: Colors.blueGrey.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestione Privacy / GDPR 679/2016',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Archivio interno per informative, basi giuridiche, finalità, categorie dati, conservazione e misure di sicurezza.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: mostraDialogNuovaVoce,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuova voce'),
                          ),
                          const SizedBox(width: 12),
                          Chip(
                            avatar: const Icon(Icons.list_alt, size: 18),
                            label: Text(
                              soloAttive
                                  ? '$totale voci attive'
                                  : '$totale voci totali',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: vociPrivacy.isEmpty
                        ? statoVuoto()
                        : tabellaPrivacy(),
                  ),
                ],
              ),
      ),
    );
  }
}
