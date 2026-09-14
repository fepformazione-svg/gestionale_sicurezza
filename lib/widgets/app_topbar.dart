import 'package:flutter/material.dart';

import '../models/assistente_operativo_item.dart';
import '../pages/impostazioni_page.dart';

class AppTopbar extends StatefulWidget {
  final String userName;
  final String searchText;
  final ValueChanged<String>? onSearchChanged;
  final List<AssistenteOperativoItem> notificationItems;
  final ValueChanged<AssistenteOperativoItem>? onNotificationSelected;

  const AppTopbar({
    super.key,
    this.userName = 'Alessandro',
    this.searchText = '',
    this.onSearchChanged,
    this.notificationItems = const <AssistenteOperativoItem>[],
    this.onNotificationSelected,
  });

  @override
  State<AppTopbar> createState() => _AppTopbarState();
}

class _AppTopbarState extends State<AppTopbar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchText;
  }

  @override
  void didUpdateWidget(covariant AppTopbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchText != widget.searchText &&
        _searchController.text != widget.searchText) {
      _searchController.text = widget.searchText;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _notificationBadgeText {
    final count = widget.notificationItems.length;
    return count > 99 ? '99+' : count.toString();
  }

  Color _notificationPriorityColor(PrioritaAssistenteOperativo priorita) {
    switch (priorita) {
      case PrioritaAssistenteOperativo.alta:
        return const Color(0xFFB91C1C);
      case PrioritaAssistenteOperativo.media:
        return const Color(0xFFB45309);
      case PrioritaAssistenteOperativo.bassa:
        return const Color(0xFF2563EB);
    }
  }

  Widget _buildNotificationButton() {
    final hasNotifications = widget.notificationItems.isNotEmpty;

    return PopupMenuButton<AssistenteOperativoItem>(
      tooltip: 'Notifiche',
      offset: const Offset(0, 48),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 380),
      onSelected: (item) {
        widget.onNotificationSelected?.call(item);
      },
      itemBuilder: (context) {
        if (!hasNotifications) {
          return const [
            PopupMenuItem<AssistenteOperativoItem>(
              enabled: false,
              child: Text(
                'Nessuna priorità operativa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ];
        }

        return widget.notificationItems.map((item) {
          final colore = _notificationPriorityColor(item.priorita);

          return PopupMenuItem<AssistenteOperativoItem>(
            value: item,
            child: SizedBox(
              width: 340,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: colore,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.titolo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.descrizione,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colore.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.conteggio.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colore,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none, color: Color(0xFF374151)),
            if (hasNotifications)
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _notificationBadgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          const Icon(Icons.search, color: Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Ricerca globale...',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ),
          ),
          _buildNotificationButton(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ImpostazioniPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF374151)),
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
            widget.userName,
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
