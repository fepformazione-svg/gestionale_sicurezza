import 'package:flutter/material.dart';

class TableStatusBadge extends StatelessWidget {
  final String status;

  const TableStatusBadge({
    super.key,
    required this.status,
  });

  @override
Widget build(BuildContext context) {
  Color backgroundColor;
  Color textColor;
  IconData icon;

  switch (status) {

    case 'Aperto':
      backgroundColor = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF2563EB);
      icon = Icons.radio_button_checked;
      break;

    case 'Registro':
      backgroundColor = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFEA580C);
      icon = Icons.menu_book_rounded;
      break;

    case 'In corso':
      backgroundColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      icon = Icons.schedule_rounded;
      break;

    case 'Chiuso':
      backgroundColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      icon = Icons.check_circle;
      break;

    case 'Scaduto':
      backgroundColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
      break;

    case 'Da fatturare':
      backgroundColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0284C7);
      icon = Icons.receipt_long;
      break;

    default:
      backgroundColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF6B7280);
      icon = Icons.circle;
  }

  return Align(
    alignment: Alignment.centerLeft,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            icon,
            size: 14,
            color: textColor,
          ),

          const SizedBox(width: 6),

          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
}