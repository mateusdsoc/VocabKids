import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Campo de formulário com a roupa da marca (usado no Embarque). Rótulo em
/// micro-caixa-alta (mono), superfície [AppColors.paper] opaca por legibilidade,
/// borda hairline que acende na cor primária ao focar e erro no âmbar gentil
/// ([AppColors.warn]) — nunca vermelho punitivo, igual ao resto do app.
class PassportField extends StatelessWidget {
  const PassportField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color col, double w) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: col, width: w),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppType.mono(
              size: 9.5,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
              color: c.muted),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          cursorColor: c.primary,
          style:
              AppType.nunito(size: 16, weight: FontWeight.w800, color: c.ink),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.paper,
            hintText: hint,
            hintStyle: AppType.nunito(
                size: 15, weight: FontWeight.w600, color: c.muted),
            prefixIcon: Icon(icon, size: 19, color: c.primary),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
            enabledBorder: border(c.line, 1),
            focusedBorder: border(c.primary, 1.6),
            errorBorder: border(c.warn, 1),
            focusedErrorBorder: border(c.warn, 1.6),
            errorStyle: AppType.nunito(
                size: 11.5, weight: FontWeight.w700, color: c.warn),
          ),
        ),
      ],
    );
  }
}
