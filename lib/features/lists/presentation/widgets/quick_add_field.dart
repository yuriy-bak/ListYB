import 'package:flutter/material.dart';

class QuickAddField extends StatefulWidget {
  const QuickAddField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
    this.autofocus = false,
    this.textFieldKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final bool autofocus;

  /// Ключ для внутреннего TextField (чтобы тесты находили именно поле ввода)
  final Key? textFieldKey;

  @override
  State<QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends State<QuickAddField> {
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {
      _isComposing = widget.controller.text.trim().isNotEmpty;
    });
  }

  void _handleSubmitted(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    widget.onSubmitted(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return TextField(
      key: widget.textFieldKey, // Ключ висит только на TextField
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        suffixIcon: _isComposing
            ? IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: cs.primary,
                onPressed: () => _handleSubmitted(widget.controller.text),
              )
            : null,
      ),
      onSubmitted: _handleSubmitted,
    );
  }
}
