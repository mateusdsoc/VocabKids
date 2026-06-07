import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';

/// Cabeçalho comemorativo do Resumo: selo com anel pontilhado, "Sessão
/// concluída!" e o contexto (cidade · lição).
class ResumoHeader extends StatelessWidget {
  const ResumoHeader({super.key, required this.city, required this.lesson});

  final String city;
  final int lesson;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SizedBox(
          width: 74,
          height: 74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(74, 74),
                painter: _DashedRing(c.goal.withValues(alpha: 0.30)),
              ),
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                      c.goal.withValues(alpha: 0.16), c.paper),
                  border: Border.all(
                      color: c.goal.withValues(alpha: 0.35), width: 2),
                ),
                child: Icon(AppIcons.check, size: 30, color: c.goal),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Text('Sessão concluída!',
            style: AppType.fredoka(size: 25, color: c.ink, height: 1.05)),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.pin, size: 12, color: c.primary),
            const SizedBox(width: 6),
            Text(
              '${city.toUpperCase()} · LIÇÃO $lesson',
              style: AppType.mono(
                  size: 10,
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: c.muted),
            ),
          ],
        ),
      ],
    );
  }
}

/// Anel pontilhado decorativo ao redor do selo (o `::before` dashed do design).
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
    final n = (circ / 9).floor(); // dash ~4 + gap ~5
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
