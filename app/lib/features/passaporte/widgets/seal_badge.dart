import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';

/// Selo de feito (produto §3.10) — medalha de cera/lacre dourada com o ícone do
/// feito; bloqueado vira silhueta pontilhada com cadeado. Inclui título e, se
/// [mostrarDescricao], a condição embaixo.
class SeloBadge extends StatelessWidget {
  const SeloBadge({
    super.key,
    required this.selo,
    this.medalSize = 58,
    this.mostrarDescricao = true,
  });

  final Selo selo;
  final double medalSize;
  final bool mostrarDescricao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ganho = selo.conquistado;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: medalSize,
          height: medalSize,
          child: CustomPaint(
            painter: ganho
                ? _Medal(gold: c.accent, deep: c.accentStrong)
                : _LockedMedal(c.muted.withValues(alpha: 0.35)),
            child: Center(
              child: Icon(
                ganho ? selo.icone : AppIcons.lock,
                size: medalSize * 0.36,
                color: ganho
                    ? c.accentInk
                    : c.muted.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selo.titulo,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.fredoka(
              size: 12.5,
              weight: FontWeight.w500,
              color: ganho ? c.ink : c.muted),
        ),
        if (mostrarDescricao) ...[
          const SizedBox(height: 1),
          Text(
            selo.descricao,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.nunito(
                size: 9.5, weight: FontWeight.w700, color: c.muted, height: 1.2),
          ),
        ],
      ],
    );
  }
}

/// Medalha dourada com borda "reeded" (coin) e anel interno.
class _Medal extends CustomPainter {
  _Medal({required this.gold, required this.deep});
  final Color gold;
  final Color deep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    // Dentes/serrilha da borda (lacre).
    final teeth = Paint()..color = deep.withValues(alpha: 0.9);
    const n = 24;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final p = Offset(center.dx + (r - 1) * math.cos(a),
          center.dy + (r - 1) * math.sin(a));
      canvas.drawCircle(p, r * 0.07, teeth);
    }

    // Disco com degradê.
    final disc = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(gold, Colors.white, 0.35)!, deep],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r * 0.86, disc);

    // Anel interno.
    canvas.drawCircle(
      center,
      r * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(_Medal old) => old.gold != gold || old.deep != deep;
}

/// Silhueta pontilhada do selo ainda não conquistado.
class _LockedMedal extends CustomPainter {
  _LockedMedal(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    canvas.drawCircle(
      center,
      r * 0.86,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;
    final circ = 2 * math.pi * r;
    final segs = (circ / (size.width * 0.13)).floor();
    final step = 2 * math.pi / segs;
    for (var i = 0; i < segs; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        i * step,
        step * 0.5,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_LockedMedal old) => old.color != color;
}
