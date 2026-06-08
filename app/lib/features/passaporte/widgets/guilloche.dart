import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Padrão guilloché — as linhas finas de segurança de um passaporte/cédula,
/// desenhadas como uma hipotrocoide (rosácea de espirógrafo). Puramente
/// decorativo, em alpha baixo, para dar textura "de documento" sem roubar a cena.
class Guilloche extends StatelessWidget {
  const Guilloche({
    super.key,
    required this.color,
    this.petals = 7,
    this.inner = 4,
    this.depth = 0.62,
    this.turns = 1,
  });

  /// Cor das linhas (use alpha baixo).
  final Color color;

  /// Aproxima R (roda fixa) — mais pétalas, mais "denso".
  final int petals;

  /// Aproxima r (roda móvel).
  final int inner;

  /// Profundidade do traço (d), 0..1 do raio.
  final double depth;

  /// Quantas rosáceas sobrepostas (giradas), para encorpar.
  final int turns;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GuillochePainter(
        color: color,
        petals: petals,
        inner: inner,
        depth: depth,
        turns: turns,
      ),
    );
  }
}

class _GuillochePainter extends CustomPainter {
  _GuillochePainter({
    required this.color,
    required this.petals,
    required this.inner,
    required this.depth,
    required this.turns,
  });

  final Color color;
  final int petals;
  final int inner;
  final double depth;
  final int turns;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 0.7
      ..isAntiAlias = true;

    final big = petals.toDouble();
    final small = inner.toDouble();
    final d = depth * radius * (small / big);
    final ratio = (big - small) / small;
    // Período para fechar a curva.
    final g = _gcd(petals, inner);
    final period = 2 * math.pi * (inner ~/ g);

    for (var k = 0; k < turns; k++) {
      final rot = (k / turns) * (math.pi / petals);
      final path = Path();
      var first = true;
      for (double t = 0; t <= period + 0.02; t += 0.04) {
        final x = (radius - radius * (small / big)) * math.cos(t) +
            d * math.cos(ratio * t);
        final y = (radius - radius * (small / big)) * math.sin(t) -
            d * math.sin(ratio * t);
        final rx = x * math.cos(rot) - y * math.sin(rot);
        final ry = x * math.sin(rot) + y * math.cos(rot);
        final p = Offset(center.dx + rx, center.dy + ry);
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  @override
  bool shouldRepaint(_GuillochePainter old) =>
      old.color != color ||
      old.petals != petals ||
      old.inner != inner ||
      old.depth != depth ||
      old.turns != turns;
}
