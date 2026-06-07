import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';
import 'trilha_tones.dart';

/// Desenha o **disco** de um nó (sem o rótulo — esse é posicionado pelo mapa).
/// Profundidade por gradiente + sombras em camadas + "aba inferior" (a parede do
/// relevo), tudo barato de portar. Cada tipo×estado é uma variante reutilizável.
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.node});

  final MapNode node;

  /// Tamanho do disco por tipo×estado — o mapa usa para ancorar o centro em (x,y).
  static Size discSize(MapNode n) {
    switch (n.type) {
      case NodeType.comum:
        return n.state == NodeState.current
            ? const Size(34, 34)
            : const Size(30, 30);
      case NodeType.medal:
        switch (n.state) {
          case NodeState.current:
            return const Size(82, 82);
          case NodeState.done:
            return const Size(78, 78);
          case NodeState.locked:
            return const Size(72, 72);
        }
      case NodeType.gate:
        return const Size(172, 124);
      case NodeType.start:
        return const Size(38, 38);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = TrilhaTones.of(context);
    final paper = Color.alphaBlend(c.paper, c.bg);
    switch (node.type) {
      case NodeType.comum:
        return _comum(c, t, paper);
      case NodeType.medal:
        return _medal(c, t, paper);
      case NodeType.gate:
        return _gate(c, t, paper);
      case NodeType.start:
        return _start(c, t, paper);
    }
  }

  // ---------- COMUM ----------
  Widget _comum(AppColors c, TrilhaTones t, Color paper) {
    switch (node.state) {
      case NodeState.done:
        return Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0, -0.64),
              radius: 0.95,
              colors: [
                Color.lerp(c.goal, Colors.white, 0.42)!,
                c.goal,
                Color.lerp(c.goal, Colors.black, 0.4)!,
              ],
              stops: const [0, 0.6, 1],
            ),
            boxShadow: [
              BoxShadow(color: t.contact, blurRadius: 10, offset: const Offset(0, 7), spreadRadius: -3),
              BoxShadow(color: Color.lerp(c.goal, Colors.black, 0.5)!, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(AppIcons.check, size: 14, color: Colors.white.withValues(alpha: 0.92)),
        );
      case NodeState.current:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0, -0.64),
              radius: 0.95,
              colors: [Color.lerp(c.primary, Colors.white, 0.4)!, c.primary, t.primaryDeep],
              stops: const [0, 0.6, 1],
            ),
            boxShadow: [
              BoxShadow(color: t.contactStrong, blurRadius: 16, offset: const Offset(0, 12), spreadRadius: -5),
              BoxShadow(color: t.primaryDeep, offset: const Offset(0, 5)),
              BoxShadow(color: c.primary, spreadRadius: 5),
              BoxShadow(color: paper, spreadRadius: 3),
            ],
          ),
        );
      case NodeState.locked:
        return Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0, -0.5),
              colors: [Color.lerp(t.carveFill, Colors.black, 0.25)!, t.carveFill],
            ),
            border: Border.all(color: c.line, width: 1),
          ),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: c.muted.withValues(alpha: 0.5)),
          ),
        );
    }
  }

  // ---------- MEDAL ----------
  Widget _medal(AppColors c, TrilhaTones t, Color paper) {
    switch (node.state) {
      case NodeState.current:
        return SizedBox(
          width: 82,
          height: 82,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: t.contactStrong, blurRadius: 32, offset: const Offset(0, 28), spreadRadius: -8),
                BoxShadow(color: t.medalWallCur, offset: const Offset(0, 10)),
                BoxShadow(color: c.primary, spreadRadius: 7),
                BoxShadow(color: paper, spreadRadius: 4),
              ],
            ),
            child: ClipOval(
              child: Stack(fit: StackFit.expand, children: [
                if (node.art != null)
                  Image.asset(node.art!, fit: BoxFit.cover, alignment: const Alignment(0, 0.2)),
                _gloss(),
              ]),
            ),
          ),
        );
      case NodeState.done:
        return SizedBox(
          width: 78,
          height: 78,
          child: Stack(clipBehavior: Clip.none, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: t.contact, blurRadius: 18, offset: const Offset(0, 14), spreadRadius: -6),
                  BoxShadow(color: t.medalWall, offset: const Offset(0, 7)),
                  BoxShadow(color: c.goal, spreadRadius: 5),
                  BoxShadow(color: paper, spreadRadius: 3),
                ],
              ),
              child: ClipOval(
                child: Stack(fit: StackFit.expand, children: [
                  if (node.art != null)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Transform.scale(
                        scale: 1.14,
                        child: Image.asset(node.art!, fit: BoxFit.cover),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.6),
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          const Color(0x29140E04),
                        ],
                      ),
                    ),
                  ),
                  _gloss(),
                ]),
              ),
            ),
            // selo de check
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.goal,
                  border: Border.all(color: paper, width: 2.5),
                  boxShadow: [BoxShadow(color: t.contact, blurRadius: 9, offset: const Offset(0, 5), spreadRadius: -3)],
                ),
                child: const Icon(AppIcons.check, size: 13, color: Colors.white),
              ),
            ),
            // cantinho de postal (embaçado — reveal só no Passaporte)
            if (node.art != null)
              Positioned(
                top: -9,
                right: -10,
                child: Transform.rotate(
                  angle: 0.23,
                  child: Container(
                    width: 28,
                    height: 21,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: t.contact, blurRadius: 10, offset: const Offset(0, 5), spreadRadius: -3)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                        child: Image.asset(node.art!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        );
      case NodeState.locked:
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(clipBehavior: Clip.none, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.carveFill,
                border: Border.all(color: c.line, width: 1),
                boxShadow: [BoxShadow(color: t.contact, blurRadius: 7, offset: const Offset(0, 3), spreadRadius: -4)],
              ),
              child: ClipOval(
                child: Stack(fit: StackFit.expand, children: [
                  if (node.art != null)
                    Opacity(
                      opacity: 0.65,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(_grayscaleDark),
                        child: Image.asset(node.art!, fit: BoxFit.cover),
                      ),
                    ),
                  Center(
                    child: Icon(_ghostIcon(node.ghost),
                        size: 38, color: t.ghostInk.withValues(alpha: 0.55)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.4),
                        colors: [Colors.transparent, t.carveVeil],
                        stops: const [0.35, 1],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.carveFill,
                  border: Border.all(color: c.bg, width: 2),
                ),
                child: Icon(AppIcons.lock, size: 12, color: c.muted),
              ),
            ),
          ]),
        );
    }
  }

  // ---------- GATE (portão / fronteira) ----------
  Widget _gate(AppColors c, TrilhaTones t, Color paper) {
    final locked = node.state == NodeState.locked;
    const radius = BorderRadius.only(
      topLeft: Radius.circular(86),
      topRight: Radius.circular(86),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );
    return SizedBox(
      width: 172,
      height: 124,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: t.gateFill,
          boxShadow: [
            BoxShadow(color: t.contactStrong, blurRadius: 30, offset: const Offset(0, 24), spreadRadius: -10),
            BoxShadow(color: t.gateWall, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(fit: StackFit.expand, children: [
            if (node.art != null)
              node.state == NodeState.locked
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.matrix(_grayscaleDarker),
                      child: Image.asset(node.art!, fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
                    )
                  : Image.asset(node.art!, fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: locked
                      ? [const Color(0x52081220), const Color(0xB8081220)]
                      : [const Color(0x1A081220), const Color(0x8C081220)],
                ),
              ),
            ),
            Center(
              child: Icon(_ghostIcon(node.ghost),
                  size: 58,
                  color: Colors.white
                      .withValues(alpha: locked ? 0.30 : 0.5)),
            ),
            if (locked)
              Center(
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: const Color(0x80141C2C),
                    boxShadow: [BoxShadow(color: t.contactStrong, blurRadius: 10, offset: const Offset(0, 4), spreadRadius: -2)],
                  ),
                  child: const Icon(AppIcons.lock, size: 20, color: Color(0xFFE9EEFB)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  // ---------- START (bandeira) ----------
  Widget _start(AppColors c, TrilhaTones t, Color paper) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.64),
          colors: [Colors.white, paper, Color.lerp(paper, Colors.black, 0.4)!],
          stops: const [0, 0.6, 1],
        ),
        boxShadow: [
          BoxShadow(color: t.contact, blurRadius: 13, offset: const Offset(0, 9), spreadRadius: -5),
          BoxShadow(color: Color.lerp(paper, Colors.black, 0.4)!, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(Icons.flag_rounded, size: 20, color: c.accentStrong),
    );
  }

  Widget _gloss() => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.25),
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
      );
}

IconData _ghostIcon(Landmark? l) => switch (l) {
      Landmark.eiffel => Icons.cell_tower,
      Landmark.monument => Icons.account_balance,
      Landmark.mountain => Icons.terrain,
      null => Icons.account_balance,
    };

// Cinza + escurecido para arte de nó bloqueado (grayscale .85, brilho ~.42).
const List<double> _grayscaleDark = [
  0.09, 0.30, 0.03, 0, 0, //
  0.09, 0.30, 0.03, 0, 0, //
  0.09, 0.30, 0.03, 0, 0, //
  0, 0, 0, 1, 0,
];
const List<double> _grayscaleDarker = [
  0.10, 0.33, 0.03, 0, 0, //
  0.10, 0.33, 0.03, 0, 0, //
  0.10, 0.33, 0.03, 0, 0, //
  0, 0, 0, 1, 0,
];
