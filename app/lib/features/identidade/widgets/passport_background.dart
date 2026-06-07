import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Fundo de viagem compartilhado pelas telas de identidade (Embarque e
/// Passaporte). Casa com o resto do app: base areia/navy, brilho radial no
/// escuro / linhas de papel no claro, e uma **rota tracejada com pinos** — o
/// "mapa-múndi" discreto da marca, que amarra a metáfora de viagem.
class PassportBackground extends StatelessWidget {
  const PassportBackground({super.key, required this.child});

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
          Positioned.fill(
            child: CustomPaint(
              painter: _FlightPath(
                line: c.accent.withValues(alpha: dark ? 0.22 : 0.26),
                pin: c.primary.withValues(alpha: dark ? 0.50 : 0.38),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Textura de papel do tema claro (linhas horizontais finíssimas).
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

/// Rota de voo tracejada cruzando a tela, com pinos nas pontas — bem discreta
/// para não competir com o conteúdo.
class _FlightPath extends CustomPainter {
  _FlightPath({required this.line, required this.pin});
  final Color line;
  final Color pin;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.08, size.height * 0.80);
    final end = Offset(size.width * 0.94, size.height * 0.14);
    final ctrl = Offset(size.width * 0.30, size.height * 0.16);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final metric = path.computeMetrics().first;
    const dash = 6.0, gap = 7.0;
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(
        metric.extractPath(d, (d + dash).clamp(0, metric.length)),
        stroke,
      );
      d += dash + gap;
    }

    final dot = Paint()..color = pin;
    final halo = Paint()..color = pin.withValues(alpha: 0.25);
    for (final p in [start, end]) {
      canvas.drawCircle(p, 7, halo);
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(_FlightPath old) => old.line != line || old.pin != pin;
}
