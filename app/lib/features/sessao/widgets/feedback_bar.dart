import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';

/// Faixa de feedback pós-resposta. [positive] = acerto (verde + XP); senão é o
/// erro (vermelho), com o ícone de **rever** avisando que a questão volta no
/// fim da fila para uma nova chance.
class FeedbackBar extends StatelessWidget {
  const FeedbackBar({
    super.key,
    required this.positive,
    required this.title,
    required this.subtitle,
    this.xp,
  });

  final bool positive;
  final String title;
  final String subtitle;
  final int? xp;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = positive ? c.goal : c.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.12), c.paper),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.32), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(positive ? AppIcons.check : AppIcons.retry,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppType.fredoka(
                        size: 15, weight: FontWeight.w500, color: c.ink, height: 1.15)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!positive) ...[
                      Icon(AppIcons.retry, size: 12, color: accent),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(subtitle,
                          style: AppType.nunito(
                              size: 11.5, weight: FontWeight.w700, color: accent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (positive && xp != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Color.alphaBlend(c.goal.withValues(alpha: 0.16), c.paper),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('+$xp XP',
                  style: AppType.fredoka(
                      size: 15, weight: FontWeight.w600, color: c.goal)),
            ),
          ],
        ],
      ),
    );
  }
}
