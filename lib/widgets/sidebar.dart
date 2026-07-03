import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF111827),
      child: Column(
        children: [
          // LOGO
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: const Text(
              'GESTIONALE\nSICUREZZA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),

          // MENU
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),

                _buildMenuItem(
                  icon: Icons.calendar_month,
                  title: 'Prenotazioni',
                  index: 1,
                ),

                _buildMenuItem(
                  icon: Icons.menu_book,
                  title: 'Diario',
                  index: 2,
                ),

                _buildMenuItem(
                  icon: Icons.warning_amber,
                  title: 'Scadenze',
                  index: 3,
                ),

                _buildMenuItem(icon: Icons.people, title: 'Discenti', index: 4),

                _buildMenuItem(
                  icon: Icons.business,
                  title: 'Imprese',
                  index: 5,
                ),

                _buildMenuItem(icon: Icons.school, title: 'Corsi', index: 6),

                _buildMenuItem(icon: Icons.euro, title: 'Prezzario', index: 7),
                _buildMenuItem(
                  icon: Icons.medical_services_outlined,
                  title: 'Visite Mediche',
                  index: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),

            const SizedBox(width: 14),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
