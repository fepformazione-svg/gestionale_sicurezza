import 'package:flutter/material.dart';

import '../models/discente.dart';
import '../services/database_service.dart';

class DiscenteSchedaPage extends StatefulWidget {
  final Discente discente;

  const DiscenteSchedaPage({super.key, required this.discente});

  @override
  State<DiscenteSchedaPage> createState() => _DiscenteSchedaPageState();
}

class _DiscenteSchedaPageState extends State<DiscenteSchedaPage> {
  bool caricamento = true;
  List<Map<String, dynamic>> storico = [];
  List<Map<String, dynamic>> storicoFiltrato = [];

  String filtroStorico = 'tutti';
  
  String colonnaOrdinamentoStorico = 'data';
  bool ordinamentoStoricoAscendente = false;

  final TextEditingController _cercaStoricoController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    });
  }

  void applicaFiltroStorico() {
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
            passaFiltro =
                statoScadenzaCorso(riga['scadenza']) == 'IN SCADENZA';
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
            confronto = (a['corso'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b['corso'] ?? '').toString().toLowerCase());
            break;

          case 'data':
            confronto = leggiDataStorico(a['data'])
                .compareTo(leggiDataStorico(b['data']));
            break;

          case 'scadenza':
            confronto = leggiDataStorico(a['scadenza'])
                .compareTo(leggiDataStorico(b['scadenza']));
            break;

          case 'ore':
            confronto = ((a['ore'] ?? 0) as num)
                .compareTo((b['ore'] ?? 0) as num);
            break;
        }

        return ordinamentoStoricoAscendente ? confronto : -confronto;
      });
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

      storicoFiltrato.sort((a, b) {
        int risultato = 0;

        switch (colonna) {
          case 'corso':
            risultato = valore(a['corso']).toLowerCase().compareTo(
                  valore(b['corso']).toLowerCase(),
                );

            if (risultato == 0) {
              risultato = leggiDataStorico(a['data']).compareTo(
                leggiDataStorico(b['data']),
              );
            }
            break;

          case 'data':
            risultato = leggiDataStorico(a['data']).compareTo(
              leggiDataStorico(b['data']),
            );

            if (risultato == 0) {
              risultato = valore(a['corso']).toLowerCase().compareTo(
                    valore(b['corso']).toLowerCase(),
                  );
            }
            break;

          case 'scadenza':
            risultato = leggiDataStorico(a['scadenza']).compareTo(
              leggiDataStorico(b['scadenza']),
            );

            if (risultato == 0) {
              risultato = valore(a['corso']).toLowerCase().compareTo(
                    valore(b['corso']).toLowerCase(),
                  );
            }
            break;

          case 'ore':
            final oreA =
                num.tryParse(valore(a['durata_ore']).replaceAll(',', '.')) ?? 0;

            final oreB =
                num.tryParse(valore(b['durata_ore']).replaceAll(',', '.')) ?? 0;

            risultato = oreA.compareTo(oreB);

            if (risultato == 0) {
              risultato = valore(a['corso']).toLowerCase().compareTo(
                    valore(b['corso']).toLowerCase(),
                  );
            }
            break;
        }

        return ordinamentoStoricoAscendente ? risultato : -risultato;
      });
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
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
                      Expanded(
                        flex: 2,
                        child: _StoricoHeaderCell('Stato'),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    itemCount: storico.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFE5E7EB),
                    ),
                    itemBuilder: (context, index) {
                      final r = storico[index];
                      final stato = statoScadenzaCorso(r['scadenza']);

                      return Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
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
                                    borderRadius: BorderRadius.circular(999),
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
            tooltip: 'Modifica',
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
            onPressed: () {
              Navigator.pop(context, 'modifica');
            },
          ),
          IconButton(
            tooltip: 'Elimina',
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            onPressed: eliminaDiscente,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnagraficaCard(discente: d),
            const SizedBox(height: 18),
            _SorveglianzaSanitariaCard(discente: d),
            const SizedBox(height: 24),
            const Text(
              'Storico formativo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                InkWell(
                  onTap: () {
                    filtroStorico = 'tutti';
                    applicaFiltroStorico();

                    mostraTuttiICorsi();
                  },
                  child: _StoricoKpiCard(
                    titolo: 'Totale corsi',
                    valore: totaleCorsi.toString(),
                    colore: const Color(0xFF2563EB),
                    attivo: filtroStorico == 'tutti',
                  ),
                ),
                InkWell(
                  onTap: () {
                    filtroStorico = 'validi';
                    applicaFiltroStorico();
                  },
                  child: _StoricoKpiCard(
                    titolo: 'Validi',
                    valore: corsiValidi.toString(),
                    colore: const Color(0xFF16A34A),
                    attivo: filtroStorico == 'validi',
                  ),
                ),
                InkWell(
                  onTap: () {
                    filtroStorico = 'in_scadenza';
                    applicaFiltroStorico();
                  },
                  child: _StoricoKpiCard(
                    titolo: 'In scadenza',
                    valore: corsiInScadenza.toString(),
                    colore: const Color(0xFFF59E0B),
                    attivo: filtroStorico == 'in_scadenza',
                  ),
                ),
                InkWell(
                  onTap: () {
                    filtroStorico = 'scaduti';
                    applicaFiltroStorico();
                  },
                  child: _StoricoKpiCard(
                    titolo: 'Scaduti',
                    valore: corsiScaduti.toString(),
                    colore: const Color(0xFFDC2626),
                    attivo: filtroStorico == 'scaduti',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _cercaStoricoController,
                    onChanged: filtraStorico,
                    decoration: InputDecoration(
                      hintText: 'Cerca corso...',
                      prefixIcon: const Icon(Icons.search),

                      suffixIcon: _cercaStoricoController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Azzera ricerca',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _cercaStoricoController.clear();
                                filtraStorico('');
                              },
                            )
                          : null,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                OutlinedButton.icon(
                  onPressed: azzeraFiltroStorico,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Azzera filtro',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(
                      color: Color(0xFFD1D5DB),
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
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storicoFiltrato.length == 1
                          ? 'Visualizzato 1 corso'
                          : 'Visualizzati ${storicoFiltrato.length} corsi',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    if (filtroStorico != 'tutti') ...[
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: azzeraFiltroStorico,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: filtroStorico == 'validi'
                                ? const Color(0xFFEAF7EE)
                                : filtroStorico == 'in_scadenza'
                                    ? const Color(0xFFFFF7E6)
                                    : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filtroStorico == 'validi'
                                    ? 'VALIDI'
                                    : filtroStorico == 'in_scadenza'
                                        ? 'IN SCADENZA'
                                        : 'SCADUTI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: filtroStorico == 'validi'
                                      ? const Color(0xFF16A34A)
                                      : filtroStorico == 'in_scadenza'
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.close,
                                size: 14,
                                color: filtroStorico == 'validi'
                                    ? const Color(0xFF16A34A)
                                    : filtroStorico == 'in_scadenza'
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (filtroStorico != 'tutti')
                  TextButton.icon(
                    onPressed: azzeraFiltroStorico,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Azzera filtri'),
                  ),
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
                      ? const Center(
                          child: Text(
                            'Nessun corso presente nello storico',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 15,
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
                                    child: InkWell(
                                      onTap: () => ordinaStorico('corso'),
                                      child: _StoricoHeaderCell(
                                        'Corso',
                                        attiva: colonnaOrdinamentoStorico == 'corso',
                                        crescente: ordinamentoStoricoAscendente,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: () => ordinaStorico('data'),
                                      child: _StoricoHeaderCell(
                                        'Data corso',
                                        attiva: colonnaOrdinamentoStorico == 'data',
                                        crescente: ordinamentoStoricoAscendente,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: () => ordinaStorico('scadenza'),
                                      child: _StoricoHeaderCell(
                                        'Scadenza',
                                        attiva: colonnaOrdinamentoStorico == 'scadenza',
                                        crescente: ordinamentoStoricoAscendente,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: InkWell(
                                      onTap: () => ordinaStorico('ore'),
                                      child: _StoricoHeaderCell(
                                        'Ore',
                                        attiva: colonnaOrdinamentoStorico == 'ore',
                                        crescente: ordinamentoStoricoAscendente,
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
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                                itemBuilder: (context, index) {
                                  final r = storicoFiltrato[index];
                                  final stato = statoScadenzaCorso(r['scadenza']);

                                  return Container(
                                    height: 58,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
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
                                                borderRadius:
                                                    BorderRadius.circular(999),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        runSpacing: 18,
        spacing: 36,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        runSpacing: 18,
        spacing: 36,
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

  const _StoricoKpiCard({
    required this.titolo,
    required this.valore,
    required this.colore,
    this.attivo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: attivo ? colore.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: attivo ? colore : const Color(0xFFE5E7EB),
          width: attivo ? 2 : 1,
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
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: attiva
        ? BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(6),
          )
        : null,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          testo.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: attiva
                ? const Color(0xFF2563EB)
                : const Color(0xFF6B7280),
            letterSpacing: 0.6,
          ),
        ),
        if (attiva) ...[
          const SizedBox(width: 4),
          Icon(
            crescente ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13,
            color: const Color(0xFF2563EB),
          ),
        ],
      ],
    ),
  );
}
}