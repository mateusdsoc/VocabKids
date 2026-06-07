import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';

/// Carimbo da marca, herói do Embarque: anel pontilhado dourado em volta de um
/// globo (gradiente do avatar), o wordmark "VocabKids" em Fredoka e a assinatura
/// manuscrita (Caveat) — o mesmo vocabulário visual do selo do Passaporte.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(92, 92),
                painter: _DashedRing(c.accent.withValues(alpha: 0.55)),
              ),
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: c.avatarGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: const Icon(AppIcons.globe, size: 38, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('VocabKids',
            style: AppType.fredoka(size: 31, color: c.ink, height: 1.0)),
        const SizedBox(height: 2),
        Text('sua viagem pelo vocabulário',
            style: AppType.caveat(size: 21, color: c.accentStrong)),
      ],
    );
  }
}

/// Anel pontilhado decorativo (o mesmo motivo do selo do Resumo).
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
