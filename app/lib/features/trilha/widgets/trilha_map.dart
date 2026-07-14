import 'dart:math' show pi, cos, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/confetti_burst.dart';
import '../models.dart';
import 'map_pins.dart';
import 'trilha_tones.dart';

/// Espaço lógico do mapa (igual ao design): 340 de largura; a ALTURA vem de
/// [TrilhaMapData.mapHeight] (540 no template do demo; no mapa contínuo,
/// cresce com a trilha). As coordenadas dos nós vivem nesse espaço; o widget
/// escala as POSIÇÕES proporcionalmente à largura disponível (pins/rótulos
/// mantêm o tamanho intrínseco) — em vez de um canvas fixo que recorta em
/// telas estreitas.
const double _mapW = 340;

/// Altura de referência da textura cartográfica do fundo (tela cheia).
const double _texH = 540;

/// O mapa da Trilha: banhos de cor por país, textura cartográfica, o caminho
/// sinuoso (percorrido vivo + futuro rebaixado), a fronteira única e os nós.
///
/// [chegada] (opcional) toca a animação de **completar nó** (produto 3.7):
/// 0→1, o último trecho verde se desenha com um marcador na ponta, o pin do
/// nó atual pipoca na chegada (confete + aside em fade) e tudo **assenta
/// estático** — decisão do dono (11/06): sem bob/flutuação contínua. `null`
/// = mapa estático (custo zero de animação).
class TrilhaMap extends StatelessWidget {
  const TrilhaMap({super.key, required this.data, this.onContinue, this.chegada});

  final TrilhaMapData data;
  final VoidCallback? onContinue;
  final Animation<double>? chegada;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = TrilhaTones.of(context);

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth.isFinite ? box.maxWidth : _mapW;
      final k = w / _mapW; // escala uniforme: posições acompanham a largura
      final h = data.mapHeight * k;

      return ClipRect(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // caminho (repinta sozinho durante a chegada, via repaint)
              Positioned.fill(
                  child: CustomPaint(
                      painter: _PathPainter(data.nodes, t,
                          mapH: data.mapHeight,
                          chegada: chegada,
                          markerColor: c.primary))),
              // fronteiras — uma faixa por passagem de país
              for (final f in data.frontiers)
                Positioned(
                  left: 14, right: 14, top: f.y * k - 11,
                  child: _Frontier(label: f.label, tones: t),
                ),
              // nós
              for (final n in data.nodes) _positionedPin(n, k),
              // rótulos abaixo dos nós (exceto o atual, que usa o aside)
              for (final n in data.nodes)
                if (!n.cta) _positionedLabel(context, n, k, w),
              // aside do nó atual (nome + "Continuar") — pelo flag `cta`,
              // porque com dados reais o nó atual pode ser comum, não medal.
              for (final n in data.nodes)
                if (n.cta) _positionedAside(context, n, k, w),
              // confete da chegada, sobre o nó atual (monta no pop, 1×)
              if (chegada != null) _confettiChegada(k),
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
    });
  }

  Widget _positionedPin(MapNode n, double k) {
    final s = MapPin.discSize(n);
    Widget pin = MapPin(node: n);
    final cheg = chegada;
    // Chegada: o pin do nó atual fica oculto enquanto o marcador viaja e
    // pipoca (overshoot) quando o trecho termina de se desenhar.
    if (cheg != null && n.state == NodeState.current) {
      pin = AnimatedBuilder(
        animation: cheg,
        builder: (context, child) {
          final scale = const Interval(0.55, 0.85, curve: Curves.easeOutBack)
              .transform(cheg.value);
          if (scale <= 0) return SizedBox(width: s.width, height: s.height);
          return Transform.scale(scale: scale, child: child);
        },
        child: pin,
      );
    }
    return Positioned(
      left: n.x * k - s.width / 2,
      top: n.y * k - s.height / 2,
      child: pin,
    );
  }

  /// Confete centrado no nó atual; só entra na árvore quando o pin pipoca
  /// (o [ConfettiBurst] roda uma vez ao montar).
  Widget _confettiChegada(double k) {
    final atual = data.nodes.where((n) => n.state == NodeState.current);
    if (atual.isEmpty) return const SizedBox.shrink();
    final n = atual.first;
    return AnimatedBuilder(
      animation: chegada!,
      builder: (context, _) {
        if (chegada!.value < 0.55) return const SizedBox.shrink();
        return Positioned(
          left: n.x * k - 75,
          top: n.y * k - 75,
          width: 150,
          height: 150,
          child: const ConfettiBurst(),
        );
      },
    );
  }

  Widget _positionedLabel(BuildContext context, MapNode n, double k, double w) {
    if (n.label == null && n.sub == null) return const SizedBox.shrink();
    final s = MapPin.discSize(n);
    final gap = switch (n.type) {
      NodeType.medal => 11.0,
      NodeType.gate => 9.0,
      NodeType.start => 6.0,
      NodeType.comum => 7.0,
    };
    // Clampa o rótulo dentro do canvas (nós de borda em telas estreitas).
    final left = (n.x * k - 85).clamp(2.0, w - 172.0);
    return Positioned(
      left: left,
      top: n.y * k + s.height / 2 + gap,
      width: 170,
      child: Center(child: _Label(node: n)),
    );
  }

  Widget _positionedAside(BuildContext context, MapNode n, double k, double w) {
    final s = MapPin.discSize(n);
    // O aside fica do lado com mais espaço (nós à esquerda do template
    // jogam o aside para a direita); encolhe em vez de sair da tela.
    final roomLeft = n.x * k - s.width / 2 - 11;
    final roomRight = w - n.x * k - s.width / 2 - 11;
    final aDireita = roomRight > roomLeft;
    final room = (aDireita ? roomRight : roomLeft).clamp(0.0, double.infinity);
    final width = room.clamp(0.0, 170.0);
    Widget aside =
        _CurrentAside(node: n, onContinue: onContinue, aDireita: aDireita);
    final cheg = chegada;
    if (cheg != null) {
      // Entra em fade depois do pop do pin. Segue tocável desde já
      // (só a opacidade anima — princípio 3.7, não-bloqueante).
      aside = AnimatedBuilder(
        animation: cheg,
        builder: (context, child) {
          final f = const Interval(0.62, 0.95, curve: Curves.easeOutCubic)
              .transform(cheg.value);
          return Opacity(
            opacity: f,
            child: Transform.translate(
                offset: Offset(0, 8 * (1 - f)), child: child),
          );
        },
        child: aside,
      );
    }
    return Positioned(
      left: aDireita ? n.x * k + s.width / 2 + 11 : roomLeft - width,
      top: n.y * k - 30,
      width: width,
      child: aside,
    );
  }
}

