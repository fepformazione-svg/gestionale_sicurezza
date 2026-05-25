import 'package:flutter/material.dart';

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

  List<Widget> get pages => [
        const DashboardPage(),
        PrenotazioniPage(globalSearch: globalSearch),
        const DiarioPage(),
        const ScadenzePage(),
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
              });
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          shrinkWrap: true,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 2.4,
          children: const [
            KpiCard(
              title: 'Prenotazioni',
              value: '0',
              icon: Icons.calendar_month,
              color: Color(0xFF2563EB),
            ),
            KpiCard(
              title: 'Diario corsi',
              value: '0',
              icon: Icons.menu_book,
              color: Color(0xFF16A34A),
            ),
            KpiCard(
              title: 'Scadenze',
              value: '0',
              icon: Icons.warning_amber,
              color: Color(0xFFDC2626),
            ),
            KpiCard(
              title: 'Discenti',
              value: '0',
              icon: Icons.people,
              color: Color(0xFF7C3AED),
            ),
            KpiCard(
              title: 'Imprese',
              value: '0',
              icon: Icons.business,
              color: Color(0xFFF59E0B),
            ),
            KpiCard(
              title: 'Da fatturare',
              value: '0',
              icon: Icons.euro,
              color: Color(0xFF0891B2),
            ),
          ],
        ),
      ],
    );
  }
}