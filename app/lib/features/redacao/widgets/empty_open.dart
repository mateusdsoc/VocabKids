import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';

/// Estado vazio (nenhuma redação aberta) — gentil, dentro da metáfora: um selo
/// pontilhado à espera de um carimbo. Nunca uma tela morta.
class EmptyOpen extends StatelessWidget {
  const EmptyOpen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _DashedRing(c.muted.withValues(alpha: 0.35)),
                ),
                Icon(AppIcons.redacao, size: 26, color: c.muted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Nenhum tema aberto',
              style: AppType.fredoka(size: 18, color: c.ink)),
          const SizedBox(height: 6),
          Text(
            'Um novo tema chega aqui de tempos em\ntempos, pra você escrever sobre ele.',
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 13, weight: FontWeight.w600, color: c.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  _DashedRing(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final r = (size.width - 2) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circ = 2 * pi * r;
    final n = (circ / 9).floor();
    final step = 2 * pi / n;
    final arc = 4 / r;
    final rect = Rect.fromCircle(center: center, radius: r);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step, arc, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}
