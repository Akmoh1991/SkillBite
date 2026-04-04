import 'package:flutter/material.dart';

enum AppTextFieldDirectionMode { locale, contentAware, ltr, rtl }

class AppTextField extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final effectiveDirection = _resolveDirection(
          value.text,
          Directionality.of(context),
        );
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: decoration,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          minLines: minLines,
          maxLines: maxLines,
          autofocus: autofocus,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          onChanged: onChanged,
          textDirection: effectiveDirection,
          textAlign: TextAlign.start,
        );
      },
    );
  }

  TextDirection _resolveDirection(
    String text,
    TextDirection ambientDirection,
  ) {
    switch (directionMode) {
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
