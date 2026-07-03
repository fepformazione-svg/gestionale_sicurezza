import 'package:flutter/material.dart';

import '../models/assistente_operativo_item.dart';
import '../services/app_database.dart';
import '../services/assistente_operativo_service.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/sessione_utente_service.dart';

import '../widgets/sidebar.dart';
import '../widgets/kpi_card.dart';
import '../widgets/app_topbar.dart';

import 'prenotazioni_page.dart';
import 'diario_page.dart';
import 'scadenze_page.dart';
import 'discenti_page.dart';
import 'imprese_page.dart';
import 'corsi_page.dart';
import 'prezzario_page.dart';
import 'visite_mediche_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  String globalSearch = '';
  String filtroScadenze = 'tutte';
  String filtroPrenotazioni = 'tutte';
  bool diarioSoloDaFatturare = false;
  int dashboardRefresh = 0;
  List<Widget> get pages => [
    DashboardPage(key: ValueKey(dashboardRefresh)),
    PrenotazioniPage(
      globalSearch: globalSearch,
      filtro: filtroPrenotazioni,
      onDatiModificati: () {
        setState(() {
          dashboardRefresh++;
        });
      },
    ),
    DiarioPage(soloDaFatturare: diarioSoloDaFatturare),
    ScadenzePage(filtro: filtroScadenze),
    DiscentiPage(globalSearch: globalSearch),
    const ImpresePage(),
    const CorsiPage(),
    const PrezzarioPage(),
    const VisiteMedichePage(),
  ];

  void aggiornaRicercaGlobale(String value) {
    setState(() {
      globalSearch = value;
    });

    debugPrint('Ricerca globale: $globalSearch');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              setState(() {
                selectedIndex = index;

                if (index == 0) {
                  dashboardRefresh++;
                }

                if (index == 1) {
                  filtroPrenotazioni = 'tutte';
                }

                if (index == 2) {
                  diarioSoloDaFatturare = false;
                }

                if (index == 3) {
                  filtroScadenze = 'tutte';
                }
              });

              if (index == 0) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  setState(() {
                    dashboardRefresh++;
                  });
                });
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  AppTopbar(onSearchChanged: aggiornaRicercaGlobale),
                  const SizedBox(height: 24),
                  Expanded(child: pages[selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool caricamento = true;
  List<AssistenteOperativoItem> assistenteItems = [];

  Map<String, int> kpi = {
    'prenotazioni': 0,
    'prenotazioni_aperte': 0,
    'prenotazioni_chiuse': 0,
    'diario': 0,
    'scadenze': 0,
    'scaduti': 0,
    'discenti': 0,
    'imprese': 0,
    'corsi': 0,
    'da_fatturare': 0,
  };

  String get testoUtenteCorrente {
    final sessione = SessioneUtenteService.instance;

    if (!sessione.utenteLoggato) {
      return 'Utente corrente: nessuno';
    }

    return 'Utente corrente: ${sessione.nomeVisualizzato}';
  }

  Widget badgeUtenteCorrente() {
    return ValueListenableBuilder<int>(
      valueListenable: SessioneUtenteService.instance.notificatoreSessione,
      builder: (context, value, child) {
        final utenteLoggato = SessioneUtenteService.instance.utenteLoggato;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: utenteLoggato ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: utenteLoggato
                  ? Colors.green.shade200
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                utenteLoggato
                    ? Icons.verified_user_outlined
                    : Icons.person_off_outlined,
                size: 18,
                color: utenteLoggato
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                testoUtenteCorrente,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: utenteLoggato
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    caricaKpi();
  }

  Future<void> caricaKpi() async {
    final dati = await DatabaseService.instance.caricaKpiDashboard();

    final aperte = await DatabaseService.instance.contaPrenotazioniAperte();
    final chiuse = await DatabaseService.instance.contaPrenotazioniChiuse();
    final totale = await DatabaseService.instance.contaPrenotazioniTotali();

    final assistenteService = AssistenteOperativoService(AppDatabase.instance);
    final riepilogoAssistente = await assistenteService
        .generaRiepilogoOperativo();

    if (!mounted) return;

    setState(() {
      kpi = {
        ...dati,
        'prenotazioni': totale,
        'prenotazioni_aperte': aperte,
        'prenotazioni_chiuse': chiuse,
      };
      assistenteItems = riepilogoAssistente;
      caricamento = false;
    });
  }

  Color colorePriorita(PrioritaAssistenteOperativo priorita) {
    switch (priorita) {
      case PrioritaAssistenteOperativo.alta:
        return const Color(0xFFDC2626);
      case PrioritaAssistenteOperativo.media:
        return const Color(0xFFF59E0B);
      case PrioritaAssistenteOperativo.bassa:
        return const Color(0xFF2563EB);
    }
  }

  IconData iconaPriorita(PrioritaAssistenteOperativo priorita) {
    switch (priorita) {
      case PrioritaAssistenteOperativo.alta:
        return Icons.priority_high;
      case PrioritaAssistenteOperativo.media:
        return Icons.warning_amber;
      case PrioritaAssistenteOperativo.bassa:
        return Icons.info_outline;
    }
  }

  String messaggioPrioritaOperativa() {
    final haPrioritaAlta = assistenteItems.any(
      (item) => item.priorita == PrioritaAssistenteOperativo.alta,
    );
    final haPrioritaMedia = assistenteItems.any(
      (item) => item.priorita == PrioritaAssistenteOperativo.media,
    );

    if (haPrioritaAlta) {
      return 'Priorit\u00E0 operativa: gestisci prima le criticit\u00E0 ad alta priorit\u00E0, poi pianifica le attivit\u00E0 in scadenza.';
    }

    if (haPrioritaMedia) {
      return 'Priorit\u00E0 operativa: pianifica le attivit\u00E0 in scadenza e mantieni aggiornata la situazione.';
    }

    return 'Priorit\u00E0 operativa: controlla le attivit\u00E0 segnalate e mantieni il gestionale aggiornato.';
  }

  void apriModuloAssistente(
    BuildContext context,
    ModuloAssistenteOperativo modulo,
  ) {
    final homeState = context.findAncestorStateOfType<_HomePageState>();

    if (homeState == null) return;

    homeState.setState(() {
      switch (modulo) {
        case ModuloAssistenteOperativo.prenotazioni:
          homeState.filtroPrenotazioni = 'aperte';
          homeState.selectedIndex = 1;
          break;
        case ModuloAssistenteOperativo.diario:
          homeState.diarioSoloDaFatturare = true;
          homeState.selectedIndex = 2;
          break;
        case ModuloAssistenteOperativo.scadenze:
          homeState.filtroScadenze = 'scaduti';
          homeState.selectedIndex = 3;
          break;
        case ModuloAssistenteOperativo.discenti:
          homeState.selectedIndex = 4;
          break;
        case ModuloAssistenteOperativo.imprese:
          homeState.selectedIndex = 5;
          break;
        case ModuloAssistenteOperativo.visiteMediche:
          homeState.selectedIndex = 8;
          break;
        case ModuloAssistenteOperativo.dashboard:
        case ModuloAssistenteOperativo.consensiPrivacy:
          homeState.selectedIndex = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Modulo non ancora collegato alla navigazione rapida.',
              ),
            ),
          );
          break;
      }
    });
  }

  Widget riquadroAssistenteOperativo() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assistant_direction_outlined,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistente operativo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),

                      SizedBox(height: 4),
                      Text(
                        'Controllo locale delle priorità del gestionale',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 18, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ordine operativo: scaduti → in scadenza → da gestire',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (assistenteItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Nessuna criticità operativa rilevata.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            messaggioPrioritaOperativa(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF312E81),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...assistenteItems.map((item) {
                    final colore = colorePriorita(item.priorita);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => apriModuloAssistente(context, item.modulo),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colore.withValues(alpha: 0.12),
                                child: Icon(
                                  iconaPriorita(item.priorita),
                                  color: colore,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.titolo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.descrizione,
                                      style: const TextStyle(
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                    if (item.azioneSuggerita != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.azioneSuggerita!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colore.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.conteggio.toString(),
                                  style: TextStyle(
                                    color: colore,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void apriPagina(BuildContext context, int index) {
    final homeState = context.findAncestorStateOfType<_HomePageState>();

    homeState?.setState(() {
      homeState.selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (caricamento) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: caricaKpi,
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badgeUtenteCorrente(),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final file = await BackupService.eseguiBackupManuale();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            file != null
                                ? 'Backup completato con successo'
                                : 'Errore durante il backup',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Backup Database'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Panoramica generale del gestionale formazione sicurezza',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),

          GridView.count(
            crossAxisCount: 3,
            mainAxisExtent: 145,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 2.1,
            children: [
              GestureDetector(
                onTap: () {
                  final homeState = context
                      .findAncestorStateOfType<_HomePageState>();

                  homeState?.setState(() {
                    homeState.filtroPrenotazioni = 'aperte';
                    homeState.selectedIndex = 1;
                  });
                },
                child: KpiCard(
                  title: 'Prenotazioni aperte',
                  value: kpi['prenotazioni_aperte'].toString(),
                  icon: Icons.calendar_month,
                  color: const Color(0xFF2563EB),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final homeState = context
                      .findAncestorStateOfType<_HomePageState>();

                  homeState?.setState(() {
                    homeState.filtroPrenotazioni = 'chiuse';
                    homeState.selectedIndex = 1;
                  });
                },
                child: KpiCard(
                  title: 'Prenotazioni chiuse',
                  value: kpi['prenotazioni_chiuse'].toString(),
                  icon: Icons.event_available,
                  color: const Color(0xFF64748B),
                ),
              ),

              GestureDetector(
                onTap: () {
                  final homeState = context
                      .findAncestorStateOfType<_HomePageState>();

                  homeState?.setState(() {
                    homeState.diarioSoloDaFatturare = false;
                    homeState.selectedIndex = 2;
                  });
                },
                child: KpiCard(
                  title: 'Diario corsi',
                  value: kpi['diario'].toString(),
                  icon: Icons.menu_book,
                  color: const Color(0xFF16A34A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final homeState = context
                      .findAncestorStateOfType<_HomePageState>();

                  homeState?.setState(() {
                    homeState.filtroScadenze = 'tutte';
                    homeState.selectedIndex = 3;
                  });
                },
                child: KpiCard(
                  title: 'Scadenze',
                  value: kpi['scadenze'].toString(),
                  icon: Icons.warning_amber,
                  color: const Color(0xFFDC2626),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final homeState = context
                      .findAncestorStateOfType<_HomePageState>();

                  homeState?.setState(() {
                    homeState.filtroScadenze = 'scaduti';
                    homeState.selectedIndex = 3;
                  });
                },
                child: KpiCard(
                  title: 'Scaduti',
                  value: kpi['scaduti'].toString(),
                  icon: Icons.gpp_bad,
                  color: const Color(0xFFB91C1C),
                ),
              ),
              GestureDetector(
                onTap: () => apriPagina(context, 4),
                child: KpiCard(
                  title: 'Discenti',
                  value: kpi['discenti'].toString(),
                  icon: Icons.people,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              GestureDetector(
                onTap: () => apriPagina(context, 5),
                child: KpiCard(
                  title: 'Imprese',
                  value: kpi['imprese'].toString(),
                  icon: Icons.business,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              GestureDetector(
                onTap: () => apriPagina(context, 6),
                child: KpiCard(
                  title: 'Corsi',
                  value: kpi['corsi'].toString(),
                  icon: Icons.school,
                  color: const Color(0xFF2563EB),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final homeState = context
                      .findAncestorStateOfType<_HomePageState>();

                  homeState?.setState(() {
                    homeState.diarioSoloDaFatturare = true;
                    homeState.selectedIndex = 2;
                  });
                },
                child: KpiCard(
                  title: 'Da fatturare',
                  value: kpi['da_fatturare'].toString(),
                  icon: Icons.euro,
                  color: const Color(0xFF0891B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          riquadroAssistenteOperativo(),
        ],
      ),
    );
  }
}
