import 'package:flutter/material.dart';

class EnterpriseOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const EnterpriseOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class EnterpriseAutocompleteField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<EnterpriseOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const EnterpriseAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<EnterpriseAutocompleteField<T>> createState() =>
      _EnterpriseAutocompleteFieldState<T>();
}

class _EnterpriseAutocompleteFieldState<T>
    extends State<EnterpriseAutocompleteField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _open = false;
  String _search = '';

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _focusNode = FocusNode();

    _syncText();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.enabled) {
        setState(() {
          _open = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant EnterpriseAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value ||
        oldWidget.options != widget.options) {
      _syncText();
    }
  }

  void _syncText() {
    final selected = widget.options.where((e) => e.value == widget.value);

    if (selected.isNotEmpty) {
      _controller.text = selected.first.label;
    } else {
      _controller.text = '';
    }
  }

  List<EnterpriseOption<T>> get _filteredOptions {
    final q = _search.trim().toLowerCase();

    if (q.isEmpty) {
      return widget.options.take(30).toList();
    }

    return widget.options.where((item) {
      final label = item.label.toLowerCase();
      final subtitle = item.subtitle?.toLowerCase() ?? '';

      return label.contains(q) || subtitle.contains(q);
    }).take(50).toList();
  }

  void _select(EnterpriseOption<T> option) {
    widget.onChanged(option.value);

    setState(() {
      _controller.text = option.label;
      _search = '';
      _open = false;
    });

    FocusScope.of(context).unfocus();
  }

  void _clear() {
    widget.onChanged(null);

    setState(() {
      _controller.clear();
      _search = '';
      _open = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredOptions;

    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _open = true;
                });
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: true,
                fillColor:
                    widget.enabled ? Colors.white : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty && widget.enabled)
                      IconButton(
                        tooltip: 'Cancella',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clear,
                      ),
                    const Icon(Icons.expand_more),
                    const SizedBox(width: 6),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.4,
                  ),
                ),
                errorText: field.errorText,
              ),
            ),
            if (_open && widget.enabled) ...[
              const SizedBox(height: 8),
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 260,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Nessun risultato trovato',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return InkWell(
                              onTap: () {
                                _select(item);
                                field.didChange(item.value);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (item.subtitle != null &&
                                              item.subtitle!.trim().isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Text(
                                                item.subtitle!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}