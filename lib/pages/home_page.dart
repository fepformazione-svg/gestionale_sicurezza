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
  String filtroVisiteMediche = 'Tutte';
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
    VisiteMedichePage(
      key: ValueKey('visite_mediche_$filtroVisiteMediche'),
      filtroStatoIniziale: filtroVisiteMediche,
    ),
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

                if (index == 8) {
                  filtroVisiteMediche = 'Tutte';
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
          homeState.filtroVisiteMediche = 'Tutte';
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
    String testoCosaFareOggi() {
      if (assistenteItems.isEmpty) {
        return 'Nessuna attività urgente: il gestionale non segnala interventi immediati.';
      }

      final dettagli = assistenteItems
          .map((item) {
            final conteggio = item.conteggio;
            final titolo = item.titolo.toLowerCase();

            if (titolo.contains('scadenze scadute')) {
              return conteggio == 1
                  ? '1 scadenza scaduta'
                  : '$conteggio scadenze scadute';
            }

            if (titolo.contains('scadenze in scadenza')) {
              return conteggio == 1
                  ? '1 scadenza in scadenza'
                  : '$conteggio scadenze in scadenza';
            }

            if (titolo.contains('visite mediche scadute')) {
              return conteggio == 1
                  ? '1 visita medica scaduta'
                  : '$conteggio visite mediche scadute';
            }

            if (titolo.contains('visite mediche in scadenza')) {
              return conteggio == 1
                  ? '1 visita medica in scadenza'
                  : '$conteggio visite mediche in scadenza';
            }

            if (titolo.contains('pratiche da fatturare')) {
              return conteggio == 1
                  ? '1 pratica da fatturare'
                  : '$conteggio pratiche da fatturare';
            }

            return '$conteggio $titolo';
          })
          .join(', ');

      return 'Oggi: $dettagli.';
    }

    String testoPrioritaMassima() {
      if (assistenteItems.isEmpty) {
        return '';
      }

      final titolo = assistenteItems.first.titolo.toLowerCase();

      if (titolo.contains('scadenze scadute')) {
        return 'Priorità massima: scadenze scadute.';
      }

      if (titolo.contains('visite mediche scadute')) {
        return 'Priorità massima: visite mediche scadute.';
      }

      if (titolo.contains('pratiche da fatturare')) {
        return 'Priorità massima: pratiche da fatturare.';
      }

      if (titolo.contains('scadenze in scadenza')) {
        return 'Priorità massima: scadenze in scadenza.';
      }

      if (titolo.contains('visite mediche in scadenza')) {
        return 'Priorità massima: visite mediche in scadenza.';
      }

      return 'Priorità massima: ${assistenteItems.first.titolo.toLowerCase()}.';
    }

    bool prioritaMassimaScaduta() {
      if (assistenteItems.isEmpty) {
        return false;
      }

      final titolo = assistenteItems.first.titolo.toLowerCase();
      return titolo.contains('scadute') || titolo.contains('scaduta');
    }

    bool prioritaMassimaInScadenza() {
      if (assistenteItems.isEmpty) {
        return false;
      }

      final titolo = assistenteItems.first.titolo.toLowerCase();
      return titolo.contains('in scadenza');
    }

    Color sfondoCosaFareOggi() {
      if (assistenteItems.isEmpty) {
        return const Color(0xFFF0FDF4);
      }

      if (prioritaMassimaScaduta()) {
        return const Color(0xFFFEF2F2);
      }

      if (prioritaMassimaInScadenza()) {
        return const Color(0xFFFFFBEB);
      }

      return const Color(0xFFEFF6FF);
    }

    Color bordoCosaFareOggi() {
      if (assistenteItems.isEmpty) {
        return const Color(0xFFBBF7D0);
      }

      if (prioritaMassimaScaduta()) {
        return const Color(0xFFFECACA);
      }

      if (prioritaMassimaInScadenza()) {
        return const Color(0xFFFDE68A);
      }

      return const Color(0xFFBFDBFE);
    }

    final tuttoSottoControllo = assistenteItems.isEmpty;

    Color testoCosaFareOggiColore() {
      if (tuttoSottoControllo) {
        return const Color(0xFF166534);
      }

      if (prioritaMassimaScaduta()) {
        return const Color(0xFF991B1B);
      }

      if (prioritaMassimaInScadenza()) {
        return const Color(0xFF92400E);
      }

      return const Color(0xFF1D4ED8);
    }

    IconData iconaCosaFareOggi() {
      if (tuttoSottoControllo) {
        return Icons.check_circle_outline;
      }

      if (prioritaMassimaScaduta()) {
        return Icons.error_outline;
      }

      if (prioritaMassimaInScadenza()) {
        return Icons.warning_amber_outlined;
      }

      return Icons.today_outlined;
    }

    Widget buildMiniContatoreCosaFareOggi({
      required IconData icona,
      required int valore,
      required String testo,
      required Color colore,
      VoidCallback? onTap,
    }) {
      return MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colore.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colore.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icona, size: 15, color: colore),
                const SizedBox(width: 6),
                Text(
                  '$valore $testo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colore,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    int conteggioAssistentePerTitolo(String testoTitolo) {
      final testoNormalizzato = testoTitolo.toLowerCase();

      for (final item in assistenteItems) {
        if (item.titolo.toLowerCase().contains(testoNormalizzato)) {
          return item.conteggio;
        }
      }

      return 0;
    }

    final scadenzeScadute = conteggioAssistentePerTitolo('scadenze scadute');
    final scadenzeInScadenza = conteggioAssistentePerTitolo(
      'scadenze in scadenza',
    );
    final praticheDaFatturare = conteggioAssistentePerTitolo(
      'pratiche da fatturare',
    );
    final visiteMedicheScadute = conteggioAssistentePerTitolo(
      'visite mediche scadute',
    );
    final visiteMedicheInScadenza = conteggioAssistentePerTitolo(
      'visite mediche in scadenza',
    );
    final totalePrioritaOperative =
        scadenzeScadute +
        visiteMedicheScadute +
        praticheDaFatturare +
        scadenzeInScadenza +
        visiteMedicheInScadenza;
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sfondoCosaFareOggi(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bordoCosaFareOggi()),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    iconaCosaFareOggi(),
                    color: testoCosaFareOggiColore(),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cosa fare oggi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: testoCosaFareOggiColore(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!tuttoSottoControllo) ...[
                          Text(
                            testoPrioritaMassima(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: testoCosaFareOggiColore(),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          tuttoSottoControllo
                              ? 'Tutto sotto controllo'
                              : testoCosaFareOggi(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: tuttoSottoControllo
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: testoCosaFareOggiColore(),
                          ),
                        ),
                        if (tuttoSottoControllo) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Non risultano attività urgenti o in scadenza.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: testoCosaFareOggiColore(),
                            ),
                          ),
                        ],
                        if (!tuttoSottoControllo &&
                            totalePrioritaOperative > 0) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (scadenzeScadute > 0)
                                buildMiniContatoreCosaFareOggi(
                                  icona: Icons.gpp_bad_outlined,
                                  valore: scadenzeScadute,
                                  testo: 'Scadenze scadute',
                                  colore: const Color(0xFFDC2626),
                                  onTap: () {
                                    final homeState = context
                                        .findAncestorStateOfType<
                                          _HomePageState
                                        >();

                                    homeState?.setState(() {
                                      homeState.filtroScadenze = 'scaduti';
                                      homeState.selectedIndex = 3;
                                    });
                                  },
                                ),
                              if (visiteMedicheScadute > 0)
                                buildMiniContatoreCosaFareOggi(
                                  icona: Icons.medical_services_outlined,
                                  valore: visiteMedicheScadute,
                                  testo: 'Visite mediche scadute',
                                  colore: const Color(0xFFB91C1C),
                                  onTap: () {
                                    final homeState = context
                                        .findAncestorStateOfType<
                                          _HomePageState
                                        >();

                                    homeState?.setState(() {
                                      homeState.filtroVisiteMediche = 'Scadute';
                                      homeState.selectedIndex = 8;
                                    });
                                  },
                                ),

                              if (praticheDaFatturare > 0)
                                buildMiniContatoreCosaFareOggi(
                                  icona: Icons.receipt_long_outlined,
                                  valore: praticheDaFatturare,
                                  testo: 'Pratiche da fatturare',
                                  colore: const Color(0xFF0891B2),
                                  onTap: () => apriModuloAssistente(
                                    context,
                                    ModuloAssistenteOperativo.diario,
                                  ),
                                ),
                              if (scadenzeInScadenza > 0)
                                buildMiniContatoreCosaFareOggi(
                                  icona: Icons.warning_amber_outlined,
                                  valore: scadenzeInScadenza,
                                  testo: 'Scadenze in scadenza',
                                  colore: const Color(0xFFF59E0B),
                                  onTap: () {
                                    final homeState = context
                                        .findAncestorStateOfType<
                                          _HomePageState
                                        >();

                                    homeState?.setState(() {
                                      homeState.filtroScadenze = 'in_scadenza';
                                      homeState.selectedIndex = 3;
                                    });
                                  },
                                ),
                              if (visiteMedicheInScadenza > 0)
                                buildMiniContatoreCosaFareOggi(
                                  icona: Icons.medical_services_outlined,
                                  valore: visiteMedicheInScadenza,
                                  testo: 'Visite mediche in scadenza',
                                  colore: const Color(0xFF92400E),
                                  onTap: () {
                                    final homeState = context
                                        .findAncestorStateOfType<
                                          _HomePageState
                                        >();

                                    homeState?.setState(() {
                                      homeState.filtroVisiteMediche =
                                          'In scadenza';
                                      homeState.selectedIndex = 8;
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalePrioritaOperative == 1
                                ? 'È presente 1 priorità operativa da gestire.'
                                : 'Sono presenti $totalePrioritaOperative priorità operative da gestire.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: testoCosaFareOggiColore(),
                            ),
                          ),
                        ],
                      ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nessuna criticità operativa rilevata.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF166534),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scadenze, visite mediche e pratiche da fatturare non richiedono interventi immediati.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Clicca una voce per aprire il modulo collegato e gestire la priorità.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...assistenteItems.map((item) {
                    final colore = colorePriorita(item.priorita);
                    final etichettaPriorita = switch (item.priorita) {
                      PrioritaAssistenteOperativo.alta => 'PRIORITÀ ALTA',
                      PrioritaAssistenteOperativo.media => 'IN SCADENZA',
                      PrioritaAssistenteOperativo.bassa => 'DA MONITORARE',
                    };

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
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colore.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: colore.withValues(alpha: 0.30),
                                        ),
                                      ),
                                      child: Text(
                                        etichettaPriorita,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colore,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
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
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
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
                                        Text(
                                          'Apri modulo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
