import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models.dart';

/// Cabeçalho do país (variação "carimbo champanhe" da v5): nome do país em
/// dourado, "país atual" manuscrito, medidor de destinos e um anel pontilhado
/// decorativo no canto — sensação de carimbo de passaporte.
class CountryStamp extends StatelessWidget {
  const CountryStamp({super.key, required this.country});

  final TrilhaCountry country;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // O papel pode ser translúcido (vidro no claro); o carimbo é sólido.
    final paper = Color.alphaBlend(c.paper, c.bg);
    final fill = Color.alphaBlend(c.accent.withValues(alpha: 0.12), paper);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: c.accentStrong.withValues(alpha: 0.30), width: 1.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: CustomPaint(
              size: const Size(74, 74),
              painter: _DashedRing(c.accent.withValues(alpha: 0.38)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(country.name,
                      style: AppType.fredoka(
                          size: 22,
                          weight: FontWeight.w600,
                          color: c.accentStrong)),
                  const SizedBox(width: 8),
                  Text(country.tagline,
                      style: AppType.caveat(size: 14, color: c.muted)),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 8,
                        color: Color.alphaBlend(
                            c.accent.withValues(alpha: 0.22), paper),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: country.fraction.clamp(0.0, 1.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: LinearGradient(colors: [
                                  c.goal,
                                  Color.lerp(c.goal, Colors.white, 0.45)!,
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${country.destinationsDone} / ${country.destinationsTotal} destinos',
                    style: AppType.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: c.accentStrong),
                  ),
                ],
              ),
            ],
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
      ..strokeWidth = 2;
    final r = (size.width - 2) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final n = (2 * pi * r / 10).floor();
    final step = 2 * pi / n;
    final arc = step * 0.55;
    final rect = Rect.fromCircle(center: center, radius: r);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step, arc, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}
