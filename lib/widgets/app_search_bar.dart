import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onArrowDown;

  const AppSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onArrowDown,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controllerInterno;
  late final bool _usaControllerEsterno;

  TextEditingController get _controller =>
      _usaControllerEsterno ? widget.controller! : _controllerInterno;

  @override
  void initState() {
    super.initState();

    _usaControllerEsterno = widget.controller != null;
    _controllerInterno = TextEditingController();

    _controller.addListener(_aggiornaIcona);
  }

  @override
  void dispose() {
    _controller.removeListener(_aggiornaIcona);

    if (!_usaControllerEsterno) {
      _controllerInterno.dispose();
    }

    super.dispose();
  }

  void _aggiornaIcona() {
    if (mounted) {
      setState(() {});
    }
  }

  void _azzeraRicerca() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ricercaAttiva = _controller.text.trim().isNotEmpty;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: (_) {
          widget.onArrowDown?.call();
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          suffixIcon: ricercaAttiva
              ? Tooltip(
                  message: 'Azzera ricerca',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _azzeraRicerca,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
