import 'package:flutter/material.dart';

class AppTopbar extends StatelessWidget {
  final String userName;
  final ValueChanged<String>? onSearchChanged;

  const AppTopbar({
    super.key,
    this.userName = 'Alessandro',
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Ricerca globale...',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifiche',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            userName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}