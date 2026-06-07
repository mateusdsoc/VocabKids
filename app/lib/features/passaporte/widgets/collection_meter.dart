import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/progress_bar.dart';

/// Medidor da coleção — "X de Y lembranças", com barra dourada. Mostra o quanto
/// do passaporte já foi preenchido (motivador por si só).
class CollectionMeter extends StatelessWidget {
  const CollectionMeter({
    super.key,
    required this.conquistadas,
    required this.total,
    this.label = 'lembranças coletadas',
  });

  final int conquistadas;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$conquistadas',
                style: AppType.fredoka(size: 22, color: c.accentStrong, height: 1.0)),
            const SizedBox(width: 4),
            Text('de $total',
                style: AppType.fredoka(
                    size: 14, weight: FontWeight.w500, color: c.muted)),
            const Spacer(),
            Text(label.toUpperCase(),
                style: AppType.mono(
                    size: 9, weight: FontWeight.w700, letterSpacing: 1.0, color: c.muted)),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(
          value: total == 0 ? 0 : conquistadas / total,
          color: c.accent,
          gradient: true,
          height: 8,
        ),
      ],
    );
  }
}
