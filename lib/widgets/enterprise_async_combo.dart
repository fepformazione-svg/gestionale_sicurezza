import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sqlite_search_service.dart';

class EnterpriseAsyncCombo extends StatefulWidget {
  final String label;
  final String hintText;
  final int? selectedId;
  final String? selectedText;
  final Future<List<SearchItem>> Function(String query) onSearch;
  final ValueChanged<SearchItem?> onChanged;

  const EnterpriseAsyncCombo({
    super.key,
    required this.label,
    required this.hintText,
    required this.selectedId,
    required this.selectedText,
    required this.onSearch,
    required this.onChanged,
  });

  @override
  State<EnterpriseAsyncCombo> createState() => _EnterpriseAsyncComboState();
}

class _EnterpriseAsyncComboState extends State<EnterpriseAsyncCombo> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  List<SearchItem> _items = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();

    _controller.text = widget.selectedText ?? '';

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 450), () {
          _removeOverlay();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant EnterpriseAsyncCombo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedText != widget.selectedText) {
      _controller.text = widget.selectedText ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged(null);
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      _items = [];
      _loading = false;
      _removeOverlay();
      setState(() {});
      return;
    }

    _loading = true;
    _showOverlay();
    setState(() {});

    _debounce = Timer(const Duration(milliseconds: 320), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    _lastQuery = query;

    try {
      final result = await widget.onSearch(query);

      if (!mounted) return;
      if (_lastQuery != query) return;

      _items = result;
      _loading = false;
      _showOverlay();
      setState(() {});
    } catch (_) {
      if (!mounted) return;

      _items = [];
      _loading = false;
      _showOverlay();
      setState(() {});
    }
  }

  void _select(SearchItem item) {
    _debounce?.cancel();

    _controller.text = item.text;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    _items = [];
    _loading = false;

    widget.onChanged(item);

    _removeOverlay();

    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _debounce?.cancel();

    _controller.clear();
    _items = [];
    _loading = false;

    widget.onChanged(null);

    _removeOverlay();
    setState(() {});
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _fieldWidth(),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 82),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildDropdown(),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  double _fieldWidth() {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size.width ?? 300;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _clear,
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Ricerca in corso...',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Nessun risultato trovato',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      shrinkWrap: true,
      itemCount: _items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
      itemBuilder: (context, index) {
        final item = _items[index];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              _select(item);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                item.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
