import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';

/// Cartão-estatística do Passaporte: rótulo micro + ícone no acento da métrica e
/// o número-herói em Fredoka. Usado em trio (XP, palavras, nível).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(height: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.fredoka(size: 23, color: c.ink, height: 1.0)),
          const SizedBox(height: 3),
          Text(label.toUpperCase(),
              maxLines: 2,
              style: AppType.mono(
                  size: 8.5,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: c.muted)),
        ],
      ),
    );
  }
}
