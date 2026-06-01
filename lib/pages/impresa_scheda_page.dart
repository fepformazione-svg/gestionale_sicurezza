import 'package:flutter/material.dart';

import '../models/discente.dart';
import '../models/impresa.dart';
import '../services/database_service.dart';
import 'discente_scheda_page.dart';

class ImpresaSchedaPage extends StatefulWidget {
  final Impresa impresa;

  const ImpresaSchedaPage({
    super.key,
    required this.impresa,
  });

  @override
  State<ImpresaSchedaPage> createState() => _ImpresaSchedaPageState();
}

class _ImpresaSchedaPageState extends State<ImpresaSchedaPage> {
  List<Discente> discentiAssociati = [];

  @override
  void initState() {
    super.initState();
    caricaDiscentiAssociati();
  }

  Future<void> caricaDiscentiAssociati() async {
    final idImpresa = widget.impresa.id;
    if (idImpresa == null) return;

    final risultato =
        await DatabaseService.instance.getDiscentiByImpresaId(idImpresa);

    if (!mounted) return;

    setState(() {
      discentiAssociati = risultato;
    });
  }

  String valore(String? testo) {
    final v = testo?.trim() ?? '';
    return v.isEmpty ? '-' : v;
  }

  void modificaImpresa(BuildContext context) {
    Navigator.pop(context, 'modifica');
  }

  Future<void> apriSchedaDiscente(Discente discente) async {
    final risultato = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscenteSchedaPage(discente: discente),
      ),
    );

    if (risultato == 'modifica') {
      await apriDialogDiscente(discente: discente);
    }

    await caricaDiscentiAssociati();
  }

  Future<void> apriDialogDiscente({Discente? discente}) async {
    final nomeController = TextEditingController(text: discente?.nome ?? '');
    final cognomeController = TextEditingController(
      text: discente?.cognome ?? '',
    );

    final luogoController = TextEditingController(
      text: discente?.luogoNascita ?? '',
    );
    final dataController = TextEditingController(
      text: discente?.dataNascita ?? '',
    );
    final cfController = TextEditingController(
      text: discente?.codiceFiscale ?? '',
    );

    final dataVisitaController = TextEditingController(
      text: discente?.dataVisitaMedica ?? '',
    );
    final scadenzaVisitaController = TextEditingController(
      text: discente?.scadenzaVisitaMedica ?? '',
    );

    bool visitaMedicaSvolta = (discente?.visitaMedicaSvolta ?? 0) == 1;

    int? impresaId = discente?.impresaId ?? widget.impresa.id;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cognomeController,
                      decoration: const InputDecoration(
                        labelText: 'Cognome *',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: luogoController,
                      decoration: const InputDecoration(
                        labelText: 'Luogo nascita',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: dataController,
                      decoration: const InputDecoration(
                        labelText: 'Data nascita',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: cfController,
                      decoration: const InputDecoration(
                        labelText: 'Codice fiscale',
                      ),
                    ),

                    const SizedBox(height: 12),

                    CheckboxListTile(
                      value: visitaMedicaSvolta,
                      title: const Text('Visita medica svolta'),
                      onChanged: (value) {
                        setDialogState(() {
                          visitaMedicaSvolta = value ?? false;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: dataVisitaController,
                      decoration: const InputDecoration(
                        labelText: 'Data visita',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: scadenzaVisitaController,
                      decoration: const InputDecoration(
                        labelText: 'Scadenza visita',
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salva'),
                      onPressed: () async {
                        final nome = nomeController.text.trim();
                        final cognome = cognomeController.text.trim();

                        if (nome.isEmpty || cognome.isEmpty) {
                          return;
                        }

                        final datiDiscente = Discente(
                          id: discente?.id,
                          nome: nome,
                          cognome: cognome,
                          luogoNascita: luogoController.text.trim(),
                          dataNascita: dataController.text.trim(),
                          codiceFiscale: cfController.text.trim(),
                          impresaId: impresaId,
                          visitaMedicaSvolta: visitaMedicaSvolta ? 1 : 0,
                          dataVisitaMedica: dataVisitaController.text.trim(),
                          scadenzaVisitaMedica: scadenzaVisitaController.text.trim(),
                        );

                        if (discente == null) {
                          await DatabaseService.instance.insertDiscente(datiDiscente);
                        } else {
                          await DatabaseService.instance.updateDiscente(datiDiscente);
                        }

                        if (!context.mounted) return;

                        Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (salvato == true) {
      await caricaDiscentiAssociati();
    }
  }
  @override
  Widget build(BuildContext context) {
    final impresa = widget.impresa;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Scheda impresa'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Modifica impresa',
            onPressed: () => modificaImpresa(context),
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
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
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
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
              _InfoRiga(
                label: 'Referente',
                value: valore(impresa.referente),
              ),
              _InfoRiga(
                label: 'Telefono',
                value: valore(impresa.telefono),
              ),
              _InfoRiga(
                label: 'Indirizzo',
                value: valore(impresa.indirizzo),
              ),
              const SizedBox(height: 28),
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
                    onPressed: () => apriDialogDiscente(),
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
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final discente = discentiAssociati[index];

                          return InkWell(
                            onDoubleTap: () => apriSchedaDiscente(discente),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      discente.nomeCompleto,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Doppio click per aprire',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
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
    );
  }
}

class _InfoRiga extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRiga({
    required this.label,
    required this.value,
  });

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