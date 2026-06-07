import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import '../models.dart';

/// Linha de progressão de uma palavra (dominada ✓ ou subiu de nível ↑). Usa o
/// [SurfaceCard] de vidro, como o resto dos cards.
class WordProgressRow extends StatelessWidget {
  const WordProgressRow({super.key, required this.word});

  final WordProgress word;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dom = word.change == WordChange.dominated;
    final accent = dom ? c.goal : c.primary;
    final icon = dom ? AppIcons.check : AppIcons.up;
    final label =
        dom ? 'Dominada!' : 'Nível ${word.fromLevel} → ${word.toLevel}';

    return SurfaceCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                  accent.withValues(alpha: dom ? 0.16 : 0.13), c.paper),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(word.word,
                style: AppType.fredoka(
                    size: 16, weight: FontWeight.w500, color: c.ink)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                  accent.withValues(alpha: dom ? 0.14 : 0.12), c.paper),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: accent),
                const SizedBox(width: 5),
                Text(label,
                    style: AppType.nunito(
                        size: 11.5, weight: FontWeight.w800, color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
