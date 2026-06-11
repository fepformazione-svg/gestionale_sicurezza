import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/discente.dart';
import '../services/database_service.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DiscenteSchedaPage extends StatefulWidget {
  final Discente discente;

  const DiscenteSchedaPage({super.key, required this.discente});

  @override
  State<DiscenteSchedaPage> createState() => _DiscenteSchedaPageState();
}

class _DiscenteSchedaPageState extends State<DiscenteSchedaPage> {
  bool caricamento = true;
  bool eliminazioneCorsiInCorso = false;
  List<Map<String, dynamic>> storico = [];
  List<Map<String, dynamic>> storicoFiltrato = [];

  String filtroStorico = 'tutti';

  void mostraSnackBarSuccesso(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messaggio,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void mostraSnackBarErrore(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messaggio,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String ultimaColonnaOrdinamentoStorico = 'data';
  static bool ultimoOrdinamentoStoricoAscendente = false;

  late String colonnaOrdinamentoStorico;
  late bool ordinamentoStoricoAscendente;

  int? storicoSelezionato;
  int? indiceHoverStorico;

  final Set<int> storiciSelezionati = {};
  int? ultimoStoricoSelezionato;

  bool selezioneStoricoValida() {
    if (storiciSelezionati.isEmpty) return false;

    return storiciSelezionati.every(
      (index) => index >= 0 && index < storicoFiltrato.length,
    );
  }

  final TextEditingController _cercaStoricoController = TextEditingController();

  void apriDettaglioStorico(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (context) {
        final stato = statoScadenzaCorso(r['scadenza']);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(30, 18, 30, 14),
          actionsPadding: const EdgeInsets.fromLTRB(24, 6, 24, 20),

          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Dettaglio corso',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    valore(r['corso']),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                _rigaDettaglioStorico('Data corso', formattaData(r['data'])),
                _rigaDettaglioStorico(
                  'Scadenza',
                  formattaData(r['scadenza']),
                  stato: stato,
                ),
                _rigaDettaglioStorico('Ore', '${valore(r['durata_ore'])} h'),
                _rigaStatoDettaglioStorico(stato),
              ],
            ),
          ),

          actions: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Chiudi'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.hovered)) {
                      return const Color(0xFF1D4ED8);
                    }
                    return const Color(0xFF2563EB);
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(0),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _rigaDettaglioStorico(
    String etichetta,
    String valore, {
    String? stato,
  }) {
    final bool evidenziaScadenza = etichetta == 'Scadenza';

    Color coloreSfondo = const Color(0xFFFFFFFF);
    Color coloreBordo = const Color(0xFFE2E8F0);

    if (evidenziaScadenza) {
      if (stato == 'SCADUTO') {
        coloreSfondo = const Color(0xFFFEF2F2);
        coloreBordo = const Color(0xFFFECACA);
      } else if (stato == 'IN SCADENZA') {
        coloreSfondo = const Color(0xFFFFF7ED);
        coloreBordo = const Color(0xFFFED7AA);
      } else {
        coloreSfondo = const Color(0xFFF0FDF4);
        coloreBordo = const Color(0xFFBBF7D0);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: coloreSfondo,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: coloreBordo),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              etichetta,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                valore,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rigaStatoDettaglioStorico(String stato) {
    Color coloreSfondo;
    Color coloreTesto;
    IconData icona;

    if (stato == 'SCADUTO') {
      coloreSfondo = const Color(0xFFFEE2E2);
      coloreTesto = const Color(0xFFB91C1C);
      icona = Icons.error_outline;
    } else if (stato == 'IN SCADENZA') {
      coloreSfondo = const Color(0xFFFFF7ED);
      coloreTesto = const Color(0xFFC2410C);
      icona = Icons.warning_amber_rounded;
    } else {
      coloreSfondo = const Color(0xFFDCFCE7);
      coloreTesto = const Color(0xFF15803D);
      icona = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 125,
            child: Text(
              'Stato',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: coloreSfondo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icona, size: 15, color: coloreTesto),
                    const SizedBox(width: 6),
                    Text(
                      stato,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: coloreTesto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    colonnaOrdinamentoStorico = ultimaColonnaOrdinamentoStorico;
    ordinamentoStoricoAscendente = ultimoOrdinamentoStoricoAscendente;

    caricaStorico();
  }

  Future<void> caricaStorico() async {
    final id = widget.discente.id;

    if (id == null) {
      setState(() {
        storico = [];
        storicoFiltrato = [];
        caricamento = false;
      });
      return;
    }

    final dati = await DatabaseService.instance.getStoricoDiscente(id);

    if (!mounted) return;

    setState(() {
      storico = dati;
      storicoFiltrato = List.from(dati);
      caricamento = false;
    });
  }

  void filtraStorico(String testo) {
    applicaFiltroStorico();
  }

  void azzeraFiltroStorico() {
    setState(() {
      filtroStorico = 'tutti';
      _cercaStoricoController.clear();
      storicoFiltrato = List.from(storico);

      storiciSelezionati.clear();
      storicoSelezionato = null;
      ultimoStoricoSelezionato = null;
      indiceHoverStorico = null;
    });
  }

  void applicaFiltroStorico() {
    final bool esistonoValidi = storico.any(
      (r) => statoScadenzaCorso(r['scadenza']) == 'VALIDO',
    );

    final bool esistonoInScadenza = storico.any(
      (r) => statoScadenzaCorso(r['scadenza']) == 'IN SCADENZA',
    );

    final bool esistonoScaduti = storico.any(
      (r) => statoScadenzaCorso(r['scadenza']) == 'SCADUTO',
    );

    if (filtroStorico == 'validi' && !esistonoValidi) {
      filtroStorico = 'tutti';
    }

    if (filtroStorico == 'in_scadenza' && !esistonoInScadenza) {
      filtroStorico = 'tutti';
    }

    if (filtroStorico == 'scaduti' && !esistonoScaduti) {
      filtroStorico = 'tutti';
    }
    final ricerca = _cercaStoricoController.text.toLowerCase().trim();

    setState(() {
      storicoFiltrato = storico.where((riga) {
        final corso = (riga['corso'] ?? '').toString().toLowerCase();

        final passaRicerca = ricerca.isEmpty || corso.contains(ricerca);

        bool passaFiltro = true;

        switch (filtroStorico) {
          case 'validi':
            passaFiltro = statoScadenzaCorso(riga['scadenza']) == 'VALIDO';
            break;

          case 'in_scadenza':
            passaFiltro = statoScadenzaCorso(riga['scadenza']) == 'IN SCADENZA';
            break;

          case 'scaduti':
            passaFiltro = statoScadenzaCorso(riga['scadenza']) == 'SCADUTO';
            break;
        }

        return passaRicerca && passaFiltro;
      }).toList();

      storicoFiltrato.sort((a, b) {
        int confronto = 0;

        switch (colonnaOrdinamentoStorico) {
          case 'corso':
            confronto = (a['corso'] ?? '').toString().toLowerCase().compareTo(
              (b['corso'] ?? '').toString().toLowerCase(),
            );
            break;

          case 'data':
            confronto = leggiDataStorico(
              a['data'],
            ).compareTo(leggiDataStorico(b['data']));
            break;

          case 'scadenza':
            confronto = leggiDataStorico(
              a['scadenza'],
            ).compareTo(leggiDataStorico(b['scadenza']));
            break;

          case 'ore':
            confronto = ((a['ore'] ?? 0) as num).compareTo(
              (b['ore'] ?? 0) as num,
            );
            break;
        }

        return ordinamentoStoricoAscendente ? confronto : -confronto;
      });

      storiciSelezionati.clear();
      storicoSelezionato = null;
      ultimoStoricoSelezionato = null;
      indiceHoverStorico = null;
    });
  }

  DateTime leggiDataStorico(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';

    final parti = testo.split('/');
    if (parti.length == 3) {
      final giorno = int.tryParse(parti[0]);
      final mese = int.tryParse(parti[1]);
      final anno = int.tryParse(parti[2]);

      if (giorno != null && mese != null && anno != null) {
        return DateTime(anno, mese, giorno);
      }
    }

    return DateTime.tryParse(testo) ?? DateTime(1900);
  }

  void ordinaStorico(String colonna) {
    DateTime leggiDataStorico(dynamic valore) {
      final testo = valore?.toString().trim() ?? '';

      if (testo.isEmpty) {
        return DateTime(1900);
      }

      final parti = testo.split('/');
      if (parti.length == 3) {
        final giorno = int.tryParse(parti[0]);
        final mese = int.tryParse(parti[1]);
        final anno = int.tryParse(parti[2]);

        if (giorno != null && mese != null && anno != null) {
          return DateTime(anno, mese, giorno);
        }
      }

      return DateTime.tryParse(testo) ?? DateTime(1900);
    }

    String valore(dynamic valore) {
      return valore?.toString().trim() ?? '';
    }

    setState(() {
      if (colonnaOrdinamentoStorico == colonna) {
        ordinamentoStoricoAscendente = !ordinamentoStoricoAscendente;
      } else {
        colonnaOrdinamentoStorico = colonna;
        ordinamentoStoricoAscendente = true;
      }

      ultimaColonnaOrdinamentoStorico = colonnaOrdinamentoStorico;
      ultimoOrdinamentoStoricoAscendente = ordinamentoStoricoAscendente;

      storicoFiltrato.sort((a, b) {
        int risultato = 0;

        switch (colonna) {
          case 'corso':
            risultato = valore(
              a['corso'],
            ).toLowerCase().compareTo(valore(b['corso']).toLowerCase());

            if (risultato == 0) {
              risultato = leggiDataStorico(
                a['data'],
              ).compareTo(leggiDataStorico(b['data']));
            }
            break;

          case 'data':
            risultato = leggiDataStorico(
              a['data'],
            ).compareTo(leggiDataStorico(b['data']));

            if (risultato == 0) {
              risultato = valore(
                a['corso'],
              ).toLowerCase().compareTo(valore(b['corso']).toLowerCase());
            }
            break;

          case 'scadenza':
            risultato = leggiDataStorico(
              a['scadenza'],
            ).compareTo(leggiDataStorico(b['scadenza']));

            if (risultato == 0) {
              risultato = valore(
                a['corso'],
              ).toLowerCase().compareTo(valore(b['corso']).toLowerCase());
            }
            break;

          case 'ore':
            final oreA =
                num.tryParse(valore(a['durata_ore']).replaceAll(',', '.')) ?? 0;

            final oreB =
                num.tryParse(valore(b['durata_ore']).replaceAll(',', '.')) ?? 0;

            risultato = oreA.compareTo(oreB);

            if (risultato == 0) {
              risultato = valore(
                a['corso'],
              ).toLowerCase().compareTo(valore(b['corso']).toLowerCase());
            }
            break;
        }

        return ordinamentoStoricoAscendente ? risultato : -risultato;
      });
      storiciSelezionati.clear();
      storicoSelezionato = null;
      ultimoStoricoSelezionato = null;
      indiceHoverStorico = null;
    });
  }

  void mostraTuttiICorsi() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF2563EB),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Storico formativo completo',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Chiudi',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  storico.length == 1
                      ? 'Visualizzato 1 corso'
                      : 'Visualizzati ${storico.length} corsi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _StoricoHeaderCell(
                          'Corso',
                          attiva: colonnaOrdinamentoStorico == 'corso',
                          crescente: ordinamentoStoricoAscendente,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _StoricoHeaderCell(
                          'Data corso',
                          attiva: colonnaOrdinamentoStorico == 'data',
                          crescente: ordinamentoStoricoAscendente,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _StoricoHeaderCell(
                          'Scadenza',
                          attiva: colonnaOrdinamentoStorico == 'scadenza',
                          crescente: ordinamentoStoricoAscendente,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _StoricoHeaderCell(
                          'Ore',
                          attiva: colonnaOrdinamentoStorico == 'ore',
                          crescente: ordinamentoStoricoAscendente,
                        ),
                      ),
                      Expanded(flex: 2, child: _StoricoHeaderCell('Stato')),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    itemCount: storico.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final r = storico[index];
                      final stato = statoScadenzaCorso(r['scadenza']);

                      return GestureDetector(
                        onTap: eliminazioneCorsiInCorso
                            ? null
                            : () {
                                setState(() {
                                  storicoSelezionato = index;
                                  ultimoStoricoSelezionato = index;

                                  if (storiciSelezionati.contains(index)) {
                                    storiciSelezionati.remove(index);
                                  } else {
                                    storiciSelezionati.add(index);
                                  }
                                });
                              },
                        onDoubleTap: () {
                          final corso = valore(r['corso']);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Corso selezionato: $corso'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            if (eliminazioneCorsiInCorso) return;

                            setState(() {
                              indiceHoverStorico = index;
                            });
                          },
                          onExit: (_) {
                            if (eliminazioneCorsiInCorso) return;

                            setState(() {
                              indiceHoverStorico = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              color: storiciSelezionati.contains(index)
                                  ? eliminazioneCorsiInCorso
                                        ? const Color(0xFFFFF7ED)
                                        : const Color(0xFFEAF2FF)
                                  : indiceHoverStorico == index &&
                                        !eliminazioneCorsiInCorso
                                  ? const Color(0xFFF5F9FF)
                                  : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: storiciSelezionati.contains(index)
                                      ? eliminazioneCorsiInCorso
                                            ? const Color(0xFFF97316)
                                            : const Color(0xFF2563EB)
                                      : indiceHoverStorico == index &&
                                            !eliminazioneCorsiInCorso
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  width: storiciSelezionati.contains(index)
                                      ? 4
                                      : 3,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    valore(r['corso']),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formattaData(r['data']),
                                    style: const TextStyle(
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formattaData(r['scadenza']),
                                    style: const TextStyle(
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${valore(r['durata_ore'])} h',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sfondoStatoCorso(stato),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        stato,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: coloreStatoCorso(stato),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> eliminaDiscente() async {
    final id = widget.discente.id;
    if (id == null) return;

    final haCollegamenti = await DatabaseService.instance
        .discenteHaCollegamenti(id);

    if (!mounted) return;

    if (haCollegamenti) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Impossibile eliminare'),
            content: const Text(
              'Il discente non può essere eliminato perché sono presenti corsi, prenotazioni o scadenze collegate.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok'),
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
          title: const Text('Elimina discente'),
          content: Text(
            'Vuoi eliminare definitivamente ${widget.discente.nome} ${widget.discente.cognome}?',
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

    final haStorico = await DatabaseService.instance.discenteHaStorico(id);

    if (haStorico) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Eliminazione bloccata'),
            content: const Text(
              'Non è possibile eliminare questo discente perché sono presenti corsi o dati storici associati.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );

      return;
    }

    try {
      await DatabaseService.instance.deleteDiscente(id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Errore eliminazione'),
            content: Text(
              'Non è stato possibile eliminare il discente.\n\nDettaglio: $e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }

  String valore(dynamic v) {
    final testo = v?.toString().trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  DateTime? parseData(dynamic valore) {
    final testo = valore?.toString().trim() ?? '';
    if (testo.isEmpty) return null;

    if (testo.contains('/')) {
      final parti = testo.split('/');
      if (parti.length == 3) {
        return DateTime.tryParse(
          '${parti[2]}-${parti[1].padLeft(2, '0')}-${parti[0].padLeft(2, '0')}',
        );
      }
    }

    return DateTime.tryParse(testo);
  }

  String formattaData(dynamic valore) {
    final data = parseData(valore);

    if (data == null) return '-';

    final giorno = data.day.toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final anno = data.year.toString();

    return '$giorno/$mese/$anno';
  }

  String statoScadenzaCorso(dynamic scadenza) {
    final data = parseData(scadenza);

    if (data == null) return 'SENZA SCADENZA';

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(data.year, data.month, data.day);

    final giorni = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorni < 0) return 'SCADUTO';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDO';
  }

  Color coloreStatoCorso(String stato) {
    switch (stato) {
      case 'VALIDO':
        return const Color(0xFF16A34A);
      case 'IN SCADENZA':
        return const Color(0xFFF59E0B);
      case 'SCADUTO':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color sfondoStatoCorso(String stato) {
    switch (stato) {
      case 'VALIDO':
        return const Color(0xFFEAF7EE);
      case 'IN SCADENZA':
        return const Color(0xFFFFF7E6);
      case 'SCADUTO':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String pulisciNomeFile(String valore) {
    return valore
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-]'), '');
  }

  Future<void> esportaCorsiSelezionatiExcel() async {
    if (!selezioneStoricoValida()) {
      mostraSnackBarErrore(
        'Nessun corso valido da esportare. Aggiorna la selezione e riprova.',
      );
      return;
    }

    if (eliminazioneCorsiInCorso) {
      mostraSnackBarErrore(
        'Attendi il completamento dell’eliminazione prima di esportare.',
      );
      return;
    }

    final corsiDaEsportare = storiciSelezionati
        .map((index) => storicoFiltrato[index])
        .toList();

    if (corsiDaEsportare.isEmpty) return;

    try {
      final cognomeFile = pulisciNomeFile(widget.discente.cognome);
      final nomeFileDiscente = pulisciNomeFile(widget.discente.nome);
      final oggi = DateTime.now();

      final nomeFile =
          '${cognomeFile}_${nomeFileDiscente}_'
          '${corsiDaEsportare.length}_'
          '${corsiDaEsportare.length == 1 ? 'corso' : 'corsi'}_'
          '${oggi.year}-'
          '${oggi.month.toString().padLeft(2, '0')}-'
          '${oggi.day.toString().padLeft(2, '0')}';

      final fileExcel = excel.Excel.createExcel();
      final sheet = fileExcel['Storico Formativo'];
      sheet.appendRow([
        excel.TextCellValue('Corso'),
        excel.TextCellValue('Data corso'),
        excel.TextCellValue('Scadenza'),
        excel.TextCellValue('Ore'),
        excel.TextCellValue('Stato'),
      ]);

      final headerStyle = excel.CellStyle(
        bold: true,
        fontColorHex: excel.ExcelColor.white,
        backgroundColorHex: excel.ExcelColor.blue,
        horizontalAlign: excel.HorizontalAlign.Center,
      );

      for (int col = 0; col < 5; col++) {
        sheet
                .cell(
                  excel.CellIndex.indexByColumnRow(
                    columnIndex: col,
                    rowIndex: 0,
                  ),
                )
                .cellStyle =
            headerStyle;
      }

      sheet.setColumnWidth(0, 32); // Corso
      sheet.setColumnWidth(1, 14); // Data corso
      sheet.setColumnWidth(2, 14); // Scadenza
      sheet.setColumnWidth(3, 10); // Ore
      sheet.setColumnWidth(4, 14); // Stato

      for (final corso in corsiDaEsportare) {
        final stato = statoScadenzaCorso(corso['scadenza']);

        sheet.appendRow([
          excel.TextCellValue(valore(corso['corso'])),
          excel.TextCellValue(formattaData(corso['data'])),
          excel.TextCellValue(formattaData(corso['scadenza'])),
          excel.TextCellValue('${valore(corso['durata_ore'])} h'),
          excel.TextCellValue(stato),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$nomeFile.xlsx';

      final bytes = fileExcel.encode();
      if (bytes == null) return;

      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      mostraSnackBarSuccesso('Excel esportato correttamente');

      await Future.delayed(const Duration(milliseconds: 400));
      await OpenFile.open(path);
    } catch (e) {
      mostraSnackBarErrore('Errore durante l’esportazione Excel. Riprova.');
    }
  }

  Future<void> esportaCorsiSelezionatiPdf() async {
    if (!selezioneStoricoValida()) {
      mostraSnackBarErrore(
        'Nessun corso valido da esportare. Aggiorna la selezione e riprova.',
      );
      return;
    }

    if (eliminazioneCorsiInCorso) {
      mostraSnackBarErrore(
        'Attendi il completamento dell’eliminazione prima di esportare.',
      );
      return;
    }

    final corsiDaEsportare = storiciSelezionati
        .map((index) => storicoFiltrato[index])
        .toList();

    if (corsiDaEsportare.isEmpty) return;

    try {
      final pdf = pw.Document();

      final dataEsportazione =
          '${DateTime.now().day.toString().padLeft(2, '0')}/'
          '${DateTime.now().month.toString().padLeft(2, '0')}/'
          '${DateTime.now().year}';

      final totaleCorsi = corsiDaEsportare.length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'F&P Formazione e Prevenzione',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Export storico formativo',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Documento generato dal gestionale F&P',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Pagina ${context.pageNumber} di ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          build: (context) => [
            pw.Text(
              '${widget.discente.cognome} ${widget.discente.nome}',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Data esportazione: $dataEsportazione',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              totaleCorsi == 1
                  ? 'Totale corsi esportati: 1'
                  : 'Totale corsi esportati: $totaleCorsi',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: ['Corso', 'Data corso', 'Scadenza', 'Ore', 'Stato'],
              data: corsiDaEsportare.map((corso) {
                final stato = statoScadenzaCorso(corso['scadenza']);

                return [
                  valore(corso['corso']),
                  formattaData(corso['data']),
                  formattaData(corso['scadenza']),
                  valore(corso['durata_ore']),
                  stato,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(1.3),
              },
            ),
          ],
        ),
      );

      final cognomeFile = pulisciNomeFile(widget.discente.cognome);
      final nomeFileDiscente = pulisciNomeFile(widget.discente.nome);
      final oggi = DateTime.now();

      final nomeFilePdf =
          '${cognomeFile}_${nomeFileDiscente}_'
          '${corsiDaEsportare.length}_'
          '${corsiDaEsportare.length == 1 ? 'corso' : 'corsi'}_'
          '${oggi.year}-'
          '${oggi.month.toString().padLeft(2, '0')}-'
          '${oggi.day.toString().padLeft(2, '0')}_pdf';

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$nomeFilePdf.pdf';

      final file = File(path);
      await file.writeAsBytes(await pdf.save(), flush: true);

      if (!mounted) return;

      mostraSnackBarSuccesso('PDF esportato correttamente');

      await Future.delayed(const Duration(milliseconds: 400));
      await OpenFile.open(path);
    } catch (e) {
      mostraSnackBarErrore('Errore durante l’esportazione PDF. Riprova.');
    }
  }

  Future<void> eliminaCorsiSelezionati() async {
    if (eliminazioneCorsiInCorso) return;

    if (!selezioneStoricoValida()) {
      mostraSnackBarErrore(
        'Nessun corso valido da eliminare. Aggiorna la selezione e riprova.',
      );
      return;
    }

    final corsiSelezionatiValidi = storiciSelezionati
        .where((index) => index >= 0 && index < storicoFiltrato.length)
        .map((index) => storicoFiltrato[index])
        .toList();

    if (corsiSelezionatiValidi.isEmpty) {
      if (!mounted) return;

      setState(() {
        storiciSelezionati.clear();
        storicoSelezionato = null;
        ultimoStoricoSelezionato = null;
        indiceHoverStorico = null;
      });

      mostraSnackBarErrore(
        'Nessun corso selezionato valido. Aggiorna lo storico e riprova.',
      );

      return;
    }

    if (corsiSelezionatiValidi.isEmpty) return;

    final numeroCorsi = corsiSelezionatiValidi.length;

    final conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 18,
          shadowColor: const Color(0x33000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(30, 22, 30, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(30, 14, 30, 20),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Conferma eliminazione',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numeroCorsi == 1
                      ? 'Stai per eliminare 1 corso dallo storico formativo del discente.'
                      : 'Stai per eliminare $numeroCorsi corsi dallo storico formativo del discente.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFB86A),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFC2410C),
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          numeroCorsi == 1
                              ? 'L’operazione eliminerà definitivamente il corso selezionato.'
                              : 'L’operazione eliminerà definitivamente tutti i corsi selezionati.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Questa azione non può essere annullata.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Annulla'),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFF0F172A);
                  }
                  return const Color(0xFF475569);
                }),
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFFF1F5F9);
                  }
                  return Colors.transparent;
                }),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontWeight: FontWeight.w700),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(numeroCorsi == 1 ? 'Elimina corso' : 'Elimina corsi'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFFB91C1C);
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return const Color(0xFF991B1B);
                  }
                  return const Color(0xFFDC2626);
                }),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(0),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontWeight: FontWeight.w800),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (conferma != true) return;

    setState(() {
      eliminazioneCorsiInCorso = true;
      indiceHoverStorico = null;
      storicoSelezionato = null;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    try {
      final idsDaEliminare = corsiSelezionatiValidi
          .where((r) => r['id'] != null)
          .map((r) => r['id'] as int)
          .toList();

      if (idsDaEliminare.isEmpty) {
        if (!mounted) return;

        setState(() {
          storiciSelezionati.clear();
          storicoSelezionato = null;
          ultimoStoricoSelezionato = null;
          indiceHoverStorico = null;
          eliminazioneCorsiInCorso = false;
        });

        mostraSnackBarErrore(
          'Impossibile eliminare i corsi selezionati. Aggiorna lo storico e riprova.',
        );

        return;
      }

      await DatabaseService.instance.deleteStoriciByIds(idsDaEliminare);

      await caricaStorico();

      applicaFiltroStorico();

      if (!mounted) return;

      setState(() {
        storiciSelezionati.clear();
        storicoSelezionato = null;
        ultimoStoricoSelezionato = null;
        indiceHoverStorico = null;
        eliminazioneCorsiInCorso = false;
      });

      mostraSnackBarSuccesso(
        numeroCorsi == 1
            ? '1 corso eliminato correttamente'
            : '$numeroCorsi corsi eliminati correttamente',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        storicoSelezionato = null;
        ultimoStoricoSelezionato = null;
        indiceHoverStorico = null;
        eliminazioneCorsiInCorso = false;
      });

      mostraSnackBarErrore(
        numeroCorsi == 1
            ? 'Errore durante l’eliminazione del corso selezionato. Riprova.'
            : 'Errore durante l’eliminazione dei corsi selezionati. Riprova.',
      );
    }
  }

  String etichettaFiltroStorico(String filtro) {
    switch (filtro) {
      case 'validi':
      case 'valido':
        return 'Validi';

      case 'in_scadenza':
      case 'inScadenza':
      case 'in scadenza':
        return 'In scadenza';

      case 'scaduti':
      case 'scaduto':
        return 'Scaduti';

      case 'tutti':
        return 'Tutti';

      default:
        return filtro;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.discente;

    final totaleCorsi = storico.length;
    final corsiValidi = storico
        .where((r) => statoScadenzaCorso(r['scadenza']) == 'VALIDO')
        .length;
    final corsiInScadenza = storico
        .where((r) => statoScadenzaCorso(r['scadenza']) == 'IN SCADENZA')
        .length;
    final corsiScaduti = storico
        .where((r) => statoScadenzaCorso(r['scadenza']) == 'SCADUTO')
        .length;

    final filtroAttivo =
        filtroStorico != 'tutti' ||
        _cercaStoricoController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          '${d.nome} ${d.cognome}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: eliminazioneCorsiInCorso
                ? 'Modifica disabilitata durante l’eliminazione'
                : 'Modifica',
            icon: Icon(
              Icons.edit_outlined,
              color: eliminazioneCorsiInCorso
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF2563EB),
            ),
            onPressed: eliminazioneCorsiInCorso
                ? null
                : () {
                    Navigator.pop(context, 'modifica');
                  },
          ),
          IconButton(
            tooltip: eliminazioneCorsiInCorso
                ? 'Elimina disabilitato durante l’eliminazione'
                : 'Elimina',
            icon: Icon(
              Icons.delete_outline,
              color: eliminazioneCorsiInCorso
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFFDC2626),
            ),
            onPressed: eliminazioneCorsiInCorso ? null : eliminaDiscente,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnagraficaCard(discente: d),
            const SizedBox(height: 12),
            _SorveglianzaSanitariaCard(discente: d),
            const SizedBox(height: 14),
            const Text(
              'Storico formativo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                Tooltip(
                  message: eliminazioneCorsiInCorso
                      ? 'Azione disabilitata durante l’eliminazione'
                      : totaleCorsi == 0
                      ? 'Nessun corso presente'
                      : 'Mostra tutti i corsi',
                  waitDuration: const Duration(milliseconds: 500),
                  child: MouseRegion(
                    cursor: eliminazioneCorsiInCorso
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: InkWell(
                      onTap: eliminazioneCorsiInCorso || totaleCorsi == 0
                          ? null
                          : () {
                              filtroStorico = 'tutti';
                              applicaFiltroStorico();

                              mostraTuttiICorsi();
                            },
                      child: _StoricoKpiCard(
                        titolo: 'Totale corsi',
                        valore: totaleCorsi.toString(),
                        colore: const Color(0xFF2563EB),
                        attivo: filtroStorico == 'tutti' && totaleCorsi > 0,
                        disabilitato: totaleCorsi == 0,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: eliminazioneCorsiInCorso
                      ? 'Azione disabilitata durante l’eliminazione'
                      : corsiValidi == 0
                      ? 'Nessun corso valido presente'
                      : 'Mostra corsi validi',
                  waitDuration: const Duration(milliseconds: 500),
                  child: MouseRegion(
                    cursor: eliminazioneCorsiInCorso || totaleCorsi == 0
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: InkWell(
                      onTap: eliminazioneCorsiInCorso || corsiValidi == 0
                          ? null
                          : () {
                              filtroStorico = 'validi';
                              applicaFiltroStorico();
                            },
                      child: _StoricoKpiCard(
                        titolo: 'Validi',
                        valore: corsiValidi.toString(),
                        colore: const Color(0xFF16A34A),
                        attivo: filtroStorico == 'validi',
                        disabilitato: corsiValidi == 0,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: eliminazioneCorsiInCorso
                      ? 'Azione disabilitata durante l’eliminazione'
                      : corsiInScadenza == 0
                      ? 'Nessun corso in scadenza presente'
                      : 'Mostra corsi in scadenza',
                  waitDuration: const Duration(milliseconds: 500),
                  child: MouseRegion(
                    cursor: eliminazioneCorsiInCorso || corsiInScadenza == 0
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: InkWell(
                      onTap: eliminazioneCorsiInCorso || corsiInScadenza == 0
                          ? null
                          : () {
                              filtroStorico = 'in_scadenza';
                              applicaFiltroStorico();
                            },
                      child: _StoricoKpiCard(
                        titolo: 'In scadenza',
                        valore: corsiInScadenza.toString(),
                        colore: const Color(0xFFF59E0B),
                        attivo: filtroStorico == 'in_scadenza',
                        disabilitato: corsiInScadenza == 0,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: eliminazioneCorsiInCorso
                      ? 'Azione disabilitata durante l’eliminazione'
                      : corsiScaduti == 0
                      ? 'Nessun corso scaduto presente'
                      : 'Mostra corsi scaduti',
                  waitDuration: const Duration(milliseconds: 500),
                  child: MouseRegion(
                    cursor: eliminazioneCorsiInCorso || corsiScaduti == 0
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: InkWell(
                      onTap: eliminazioneCorsiInCorso || corsiScaduti == 0
                          ? null
                          : () {
                              filtroStorico = 'scaduti';
                              applicaFiltroStorico();
                            },
                      child: _StoricoKpiCard(
                        titolo: 'Scaduti',
                        valore: corsiScaduti.toString(),
                        colore: const Color(0xFFDC2626),
                        attivo: filtroStorico == 'scaduti' && corsiScaduti > 0,
                        disabilitato: corsiScaduti == 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: _cercaStoricoController.text.trim().isNotEmpty
                      ? 430
                      : 400,
                  child: TextField(
                    controller: _cercaStoricoController,
                    enabled: !eliminazioneCorsiInCorso,
                    onChanged: filtraStorico,
                    decoration: InputDecoration(
                      // qui resta tutto quello che hai già modificato
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                    );
                  },
                  child: _cercaStoricoController.text.trim().isNotEmpty
                      ? Padding(
                          key: const ValueKey('ricerca-attiva'),
                          padding: const EdgeInsets.only(left: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Ricerca attiva',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('ricerca-non-attiva'),
                          width: 0,
                        ),
                ),

                if (filtroAttivo) ...[
                  const SizedBox(width: 12),

                  OutlinedButton.icon(
                    onPressed: eliminazioneCorsiInCorso
                        ? null
                        : azzeraFiltroStorico,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Azzera filtro',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: child,
                          ),
                        );
                      },
                      child: _cercaStoricoController.text.trim().isNotEmpty
                          ? Container(
                              key: const ValueKey('badge-risultati-ricerca'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.manage_search_rounded,
                                    size: 18,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    storicoFiltrato.length == 1
                                        ? 'Trovato 1 corso'
                                        : 'Trovati ${storicoFiltrato.length} corsi',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              key: const ValueKey('testo-risultati-normale'),
                              storicoFiltrato.length == 1
                                  ? 'Visualizzato 1 corso'
                                  : 'Visualizzati ${storicoFiltrato.length} corsi',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                    ),

                    const SizedBox(width: 16),

                    TextButton.icon(
                      onPressed:
                          eliminazioneCorsiInCorso ||
                              storicoFiltrato.isEmpty ||
                              storiciSelezionati.length ==
                                  storicoFiltrato.length
                          ? null
                          : () {
                              setState(() {
                                storiciSelezionati.clear();
                                storiciSelezionati.addAll(
                                  List.generate(
                                    storicoFiltrato.length,
                                    (i) => i,
                                  ),
                                );
                                storicoSelezionato = storicoFiltrato.isNotEmpty
                                    ? 0
                                    : null;
                                ultimoStoricoSelezionato =
                                    storicoFiltrato.isNotEmpty
                                    ? storicoFiltrato.length - 1
                                    : null;
                              });
                            },
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('Seleziona tutto'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1D4ED8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    if (storiciSelezionati.isNotEmpty) ...[
                      const SizedBox(width: 6),

                      TextButton.icon(
                        onPressed:
                            eliminazioneCorsiInCorso ||
                                storiciSelezionati.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  storiciSelezionati.clear();
                                  storicoSelezionato = null;
                                  ultimoStoricoSelezionato = null;
                                  indiceHoverStorico = null;
                                });
                              },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Deseleziona tutto'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4338CA),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      TextButton.icon(
                        onPressed:
                            !selezioneStoricoValida() ||
                                eliminazioneCorsiInCorso
                            ? null
                            : esportaCorsiSelezionatiExcel,
                        icon: Icon(
                          Icons.table_chart_outlined,
                          size: 20,
                          color:
                              !selezioneStoricoValida() ||
                                  eliminazioneCorsiInCorso
                              ? null
                              : const Color(0xFF16A34A),
                        ),
                        label: Text(
                          'Excel',
                          style: TextStyle(
                            color:
                                !selezioneStoricoValida() ||
                                    eliminazioneCorsiInCorso
                                ? null
                                : const Color(0xFF16A34A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      TextButton.icon(
                        onPressed:
                            !selezioneStoricoValida() ||
                                eliminazioneCorsiInCorso
                            ? null
                            : esportaCorsiSelezionatiPdf,
                        icon: Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 20,
                          color:
                              !selezioneStoricoValida() ||
                                  eliminazioneCorsiInCorso
                              ? null
                              : const Color(0xFFDC2626),
                        ),
                        label: Text(
                          'PDF',
                          style: TextStyle(
                            color:
                                !selezioneStoricoValida() ||
                                    eliminazioneCorsiInCorso
                                ? null
                                : const Color(0xFFDC2626),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      TextButton.icon(
                        onPressed:
                            !selezioneStoricoValida() ||
                                eliminazioneCorsiInCorso
                            ? null
                            : eliminaCorsiSelezionati,
                        icon: eliminazioneCorsiInCorso
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF9A3412),
                                ),
                              )
                            : Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: !selezioneStoricoValida()
                                    ? null
                                    : const Color(0xFFDC2626),
                              ),
                        label: Text(
                          eliminazioneCorsiInCorso
                              ? 'Eliminazione...'
                              : 'Elimina',
                          style: TextStyle(
                            color:
                                !selezioneStoricoValida() ||
                                    eliminazioneCorsiInCorso
                                ? null
                                : const Color(0xFFDC2626),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (storiciSelezionati.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: eliminazioneCorsiInCorso
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: eliminazioneCorsiInCorso
                            ? const Color(0xFFF97316)
                            : const Color(0xFFBFDBFE),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: eliminazioneCorsiInCorso
                              ? const Color(0xFFF97316).withValues(alpha: 0.10)
                              : const Color(0xFF2563EB).withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: eliminazioneCorsiInCorso
                                ? const Color(0xFFFFEDD5)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: eliminazioneCorsiInCorso
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFFC2410C),
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color: Color(0xFF2563EB),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            eliminazioneCorsiInCorso
                                ? storiciSelezionati.length == 1
                                      ? 'Eliminazione in corso di 1 corso selezionato...'
                                      : 'Eliminazione in corso di ${storiciSelezionati.length} corsi selezionati...'
                                : storiciSelezionati.length == 1
                                ? '1 corso selezionato'
                                : '${storiciSelezionati.length} corsi selezionati',
                            style: TextStyle(
                              color: eliminazioneCorsiInCorso
                                  ? const Color(0xFF9A3412)
                                  : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: caricamento
                    ? const Center(child: CircularProgressIndicator())
                    : storico.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF64748B),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Nessun corso presente nello storico',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Quando il discente avrà corsi registrati, compariranno qui.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : storicoFiltrato.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  color: Color(0xFFF97316),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Nessun corso trovato',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _cercaStoricoController.text
                                            .trim()
                                            .isNotEmpty &&
                                        filtroStorico != 'tutti'
                                    ? 'La ricerca nel filtro "${etichettaFiltroStorico(filtroStorico)}" non ha prodotto risultati.'
                                    : _cercaStoricoController.text
                                          .trim()
                                          .isNotEmpty
                                    ? 'La ricerca attiva non ha prodotto risultati.'
                                    : filtroStorico != 'tutti'
                                    ? 'Il filtro "${etichettaFiltroStorico(filtroStorico)}" non contiene corsi.'
                                    : 'Non sono presenti corsi nello storico formativo.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_cercaStoricoController.text
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 15,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 260,
                                          ),
                                          child: Text(
                                            '"${_cercaStoricoController.text.trim()}"',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF1D4ED8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (filtroStorico != 'tutti') ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.filter_alt_rounded,
                                        size: 15,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Filtro attivo: ${etichettaFiltroStorico(filtroStorico)}',
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (filtroStorico != 'tutti' ||
                                  _cercaStoricoController.text
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (filtroStorico != 'tutti')
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF64748B,
                                              ).withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                            onTap: eliminazioneCorsiInCorso
                                                ? null
                                                : () {
                                                    setState(() {
                                                      filtroStorico = 'tutti';
                                                    });
                                                    applicaFiltroStorico();
                                                  },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 15,
                                                vertical: 11,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .filter_alt_off_rounded,
                                                    size: 18,
                                                    color: Color(0xFF475569),
                                                  ),
                                                  SizedBox(width: 7),
                                                  Text(
                                                    'Azzera filtri',
                                                    style: TextStyle(
                                                      color: Color(0xFF475569),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    if (_cercaStoricoController.text
                                        .trim()
                                        .isNotEmpty)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFBFDBFE),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF2563EB,
                                              ).withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          child: Tooltip(
                                            message: 'Azzera ricerca storico',
                                            waitDuration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              onTap: eliminazioneCorsiInCorso
                                                  ? null
                                                  : () {
                                                      _cercaStoricoController
                                                          .clear();
                                                      applicaFiltroStorico();
                                                    },
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 11,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.close_rounded,
                                                      size: 18,
                                                      color:
                                                          eliminazioneCorsiInCorso
                                                          ? const Color(
                                                              0xFFCBD5E1,
                                                            )
                                                          : const Color(
                                                              0xFF2563EB,
                                                            ),
                                                    ),
                                                    SizedBox(width: 7),
                                                    Text(
                                                      'Azzera ricerca',
                                                      style: TextStyle(
                                                        color:
                                                            eliminazioneCorsiInCorso
                                                            ? const Color(
                                                                0xFFCBD5E1,
                                                              )
                                                            : const Color(
                                                                0xFF2563EB,
                                                              ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Tooltip(
                                    message: eliminazioneCorsiInCorso
                                        ? 'Ordinamento disabilitato durante l’eliminazione'
                                        : 'Ordina per corso',
                                    waitDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    child: MouseRegion(
                                      cursor: eliminazioneCorsiInCorso
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: eliminazioneCorsiInCorso
                                            ? null
                                            : () => ordinaStorico('corso'),
                                        child: _StoricoHeaderCell(
                                          'Corso',
                                          attiva:
                                              colonnaOrdinamentoStorico ==
                                              'corso',
                                          crescente:
                                              ordinamentoStoricoAscendente,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    message: eliminazioneCorsiInCorso
                                        ? 'Ordinamento disabilitato durante l’eliminazione'
                                        : 'Ordina per data corso',
                                    waitDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    child: MouseRegion(
                                      cursor: eliminazioneCorsiInCorso
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: eliminazioneCorsiInCorso
                                            ? null
                                            : () => ordinaStorico('data'),
                                        child: _StoricoHeaderCell(
                                          'Data corso',
                                          attiva:
                                              colonnaOrdinamentoStorico ==
                                              'data',
                                          crescente:
                                              ordinamentoStoricoAscendente,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Tooltip(
                                    message: eliminazioneCorsiInCorso
                                        ? 'Ordinamento disabilitato durante l’eliminazione'
                                        : 'Ordina per scadenza',
                                    waitDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    child: MouseRegion(
                                      cursor: eliminazioneCorsiInCorso
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: eliminazioneCorsiInCorso
                                            ? null
                                            : () => ordinaStorico('scadenza'),
                                        child: _StoricoHeaderCell(
                                          'Scadenza',
                                          attiva:
                                              colonnaOrdinamentoStorico ==
                                              'scadenza',
                                          crescente:
                                              ordinamentoStoricoAscendente,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Tooltip(
                                    message: eliminazioneCorsiInCorso
                                        ? 'Ordinamento disabilitato durante l’eliminazione'
                                        : 'Ordina per ore',
                                    waitDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    child: MouseRegion(
                                      cursor: eliminazioneCorsiInCorso
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: eliminazioneCorsiInCorso
                                            ? null
                                            : () => ordinaStorico('ore'),
                                        child: _StoricoHeaderCell(
                                          'Ore',
                                          attiva:
                                              colonnaOrdinamentoStorico ==
                                              'ore',
                                          crescente:
                                              ordinamentoStoricoAscendente,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _StoricoHeaderCell('Stato'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: storicoFiltrato.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: Color(0xFFE5E7EB),
                              ),
                              itemBuilder: (context, index) {
                                final r = storicoFiltrato[index];
                                final stato = statoScadenzaCorso(r['scadenza']);

                                return MouseRegion(
                                  onEnter: (_) {
                                    if (eliminazioneCorsiInCorso) return;

                                    setState(() {
                                      indiceHoverStorico = index;
                                    });
                                  },
                                  onExit: (_) {
                                    if (eliminazioneCorsiInCorso) return;

                                    setState(() {
                                      indiceHoverStorico = null;
                                    });
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,

                                    onTap: eliminazioneCorsiInCorso
                                        ? null
                                        : () {
                                            final ctrlPremuto =
                                                HardwareKeyboard
                                                    .instance
                                                    .logicalKeysPressed
                                                    .contains(
                                                      LogicalKeyboardKey
                                                          .controlLeft,
                                                    ) ||
                                                HardwareKeyboard
                                                    .instance
                                                    .logicalKeysPressed
                                                    .contains(
                                                      LogicalKeyboardKey
                                                          .controlRight,
                                                    );

                                            final shiftPremuto =
                                                HardwareKeyboard
                                                    .instance
                                                    .logicalKeysPressed
                                                    .contains(
                                                      LogicalKeyboardKey
                                                          .shiftLeft,
                                                    ) ||
                                                HardwareKeyboard
                                                    .instance
                                                    .logicalKeysPressed
                                                    .contains(
                                                      LogicalKeyboardKey
                                                          .shiftRight,
                                                    );

                                            setState(() {
                                              storicoSelezionato = index;

                                              if (shiftPremuto &&
                                                  ultimoStoricoSelezionato !=
                                                      null) {
                                                final inizio =
                                                    ultimoStoricoSelezionato! <
                                                        index
                                                    ? ultimoStoricoSelezionato!
                                                    : index;
                                                final fine =
                                                    ultimoStoricoSelezionato! >
                                                        index
                                                    ? ultimoStoricoSelezionato!
                                                    : index;

                                                storiciSelezionati.clear();

                                                for (
                                                  int i = inizio;
                                                  i <= fine;
                                                  i++
                                                ) {
                                                  storiciSelezionati.add(i);
                                                }
                                              } else if (ctrlPremuto) {
                                                if (storiciSelezionati.contains(
                                                  index,
                                                )) {
                                                  storiciSelezionati.remove(
                                                    index,
                                                  );
                                                } else {
                                                  storiciSelezionati.add(index);
                                                }

                                                ultimoStoricoSelezionato =
                                                    index;
                                              } else {
                                                if (storiciSelezionati.contains(
                                                  index,
                                                )) {
                                                  storiciSelezionati.remove(
                                                    index,
                                                  );
                                                  storicoSelezionato = null;
                                                  ultimoStoricoSelezionato =
                                                      null;
                                                  indiceHoverStorico = null;
                                                } else {
                                                  storiciSelezionati.clear();
                                                  storiciSelezionati.add(index);
                                                  ultimoStoricoSelezionato =
                                                      index;
                                                }
                                              }
                                            });
                                          },
                                    onDoubleTap: eliminazioneCorsiInCorso
                                        ? null
                                        : () {
                                            apriDettaglioStorico(r);
                                          },
                                    child: Tooltip(
                                      message: eliminazioneCorsiInCorso
                                          ? 'Eliminazione in corso...'
                                          : 'Click per selezionare • Doppio click per aprire il dettaglio',
                                      waitDuration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      child: MouseRegion(
                                        cursor: eliminazioneCorsiInCorso
                                            ? SystemMouseCursors.basic
                                            : SystemMouseCursors.click,
                                        child: Container(
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color:
                                                storiciSelezionati.contains(
                                                  index,
                                                )
                                                ? eliminazioneCorsiInCorso
                                                      ? const Color(0xFFFFF7ED)
                                                      : const Color(0xFFEAF2FF)
                                                : indiceHoverStorico == index &&
                                                      !eliminazioneCorsiInCorso
                                                ? const Color(0xFFF1F5FF)
                                                : Colors.transparent,
                                            border: Border(
                                              left: BorderSide(
                                                color:
                                                    storiciSelezionati.contains(
                                                      index,
                                                    )
                                                    ? eliminazioneCorsiInCorso
                                                          ? const Color(
                                                              0xFFF97316,
                                                            )
                                                          : const Color(
                                                              0xFF2563EB,
                                                            )
                                                    : Colors.transparent,
                                                width: 4,
                                              ),
                                              bottom: const BorderSide(
                                                color: Color(0xFFE5E7EB),
                                                width: 0.7,
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: Text(
                                                  valore(r['corso']),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),

                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  formattaData(r['data']),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),

                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  formattaData(r['scadenza']),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),

                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  '${valore(r['durata_ore'])} h',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),

                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: sfondoStatoCorso(
                                                        stato,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      stato,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: coloreStatoCorso(
                                                          stato,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
      ),
    );
  }
}

class _AnagraficaCard extends StatelessWidget {
  final Discente discente;

  const _AnagraficaCard({required this.discente});

  String valore(String? v) {
    final testo = v?.trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        runSpacing: 14,
        spacing: 28,
        children: [
          _InfoItem(label: 'Nome', value: valore(discente.nome)),
          _InfoItem(label: 'Cognome', value: valore(discente.cognome)),
          _InfoItem(
            label: 'Luogo nascita',
            value: valore(discente.luogoNascita),
          ),
          _InfoItem(label: 'Data nascita', value: valore(discente.dataNascita)),
          _InfoItem(
            label: 'Codice fiscale',
            value: valore(discente.codiceFiscale),
          ),
          _InfoItem(label: 'Impresa', value: valore(discente.nomeImpresa)),
        ],
      ),
    );
  }
}

class _SorveglianzaSanitariaCard extends StatelessWidget {
  final Discente discente;

  const _SorveglianzaSanitariaCard({required this.discente});

  String valore(String? v) {
    final testo = v?.trim() ?? '';
    return testo.isEmpty ? '-' : testo;
  }

  String _statoVisitaMedica(bool visitaSvolta, String? scadenza) {
    if (!visitaSvolta) return 'NON PRESENTE';

    final testo = scadenza?.trim() ?? '';
    if (testo.isEmpty) return 'SENZA SCADENZA';

    DateTime? data;

    if (testo.contains('/')) {
      final parti = testo.split('/');
      if (parti.length == 3) {
        data = DateTime.tryParse(
          '${parti[2]}-${parti[1].padLeft(2, '0')}-${parti[0].padLeft(2, '0')}',
        );
      }
    } else {
      data = DateTime.tryParse(testo);
    }

    if (data == null) return 'SENZA SCADENZA';

    final oggi = DateTime.now();
    final oggiPulito = DateTime(oggi.year, oggi.month, oggi.day);
    final scadenzaPulita = DateTime(data.year, data.month, data.day);

    final giorni = scadenzaPulita.difference(oggiPulito).inDays;

    if (giorni < 0) return 'SCADUTA';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDA';
  }

  Color _coloreStato(String stato) {
    switch (stato) {
      case 'VALIDA':
        return const Color(0xFF16A34A);
      case 'IN SCADENZA':
        return const Color(0xFFF59E0B);
      case 'SCADUTA':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _sfondoStato(String stato) {
    switch (stato) {
      case 'VALIDA':
        return const Color(0xFFEAF7EE);
      case 'IN SCADENZA':
        return const Color(0xFFFFF7E6);
      case 'SCADUTA':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitaSvolta = discente.visitaMedicaSvolta == 1;

    final statoVisita = _statoVisitaMedica(
      visitaSvolta,
      discente.scadenzaVisitaMedica,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        runSpacing: 14,
        spacing: 28,
        children: [
          _InfoItem(label: 'Visita medica', value: visitaSvolta ? 'Sì' : 'No'),
          _InfoItem(
            label: 'Data visita',
            value: valore(discente.dataVisitaMedica),
          ),
          _InfoItem(
            label: 'Scadenza visita',
            value: valore(discente.scadenzaVisitaMedica),
          ),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _sfondoStato(statoVisita),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statoVisita,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _coloreStato(statoVisita),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoricoKpiCard extends StatelessWidget {
  final String titolo;
  final String valore;
  final Color colore;
  final bool attivo;
  final bool disabilitato;

  const _StoricoKpiCard({
    required this.titolo,
    required this.valore,
    required this.colore,
    this.attivo = false,
    this.disabilitato = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabilitato ? 0.45 : 1,
      child: Container(
        width: 170,
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: disabilitato
              ? Colors.white
              : attivo
              ? colore.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: disabilitato
                ? const Color(0xFFE5E7EB)
                : attivo
                ? colore
                : const Color(0xFFE5E7EB),
            width: disabilitato
                ? 1
                : attivo
                ? 2
                : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titolo.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              valore,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: colore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoricoHeaderCell extends StatelessWidget {
  final String testo;
  final bool attiva;
  final bool crescente;

  const _StoricoHeaderCell(
    this.testo, {
    this.attiva = false,
    this.crescente = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          testo.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: attiva ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            letterSpacing: 0.7,
          ),
        ),
        if (attiva) ...[
          const SizedBox(width: 5),
          Icon(
            crescente ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: const Color(0xFF2563EB),
          ),
        ],
      ],
    );
  }
}
