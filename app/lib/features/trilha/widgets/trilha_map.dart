import 'dart:math' show pi, cos, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';
import 'map_pins.dart';
import 'trilha_tones.dart';

/// Espaço lógico do mapa (igual ao design): 340 de largura × 540 de altura.
const double _mapW = 340;
const double _mapH = 540;

/// O mapa da Trilha: banhos de cor por país, textura cartográfica, o caminho
/// sinuoso (percorrido vivo + futuro rebaixado), a fronteira única e os nós.
class TrilhaMap extends StatelessWidget {
  const TrilhaMap({super.key, required this.data, this.onContinue});

  final TrilhaMapData data;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = TrilhaTones.of(context);
    final fy = data.frontierY;

    return ClipRect(
      child: SizedBox(
        width: _mapW,
        height: _mapH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // banhos de cor (frio em cima, quente embaixo)
            Positioned(
              left: -10, right: -10, top: 0, height: fy + 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.92),
                    radius: 1.1,
                    colors: [t.washCool, t.washCool.withValues(alpha: 0)],
                    stops: const [0, 0.8],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -10, right: -10, top: fy - 20, bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.2),
                    radius: 1.0,
                    colors: [t.washWarm, t.washWarm.withValues(alpha: 0)],
                    stops: const [0, 0.78],
                  ),
                ),
              ),
            ),
            // textura cartográfica
            Positioned.fill(child: CustomPaint(painter: _TexturePainter(t))),
            // caminho
            Positioned.fill(child: CustomPaint(painter: _PathPainter(data.nodes, t))),
            // fronteira única
            Positioned(
              left: 14, right: 14, top: fy - 11,
              child: _Frontier(label: data.frontierLabel ?? 'Fronteira', tones: t),
            ),
            // nós
            for (final n in data.nodes) _positionedPin(n),
            // rótulos abaixo dos nós (exceto o atual, que usa o aside)
            for (final n in data.nodes)
              if (!(n.type == NodeType.medal && n.state == NodeState.current))
                _positionedLabel(context, n),
            // aside do nó atual (nome + "Continuar")
            for (final n in data.nodes)
              if (n.type == NodeType.medal && n.state == NodeState.current)
                _positionedAside(context, n),
            // esmaecido do topo
            Positioned(
              left: 0, right: 0, top: 0, height: 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c.bg, c.bg.withValues(alpha: 0)],
                      stops: const [0.3, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionedPin(MapNode n) {
    final s = MapPin.discSize(n);
    return Positioned(
      left: n.x - s.width / 2,
      top: n.y - s.height / 2,
      child: MapPin(node: n),
    );
  }

  Widget _positionedLabel(BuildContext context, MapNode n) {
    if (n.label == null && n.sub == null) return const SizedBox.shrink();
    final s = MapPin.discSize(n);
    final gap = switch (n.type) {
      NodeType.medal => 11.0,
      NodeType.gate => 9.0,
      NodeType.start => 6.0,
      NodeType.comum => 7.0,
    };
    return Positioned(
      left: n.x - 85,
      top: n.y + s.height / 2 + gap,
      width: 170,
      child: Center(child: _Label(node: n)),
    );
  }

  Widget _positionedAside(BuildContext context, MapNode n) {
    final s = MapPin.discSize(n);
    return Positioned(
      left: n.x - s.width / 2 - 11 - 170,
      top: n.y - 30,
      width: 170,
      child: _CurrentAside(node: n, onContinue: onContinue),
    );
  }
}

