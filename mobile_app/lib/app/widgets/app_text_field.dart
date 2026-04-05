import 'package:flutter/material.dart';

enum AppTextFieldDirectionMode { locale, contentAware, ltr, rtl }

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.autofillHints,
    this.onChanged,
    this.directionMode = AppTextFieldDirectionMode.contentAware,
    this.enableInteractiveSelection = true,
    this.enableIMEPersonalizedLearning = false,
    this.scrollPadding = EdgeInsets.zero,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final bool obscureText;
  final bool? enabled;
  final bool readOnly;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final AppTextFieldDirectionMode directionMode;
  final bool enableInteractiveSelection;
  final bool enableIMEPersonalizedLearning;
  final EdgeInsets scrollPadding;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextDirection _effectiveDirection;

  @override
  void initState() {
    super.initState();
    _effectiveDirection = _resolveDirection(
      widget.controller.text,
      TextDirection.ltr,
    );
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
      _effectiveDirection = _resolveDirection(
        widget.controller.text,
        Directionality.of(context),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextDirection = _resolveDirection(
      widget.controller.text,
      Directionality.of(context),
    );
    if (nextDirection != _effectiveDirection) {
      _effectiveDirection = nextDirection;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final nextDirection = _resolveDirection(
      widget.controller.text,
      Directionality.of(context),
    );
    if (nextDirection == _effectiveDirection || !mounted) {
      return;
    }
    setState(() {
      _effectiveDirection = nextDirection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      scrollPadding: widget.scrollPadding,
      textDirection: _effectiveDirection,
      textAlign: TextAlign.start,
    );
  }

  TextDirection _resolveDirection(
    String text,
    TextDirection ambientDirection,
  ) {
    switch (widget.directionMode) {
      case AppTextFieldDirectionMode.locale:
        return ambientDirection;
      case AppTextFieldDirectionMode.ltr:
        return TextDirection.ltr;
      case AppTextFieldDirectionMode.rtl:
        return TextDirection.rtl;
      case AppTextFieldDirectionMode.contentAware:
        return _inferDirection(text, ambientDirection);
    }
  }

  TextDirection _inferDirection(
    String text,
    TextDirection ambientDirection,
  ) {
    for (final rune in text.runes) {
      if (_isArabicRune(rune)) {
        return TextDirection.rtl;
      }
      if (_isStrongLtrRune(rune)) {
        return TextDirection.ltr;
      }
    }
    return ambientDirection;
  }

  bool _isArabicRune(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  bool _isStrongLtrRune(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A) ||
        (rune >= 0x0030 && rune <= 0x0039) ||
        (rune >= 0x00C0 && rune <= 0x02AF);
  }
}
