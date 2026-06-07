import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Linha tracejada horizontal — o "picote" do bilhete/passaporte. Usada para
/// separar o cabeçalho do corpo nos cartões de embarque e de identidade.
class Perforation extends StatelessWidget {
  const Perforation({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final col = color ?? context.colors.muted.withValues(alpha: 0.40);
    return SizedBox(height: 1.4, child: CustomPaint(painter: _DashPainter(col)));
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 5.0, gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width), 0),
        p,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