/// Rótulo abaixo do nó (nome + micro-status).
class _Label extends StatelessWidget {
  const _Label({required this.node});
  final MapNode node;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isMedal = node.type == NodeType.medal;
    final pn = node.label;
    final sub = node.sub;
    final subColor = node.next
        ? c.accentStrong
        : (isMedal && node.state == NodeState.done ? c.goal : c.muted);
    final showLock = (node.type == NodeType.gate ||
            (isMedal && node.state == NodeState.locked)) &&
        sub != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pn != null)
          Text(pn,
              textAlign: TextAlign.center,
              style: AppType.fredoka(
                  size: isMedal ? 15 : 13,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: 1.05)),
        if (sub != null) ...[
          if (pn != null) const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLock) ...[
                Icon(AppIcons.lock, size: 10, color: subColor),
                const SizedBox(width: 4),
              ] else if (node.next) ...[
                Icon(AppIcons.pin, size: 10, color: subColor),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(sub.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppType.nunito(
                        size: 9.5,
                        weight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: subColor)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Lateral do nó atual: nome em azul + botão "Continuar" chunky.
class _CurrentAside extends StatelessWidget {
  const _CurrentAside({required this.node, this.onContinue});
  final MapNode node;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = TrilhaTones.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (node.label != null)
          Text(node.label!,
              style: AppType.fredoka(
                  size: 17, weight: FontWeight.w600, color: c.primary)),
        const SizedBox(height: 9),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onContinue,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: t.primaryDeep, offset: const Offset(0, 5)),
                  BoxShadow(color: t.contactStrong, blurRadius: 20, offset: const Offset(0, 13), spreadRadius: -8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.play, size: 18, color: c.onPrimary),
                  const SizedBox(width: 7),
                  Text('Continuar',
                      style: AppType.fredoka(
                          size: 15, weight: FontWeight.w600, color: c.onPrimary)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Faixa de fronteira (passagem de país) — a única linha que sobrou.
class _Frontier extends StatelessWidget {
  const _Frontier({required this.label, required this.tones});
  final String label;
  final TrilhaTones tones;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _DashedLine(tones.frontierLine)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.line, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.pin, size: 10, color: c.muted),
              const SizedBox(width: 5),
              Text(label.toUpperCase(),
                  style: AppType.mono(
                      size: 9,
                      weight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: c.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== PAINTERS =====================

class _DashedLine extends CustomPainter {
  _DashedLine(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0, gap = 6.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.color != color;
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.nodes, this.t);
  final List<MapNode> nodes;
  final TrilhaTones t;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _mapW, sy = size.height / _mapH;
    // pontos de baixo para cima (gate desce 50px, como no design)
    final pts = nodes.reversed.map((n) {
      final cy = n.type == NodeType.gate ? n.y + 50 : n.y;
      return Offset(n.x * sx, cy * sy);
    }).toList();
    final curIdx = nodes.reversed.toList().indexWhere((n) => n.state == NodeState.current);
    final traveled = pts.sublist(0, curIdx + 1);
    final future = pts.sublist(curIdx);

    final all = _curve(pts), fut = _curve(future), trav = _curve(traveled);

    void stroke(Path path, Color color, double w, {double dy = 0, double opacity = 1}) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: color.a * opacity)
        ..strokeWidth = w;
      canvas.save();
      canvas.translate(0, dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    stroke(all, t.contact, 22, dy: 9, opacity: 0.45);
    stroke(fut, t.pathGrooveHi, 17, dy: 4);
    stroke(fut, t.pathGrooveDark, 17);
    stroke(fut, t.pathGroove, 9.5);
    stroke(trav, t.pathGreenDark, 19, dy: 7);
    stroke(trav, t.pathGreen, 16);
    stroke(trav, t.pathGreenHi, 5, dy: -3, opacity: 0.75);
  }

  Path _curve(List<Offset> pts) {
    final path = Path();
    if (pts.length < 2) return path;
    path.moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final my = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, my, b.dx, my, b.dx, b.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.nodes != nodes;
}

class _TexturePainter extends CustomPainter {
  _TexturePainter(this.t);
  final TrilhaTones t;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _mapW, sy = size.height / _mapH;
    canvas.save();
    canvas.scale(sx, sy);

    // contornos topográficos
    const List<List<double>> blobs = [
      [60, 430, 90, 46], [260, 470, 68, 38], [280, 200, 84, 44],
      [60, 140, 72, 38], [180, 360, 108, 52],
    ];
    for (final b in blobs) {
      for (var k = 0; k < 3; k++) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = k == 0 ? t.topo2 : t.topo;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(b[0], b[1]),
            width: (b[2] - k * 11) * 2,
            height: (b[3] - k * 7) * 2,
          ),
          paint,
        );
      }
    }

    // rota pontilhada
    final route = Path()
      ..moveTo(300, _mapH - 30)
      ..cubicTo(200, _mapH - 130, 320, _mapH * 0.55, 200, _mapH * 0.45)
      ..cubicTo(120, _mapH * 0.36, 70, 200, 110, 60);
    _dashPath(canvas, route, t.topo2);

    // pontos espalhados
    final dotPaint = Paint()..color = t.topo2.withValues(alpha: t.topo2.a * 0.4);
    for (final p in const <List<double>>[
      [40, 300], [315, 290], [300, 400], [50, 200], [40, 510], [280, 510]
    ]) {
      canvas.drawCircle(Offset(p[0], p[1]), 1.6, dotPaint);
    }

    // bússola
    _compass(canvas, const Offset(290, 70), 13, t.topo2);

    canvas.restore();
  }

  void _dashPath(Canvas canvas, Path path, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 1.5), paint);
        d += 9.5;
      }
    }
  }

  void _compass(Canvas canvas, Offset o, double r, Color color) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;
    canvas.drawCircle(o, r, stroke);
    canvas.drawCircle(o, 2.6, stroke);
    final fill = Paint()..color = color.withValues(alpha: color.a * 0.7);
    for (var i = 0; i < 4; i++) {
      final ang = i * pi / 2 - pi / 2;
      final tip = o + Offset(cos(ang) * r, sin(ang) * r);
      final mid = o + Offset(cos(ang) * 4, sin(ang) * 4);
      final l = o + Offset(cos(ang + 0.4) * 4, sin(ang + 0.4) * 4);
      final rr = o + Offset(cos(ang - 0.4) * 4, sin(ang - 0.4) * 4);
      final p = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(l.dx, l.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(rr.dx, rr.dy)
        ..close();
      canvas.drawPath(p, fill);
    }
  }

  @override
  bool shouldRepaint(_TexturePainter old) => false;
}
