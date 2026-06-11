import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Burst de confete curto (~800 ms): roda **uma vez** ao montar, espalha do
/// centro com gravidade leve e desvanece. Não-bloqueante ([IgnorePointer]).
/// Usado no acerto da Sessão e na chegada ao nó da Trilha.
///
/// Cores padrão = tokens primária/ouro/sucesso (nunca hardcoded); o chamador
/// pode sobrescrever via [colors].
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.colors});

  final List<Color>? colors;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(
            progress: _controller.value,
            colors: widget.colors ?? [c.primary, c.accent, c.goal],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  /// (ângulo em voltas, alcance 0..1, lado px, índice de cor, círculo?, giro rad)
  static const _bits = [
    (0.94, 1.00, 6.5, 0, false, 2.6),
    (0.80, 0.85, 5.5, 1, true, 0.0),
    (0.66, 1.00, 7.0, 2, false, -2.2),
    (0.53, 0.80, 5.0, 0, true, 0.0),
    (0.40, 0.95, 6.0, 1, false, 3.1),
    (0.28, 0.85, 6.5, 2, false, -2.8),
    (0.13, 1.00, 5.5, 0, false, 2.0),
    (0.05, 0.75, 5.0, 1, true, 0.0),
    (0.59, 0.65, 4.5, 1, false, -1.6),
    (0.33, 0.60, 4.5, 2, true, 0.0),
    (0.87, 0.70, 5.0, 2, false, 1.8),
    (0.20, 0.70, 6.0, 0, true, 0.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final spread = Curves.easeOutCubic.transform(progress);
    final fade =
        progress < 0.55 ? 1.0 : 1 - (progress - 0.55) / 0.45; // some no fim
    final center = Offset(size.width / 2, size.height / 2);
    final paintBit = Paint();

    for (final (turns, reach, side, colorIx, round, spin) in _bits) {
      final angle = turns * 2 * math.pi;
      final pos = center +
          Offset(
            math.cos(angle) * size.width * 0.46 * reach * spread,
            math.sin(angle) * size.height * 0.85 * reach * spread +
                10 * progress * progress, // gravidade leve
          );
      paintBit.color = colors[colorIx].withValues(alpha: 0.95 * fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(spin * progress);
      final rect =
          Rect.fromCenter(center: Offset.zero, width: side, height: side);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(round ? side / 2 : 2)),
        paintBit,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.colors != colors;
}
