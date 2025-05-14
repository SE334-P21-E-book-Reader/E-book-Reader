import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? fillColor;
  final Widget? prefixIcon;

  const SearchBar({
    Key? key,
    required this.hintText,
    required this.onChanged,
    this.initialValue,
    this.padding,
    this.borderColor,
    this.fillColor,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: TextField(
        controller: initialValue != null
            ? TextEditingController(text: initialValue)
            : null,
        decoration: InputDecoration(
          prefixIcon: prefixIcon ?? const Icon(Icons.search),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: borderColor ?? theme.dividerColor),
          ),
          filled: true,
          fillColor: fillColor ??
              theme.inputDecorationTheme.fillColor ??
              theme.colorScheme.surface,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