/// Fundo da Trilha que cobre **a tela toda**: banhos de cor (frio em cima,
/// quente embaixo) e a textura cartográfica. Separado do [TrilhaMap] para que
/// os nós (espaço lógico 340×540) fiquem centralizados por cima de um fundo
/// contínuo, sem o retângulo recortado.
class TrilhaBackdrop extends StatelessWidget {
  const TrilhaBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TrilhaTones.of(context);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // banho frio (topo)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.85),
                radius: 1.1,
                colors: [t.washCool, t.washCool.withValues(alpha: 0)],
                stops: const [0, 0.8],
              ),
            ),
          ),
          // banho quente (base)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.55),
                radius: 1.0,
                colors: [t.washWarm, t.washWarm.withValues(alpha: 0)],
                stops: const [0, 0.78],
              ),
            ),
          ),
          // textura cartográfica (escala para preencher a tela)
          CustomPaint(painter: _TexturePainter(t)),
        ],
      ),
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
/// [aDireita] espelha o alinhamento quando o aside fica à direita do pin.
class _CurrentAside extends StatelessWidget {
  const _CurrentAside({required this.node, this.onContinue, this.aDireita = false});
  final MapNode node;
  final VoidCallback? onContinue;
  final bool aDireita;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = TrilhaTones.of(context);
    return Column(
      crossAxisAlignment:
          aDireita ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
  _PathPainter(this.nodes, this.t,
      {required this.mapH, this.chegada, required this.markerColor})
      : super(repaint: chegada);
  final List<MapNode> nodes;
  final TrilhaTones t;
  final double mapH;

  /// Animação da chegada (completar nó); `null` = mapa estático.
  final Animation<double>? chegada;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _mapW, sy = size.height / mapH;
    // pontos de baixo para cima (gate desce 50px, como no design)
    final pts = nodes.reversed.map((n) {
      final cy = n.type == NodeType.gate ? n.y + 50 : n.y;
      return Offset(n.x * sx, cy * sy);
    }).toList();
    // Corte percorrido/futuro: no nó atual; sem um (janela de destino já
    // concluído ou ainda bloqueado), no último concluído a partir da base.
    final rev = nodes.reversed.toList();
    var curIdx = rev.indexWhere((n) => n.state == NodeState.current);
    if (curIdx == -1) {
      curIdx = rev.lastIndexWhere((n) => n.state == NodeState.done);
    }
    final traveled = curIdx >= 0 ? pts.sublist(0, curIdx + 1) : <Offset>[];
    final future = pts.sublist(curIdx >= 0 ? curIdx : 0);

    final all = _curve(pts), fut = _curve(future);
    var trav = _curve(traveled);

    // Chegada: o último trecho do percorrido se desenha (extractPath) com um
    // marcador na ponta; o resto do percorrido já aparece completo.
    Offset? marker;
    final v = chegada?.value;
    if (v != null && traveled.length >= 2) {
      final pathT = const Interval(0.0, 0.55, curve: Curves.easeInOutCubic)
          .transform(v);
      if (pathT < 1) {
        final metrics = trav.computeMetrics().toList();
        if (metrics.isNotEmpty) {
          final m = metrics.first;
          final lastLen = _lastSegmentLength(traveled);
          final visible =
              (m.length - lastLen * (1 - pathT)).clamp(0.0, m.length);
          trav = m.extractPath(0, visible);
          marker = m.getTangentForOffset(visible)?.position;
        }
      }
    }

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

    // Marcador que viaja na ponta do trecho (sombra de contato + anel branco).
    if (marker != null) {
      canvas.drawCircle(
          marker + const Offset(0, 3), 8, Paint()..color = t.contact);
      canvas.drawCircle(marker, 9, Paint()..color = Colors.white);
      canvas.drawCircle(marker, 6.5, Paint()..color = markerColor);
    }
  }

  /// Comprimento do trecho final (do último nó concluído até o atual).
  double _lastSegmentLength(List<Offset> traveled) {
    final seg = _curve([traveled[traveled.length - 2], traveled.last]);
    final ms = seg.computeMetrics().toList();
    return ms.isEmpty ? 0 : ms.first.length;
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
  bool shouldRepaint(_PathPainter old) =>
      old.nodes != nodes || old.chegada != chegada || old.mapH != mapH;
}

class _TexturePainter extends CustomPainter {
  _TexturePainter(this.t);
  final TrilhaTones t;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _mapW, sy = size.height / _texH;
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
      ..moveTo(300, _texH - 30)
      ..cubicTo(200, _texH - 130, 320, _texH * 0.55, 200, _texH * 0.45)
      ..cubicTo(120, _texH * 0.36, 70, 200, 110, 60);
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
