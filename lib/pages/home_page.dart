import 'package:flutter/material.dart';

import '../services/database_service.dart';

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
int dashboardRefresh = 0;
  List<Widget> get pages => [
        DashboardPage(
  key: ValueKey(dashboardRefresh),
),
        PrenotazioniPage(
  globalSearch: globalSearch,
  filtro: filtroPrenotazioni,
  onDatiModificati: () {
    setState(() {
      dashboardRefresh++;
    });
  },
),
        DiarioPage(
          soloDaFatturare: false,
        ),
        ScadenzePage(
  filtro: filtroScadenze,
),
        DiscentiPage(globalSearch: globalSearch),
        const ImpresePage(),
        const CorsiPage(),
        const PrezzarioPage(),
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

    if (index == 1) {
      filtroPrenotazioni = 'tutte';
    }

    if (index == 3) {
      filtroScadenze = 'tutte';
    }
  });

  if (index == 0) {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        setState(() {
          dashboardRefresh++;
        });
      },
    );
  }
},
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  AppTopbar(
                    onSearchChanged: aggiornaRicercaGlobale,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: pages[selectedIndex],
                  ),
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

  Map<String, int> kpi = {
    'prenotazioni': 0,
  'prenotazioni_aperte': 0,
  'prenotazioni_chiuse': 0,
  'diario': 0,
  'scadenze': 0,
  'scaduti': 0,
  'discenti': 0,
  'imprese': 0,
  'da_fatturare': 0,
  };

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

  if (!mounted) return;

  setState(() {
    kpi = {
      ...dati,
      'prenotazioni': totale,
      'prenotazioni_aperte': aperte,
      'prenotazioni_chiuse': chiuse,
    };
    caricamento = false;
  });
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: caricaKpi,
      child: ListView(
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Panoramica generale del gestionale formazione sicurezza',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
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
    final homeState =
        context.findAncestorStateOfType<_HomePageState>();

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
    final homeState =
        context.findAncestorStateOfType<_HomePageState>();

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
  onTap: () => apriPagina(context, 2),
                child: KpiCard(
                  title: 'Diario corsi',
                  value: kpi['diario'].toString(),
                  icon: Icons.menu_book,
                  color: const Color(0xFF16A34A),
                ),
              ),
              GestureDetector(
  onTap: () {
  final homeState =
      context.findAncestorStateOfType<_HomePageState>();

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
  final homeState =
      context.findAncestorStateOfType<_HomePageState>();

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
  onTap: () {
  final homeState =
      context.findAncestorStateOfType<_HomePageState>();

  homeState?.setState(() {
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
        ],
      ),
    );
  }
}