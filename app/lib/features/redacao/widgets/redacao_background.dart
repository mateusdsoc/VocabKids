import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Fundo da área de Redação — mesma base do app (areia/navy), brilho radial no
/// escuro / linhas de papel no claro. Coerente com Resumo e Identidade.
class RedacaoBackground extends StatelessWidget {
  const RedacaoBackground({super.key, required this.child});

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
                    center: const Alignment(0, -0.85),
                    radius: 1.15,
                    colors: [
                      c.primary.withValues(alpha: 0.20),
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
                  painter: _PaperLines(c.line.withValues(alpha: 0.16))),
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
