import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';
import '../tones.dart';

/// Carimbo de país (produto §3.10) — desenhado como um **postmark** de verdade:
/// anel duplo, nome do país em arco, estrelinhas no arco inferior e a inicial no
/// miolo, com leve inclinação (a "batida" do carimbo). Conquistado = tinta do
/// país; bloqueado = slot pontilhado com cadeado (o que falta carimbar).
class Carimbo extends StatelessWidget {
  const Carimbo({
    super.key,
    required this.pais,
    required this.conquistado,
    this.size = 84,
    this.tilt = -0.11,
  });

  final Pais pais;
  final bool conquistado;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!conquistado) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _LockedStamp(c.muted.withValues(alpha: 0.38)),
          child: Center(
            child: Icon(AppIcons.lock,
                size: size * 0.26, color: c.muted.withValues(alpha: 0.6)),
          ),
        ),
      );
    }
    final tone = paisTone(context, pais);
    return Transform.rotate(
      angle: tilt,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PostmarkPainter(
            label: pais.nome.toUpperCase(),
            ink: tone.ink,
          ),
          child: Center(
            child: Text(
              pais.inicial,
              style: AppType.fredoka(
                  size: size * 0.26, color: tone.ink, height: 1.0),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostmarkPainter extends CustomPainter {
  _PostmarkPainter({required this.label, required this.ink});
  final String label;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rOuter = size.width / 2 - 1;
    final rInner = rOuter - size.width * 0.11;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink.withValues(alpha: 0.92)
      ..strokeWidth = size.width * 0.035;
    canvas.drawCircle(center, rOuter, ring);
    canvas.drawCircle(center, rInner, ring..strokeWidth = size.width * 0.022);

    // Nome do país em arco no topo.
    _arcText(
      canvas,
      label,
      center,
      (rOuter + rInner) / 2,
      AppType.mono(
          size: size.width * 0.095,
          weight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ink.withValues(alpha: 0.95)),
      centerAngle: -math.pi / 2, // topo
      clockwise: true,
    );

    // Estrelinhas no arco inferior (orientação-agnósticas).
    final star = Paint()..color = ink.withValues(alpha: 0.9);
    const n = 3;
    const spread = 0.7; // radianos
    final mid = (rOuter + rInner) / 2;
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.0 : (i / (n - 1)) * 2 - 1; // -1..1
      final a = math.pi / 2 + t * spread;
      final p = Offset(center.dx + mid * math.cos(a), center.dy + mid * math.sin(a));
      _star(canvas, p, size.width * 0.035, star);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 - math.pi / 2;
      final rad = i.isEven ? r : r * 0.45;
      final pt = Offset(c.dx + rad * math.cos(ang), c.dy + rad * math.sin(ang));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _arcText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    TextStyle style, {
    required double centerAngle,
    required bool clockwise,
  }) {
    final painters = <TextPainter>[];
    var totalAngle = 0.0;
    for (final ch in text.characters) {
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(tp);
      totalAngle += (tp.width + 1.5) / radius;
    }
    final dir = clockwise ? 1.0 : -1.0;
    var angle = centerAngle - dir * totalAngle / 2;
    for (final tp in painters) {
      final charAngle = (tp.width + 1.5) / radius;
      angle += dir * charAngle / 2;
      final pos = Offset(
          center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(clockwise ? angle + math.pi / 2 : angle - math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
      angle += dir * charAngle / 2;
    }
  }

  @override
  bool shouldRepaint(_PostmarkPainter old) =>
      old.label != label || old.ink != ink;
}

/// Slot pontilhado do carimbo ainda não conquistado.
class _LockedStamp extends CustomPainter {
  _LockedStamp(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;
    final circ = 2 * math.pi * r;
    final n = (circ / (size.width * 0.13)).floor();
    final step = 2 * math.pi / n;
    final arc = step * 0.5;
    final rect = Rect.fromCircle(center: center, radius: r);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step, arc, false, p);
    }
  }

  @override
  bool shouldRepaint(_LockedStamp old) => old.color != color;
}
