import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Fundo "A" do Resumo: base areia/navy. No escuro, brilho radial azul no topo;
/// no claro, linhas horizontais finíssimas (a textura de papel do refino).
class ResumoBackground extends StatelessWidget {
  const ResumoBackground({super.key, required this.child});

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
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [
                      c.primary.withValues(alpha: 0.22),
                      c.primary.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.56],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: CustomPaint(
                  painter: _PaperLines(c.line.withValues(alpha: 0.18))),
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
