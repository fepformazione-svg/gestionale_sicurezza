import 'package:flutter/material.dart';

import 'impresa_scheda_page.dart';

import '../models/impresa.dart';
import '../services/database_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class ImpresePage extends StatefulWidget {
  const ImpresePage({super.key});

  @override
  State<ImpresePage> createState() => _ImpresePageState();
}

class _ImpresePageState extends State<ImpresePage> {
  List<Impresa> imprese = [];
  List<Impresa> impreseFiltrate = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    caricaImprese();
  }

  Future<void> caricaImprese() async {
    final dati = await DatabaseService.instance.getImprese();

    setState(() {
      imprese = dati;
      impreseFiltrate = dati;
      loading = false;
    });
  }

  void cercaImprese(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      impreseFiltrate = imprese.where((i) {
        return i.intestazione.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> apriDialogNuovaImpresa() async {
    final ragioneSocialeController = TextEditingController();
    final partitaIvaController = TextEditingController();
    final codiceFiscaleController = TextEditingController();
    final indirizzoController = TextEditingController();
    final telefonoController = TextEditingController();
    final referenteController = TextEditingController();

    final risultato = await showDialog<Impresa>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
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
                  const Text(
                    'Nuova impresa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Inserisci i dati dell’impresa.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: ragioneSocialeController,
                    decoration: InputDecoration(
                      labelText: 'Ragione sociale *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: partitaIvaController,
                    decoration: InputDecoration(
                      labelText: 'Partita IVA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: codiceFiscaleController,
                    decoration: InputDecoration(
                      labelText: 'Codice fiscale',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: indirizzoController,
                    decoration: InputDecoration(
                      labelText: 'Indirizzo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(
                      labelText: 'Telefono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: referenteController,
                    decoration: InputDecoration(
                      labelText: 'Referente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annulla'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final nome = ragioneSocialeController.text.trim();

                          if (nome.isEmpty) return;

                          Navigator.pop(
                            context,
                            Impresa(
                              intestazione: nome,
                              partitaIva: partitaIvaController.text.trim(),
                              codiceFiscale: codiceFiscaleController.text
                                  .trim(),
                              indirizzo: indirizzoController.text.trim(),
                              telefono: telefonoController.text.trim(),
                              referente: referenteController.text.trim(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Salva impresa'),
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

    ragioneSocialeController.dispose();
    partitaIvaController.dispose();
    codiceFiscaleController.dispose();
    indirizzoController.dispose();
    telefonoController.dispose();
    referenteController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance.insertImpresa(risultato);
    await caricaImprese();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impresa salvata nel database')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Imprese',
            subtitle: 'Archivio aziende, clienti e anagrafiche operative.',
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: 'Cerca impresa...',
                  onChanged: cercaImprese,
                ),
              ),

              const SizedBox(width: 16),

              ElevatedButton.icon(
                onPressed: apriDialogNuovaImpresa,
                icon: const Icon(Icons.add),
                label: const Text('Nuova impresa'),
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
                                'Elenco imprese',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),

                            Text(
                              '${impreseFiltrate.length} record',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Expanded(
                          child: impreseFiltrate.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nessuna impresa presente',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: impreseFiltrate.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = impreseFiltrate[index];

                                    return InkWell(
                                      onDoubleTap: () async {
                                        final risultato = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ImpresaSchedaPage(
                                              impresa: item,
                                            ),
                                          ),
                                        );

                                        if (risultato == 'eliminata') {
                                          await caricaImprese();
                                        }

                                        if (risultato == 'modifica') {
                                          await apriDialogModificaImpresa(item);
                                          await caricaImprese();
                                        }
                                      },
                                      child: Container(
                                        height: 72,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.business_outlined,
                                              color: Color(0xFF2563EB),
                                            ),

                                            const SizedBox(width: 14),

                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.intestazione,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Color(0xFF111827),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 4),

                                                  Text(
                                                    [
                                                      if ((item.partitaIva ??
                                                              '')
                                                          .isNotEmpty)
                                                        'P.IVA: ${item.partitaIva}',
                                                      if ((item.codiceFiscale ??
                                                              '')
                                                          .isNotEmpty)
                                                        'CF: ${item.codiceFiscale}',
                                                      if ((item.telefono ?? '')
                                                          .isNotEmpty)
                                                        'Tel: ${item.telefono}',
                                                    ].join('   •   '),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
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
        ],
      ),
    );
  }

  Future<void> apriDialogModificaImpresa(Impresa impresa) async {
    final ragioneSocialeController = TextEditingController(
      text: impresa.intestazione,
    );
    final partitaIvaController = TextEditingController(
      text: impresa.partitaIva ?? '',
    );
    final codiceFiscaleController = TextEditingController(
      text: impresa.codiceFiscale ?? '',
    );
    final indirizzoController = TextEditingController(
      text: impresa.indirizzo ?? '',
    );
    final telefonoController = TextEditingController(
      text: impresa.telefono ?? '',
    );
    final referenteController = TextEditingController(
      text: impresa.referente ?? '',
    );

    final risultato = await showDialog<Impresa>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
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
                  const Text(
                    'Modifica impresa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Aggiorna i dati dell’impresa.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: ragioneSocialeController,
                    decoration: InputDecoration(
                      labelText: 'Ragione sociale *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: partitaIvaController,
                    decoration: InputDecoration(
                      labelText: 'Partita IVA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: codiceFiscaleController,
                    decoration: InputDecoration(
                      labelText: 'Codice fiscale',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: indirizzoController,
                    decoration: InputDecoration(
                      labelText: 'Indirizzo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(
                      labelText: 'Telefono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: referenteController,
                    decoration: InputDecoration(
                      labelText: 'Referente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annulla'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final nome = ragioneSocialeController.text.trim();

                          if (nome.isEmpty) return;

                          Navigator.pop(
                            context,
                            Impresa(
                              id: impresa.id,
                              intestazione: nome,
                              partitaIva: partitaIvaController.text.trim(),
                              codiceFiscale: codiceFiscaleController.text
                                  .trim(),
                              indirizzo: indirizzoController.text.trim(),
                              telefono: telefonoController.text.trim(),
                              referente: referenteController.text.trim(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Salva modifiche'),
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

    ragioneSocialeController.dispose();
    partitaIvaController.dispose();
    codiceFiscaleController.dispose();
    indirizzoController.dispose();
    telefonoController.dispose();
    referenteController.dispose();

    if (risultato == null) return;

    await DatabaseService.instance.updateImpresa(risultato);
    await caricaImprese();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impresa modificata correttamente')),
    );
  }
}
