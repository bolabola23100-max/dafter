import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.controller,
    this.openingBalanceController,
    this.label,
    this.hintText,
    this.suffixText,
    this.prefixIcon,
    this.border,
    this.keyboardType,
    this.decoration,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.initialValue,
    this.readOnly = false,
    this.onTap,
    this.enabled,
    this.obscureText = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final TextEditingController? openingBalanceController;
  final String? label;
  final String? hintText;
  final String? suffixText;
  final dynamic prefixIcon;
  final InputBorder? border;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final TextAlign textAlign;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool? enabled;
  final bool obscureText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? openingBalanceController;

    Widget? resolvedPrefixIcon;
    if (prefixIcon != null) {
      if (prefixIcon is IconData) {
        resolvedPrefixIcon = Icon(prefixIcon as IconData);
      } else if (prefixIcon is Widget) {
        resolvedPrefixIcon = prefixIcon as Widget;
      }
    }

    final effectiveDecoration = decoration != null
        ? decoration!.copyWith(
            labelText: label ?? decoration!.labelText,
            hintText: hintText ?? decoration!.hintText,
            suffixText: suffixText ?? decoration!.suffixText,
            border: border ?? decoration!.border,
            prefixIcon: resolvedPrefixIcon ?? decoration!.prefixIcon,
          )
        : InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixText: suffixText,
            prefixIcon: resolvedPrefixIcon,
            border: border,
          );

    return TextFormField(
      controller: effectiveController,
      initialValue: effectiveController == null ? initialValue : null,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      textAlign: textAlign,
      readOnly: readOnly,
      onTap: onTap,
      enabled: enabled,
      obscureText: obscureText,
      focusNode: focusNode,
      decoration: effectiveDecoration,
    );
  }
}
