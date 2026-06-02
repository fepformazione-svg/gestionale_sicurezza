import 'package:flutter/material.dart';

import '../models/discente.dart';
import '../models/impresa.dart';
import '../services/database_service.dart';
import 'discente_scheda_page.dart';
import '../dialogs/discente_dialog.dart' as dialogDiscente;

class ImpresaSchedaPage extends StatefulWidget {
  final Impresa impresa;

  const ImpresaSchedaPage({super.key, required this.impresa});

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
    final salvato = await dialogDiscente.apriDialogDiscente(
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
