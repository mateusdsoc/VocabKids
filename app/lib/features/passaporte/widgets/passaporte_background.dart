import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'guilloche.dart';

/// Fundo do Passaporte — base do app (areia/navy) com brilho no escuro / linhas
/// de papel no claro, e um guilloché translúcido grande ao fundo (textura de
/// documento). Coerente com Resumo/Identidade/Redação.
class PassaporteBackground extends StatelessWidget {
  const PassaporteBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.bg),
      child: Stack(
        children: [
          if (dark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.9),
                    radius: 1.2,
                    colors: [
                      c.primary.withValues(alpha: 0.18),
                      c.primary.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: CustomPaint(
                  painter: _PaperLines(c.line.withValues(alpha: 0.14))),
            ),
          // Guilloché grande, bem discreto, ancorado ao topo.
          Positioned(
            top: -120,
            right: -90,
            width: 360,
            height: 360,
            child: Guilloche(
              color: c.accent.withValues(alpha: dark ? 0.07 : 0.06),
              petals: 9,
              inner: 4,
              depth: 0.7,
              turns: 2,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PaperLines extends CustomPainter {
  _PaperLines(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_PaperLines old) => old.color != color;
}
