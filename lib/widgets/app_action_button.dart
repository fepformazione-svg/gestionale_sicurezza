import 'package:flutter/material.dart';

enum AppActionButtonType {
  nuovo,
  aggiorna,
  excel,
  pdf,
  stampa,
  elimina,
  modifica,
}

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.label,
    this.compact = false,
    this.expanded = false,
  });

  final AppActionButtonType type;
  final VoidCallback? onPressed;
  final String? label;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final config = _ActionButtonConfig.fromType(context, type);

    final button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(config.icon, size: compact ? 18 : 20),
      label: Text(label ?? config.label, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: config.backgroundColor,
        foregroundColor: config.foregroundColor,
        disabledBackgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(180),
        disabledForegroundColor: Theme.of(
          context,
        ).colorScheme.onSurface.withAlpha(120),
        elevation: type == AppActionButtonType.elimina ? 0 : 1,
        minimumSize: Size(0, compact ? 38 : 42),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

class _ActionButtonConfig {
  const _ActionButtonConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  factory _ActionButtonConfig.fromType(
    BuildContext context,
    AppActionButtonType type,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case AppActionButtonType.nuovo:
        return _ActionButtonConfig(
          label: 'Nuovo',
          icon: Icons.add,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        );

      case AppActionButtonType.aggiorna:
        return _ActionButtonConfig(
          label: 'Aggiorna',
          icon: Icons.refresh,
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
        );

      case AppActionButtonType.excel:
        return _ActionButtonConfig(
          label: 'Excel',
          icon: Icons.table_chart,
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        );

      case AppActionButtonType.pdf:
        return _ActionButtonConfig(
          label: 'PDF',
          icon: Icons.picture_as_pdf,
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        );

      case AppActionButtonType.stampa:
        return _ActionButtonConfig(
          label: 'Stampa',
          icon: Icons.print,
          backgroundColor: Colors.blueGrey.shade700,
          foregroundColor: Colors.white,
        );

      case AppActionButtonType.elimina:
        return _ActionButtonConfig(
          label: 'Elimina',
          icon: Icons.delete_outline,
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
        );

      case AppActionButtonType.modifica:
        return _ActionButtonConfig(
          label: 'Modifica',
          icon: Icons.edit_outlined,
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
        );
    }
  }
}
