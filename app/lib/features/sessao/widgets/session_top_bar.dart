import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/progress_bar.dart';

/// Topo fixo da Sessão: botão sair, progresso (contador + barra fina) com o
/// **combo** (acertos seguidos), e o botão de **report**. Idêntico em todos os
/// frames.
class SessionTopBar extends StatelessWidget {
  const SessionTopBar({
    super.key,
    required this.current,
    required this.total,
    this.combo,
    this.reportActive = false,
    this.onClose,
    this.onReport,
  });

  final int current;
  final int total;

  /// Combo atual; `null` esconde o chip (ex.: logo após um erro).
  final int? combo;
  final bool reportActive;
  final VoidCallback? onClose;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SquareButton(icon: AppIcons.close, onTap: onClose),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        style: AppType.mono(
                            size: 10.5,
                            weight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: c.muted),
                        children: [
                          TextSpan(
                              text: '$current',
                              style: TextStyle(color: c.primary)),
                          TextSpan(text: ' / $total'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (combo != null) _ComboChip(value: combo!),
                  ],
                ),
                const SizedBox(height: 5),
                ProgressBar(
                  value: total == 0 ? 0 : current / total,
                  color: c.primary,
                  height: 7,
                  gradient: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareButton(
          icon: AppIcons.report,
          onTap: onReport,
          active: reportActive,
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = active
        ? c.primary.withValues(alpha: 0.35)
        : c.line;
    return Material(
      color: c.paper,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: active ? 1.5 : 1),
          ),
          child: Icon(icon, size: 18, color: active ? c.primary : c.muted),
        ),
      ),
    );
  }
}

class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.accent.withValues(alpha: 0.24), c.paper),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.combo, size: 12, color: c.accentStrong),
          const SizedBox(width: 5),
          Text('×$value',
              style: AppType.fredoka(
                  size: 11.5, weight: FontWeight.w600, color: c.accentInk)),
        ],
      ),
    );
  }
}
