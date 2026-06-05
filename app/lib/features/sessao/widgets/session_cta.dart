import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Botão primário da Sessão (Entendi · Confirmar · Continuar). Quando
/// desabilitado (ex.: "Confirmar" antes de escolher), vira um bloco neutro.
class SessionCta extends StatelessWidget {
  const SessionCta({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(16);

    if (!enabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.muted.withValues(alpha: 0.22), c.paper),
          borderRadius: radius,
          border: Border.all(color: c.line, width: 1),
        ),
        child: Text(label,
            style: AppType.fredoka(
                size: 17, weight: FontWeight.w500, color: c.muted)),
      );
    }

    return Material(
      color: c.primary,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 11),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: c.onPrimary),
                const SizedBox(width: 9),
              ],
              Text(label,
                  style: AppType.fredoka(
                      size: 17, weight: FontWeight.w500, color: c.onPrimary)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 9),
                Icon(trailingIcon, size: 18, color: c.onPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
