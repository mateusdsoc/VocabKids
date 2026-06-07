import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart' show kGlassBlur;
import '../models.dart';

/// Card-herói do XP (vidro no claro): número grande, chip de combo e a barra de
/// nível com o **ganho** desta sessão destacado.
class XpSummaryCard extends StatelessWidget {
  const XpSummaryCard({super.key, required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glass = c.glass.a < 1.0;
    final radius = BorderRadius.circular(20);

    Widget inner = Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: radius,
        border: Border.all(color: c.line, width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // brilho decorativo no canto
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.primary.withValues(alpha: 0.18),
                    c.primary.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.7],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text('+${summary.xpGained} XP',
                        style: AppType.fredoka(
                            size: 36,
                            weight: FontWeight.w700,
                            color: c.primary,
                            height: 0.92)),
                  ),
                  if (summary.combo != null) ...[
                    const SizedBox(width: 8),
                    _ComboChip(value: summary.combo!),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Nível ${summary.level}',
                      style: AppType.fredoka(
                          size: 14, weight: FontWeight.w500, color: c.ink)),
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      style: AppType.mono(
                          size: 11, weight: FontWeight.w700, color: c.muted),
                      children: [
                        TextSpan(text: '${milhar(summary.xpFrom)} '),
                        TextSpan(
                            text: '→ ${milhar(summary.xpTo)}',
                            style: TextStyle(color: c.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _XpTrack(
                  base: summary.baseFraction, gain: summary.gainFraction),
            ],
          ),
        ],
      ),
    );

    if (glass) {
      inner = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
          child: inner,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0x80281E0A),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -22,
          ),
        ],
      ),
      child: inner,
    );
  }
}

class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.value});
  final int value;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.accent.withValues(alpha: 0.22), c.paper),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: c.accentStrong.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.combo, size: 14, color: c.accentStrong),
          const SizedBox(width: 5),
          Text('combo ×$value',
              style: AppType.fredoka(
                  size: 13, weight: FontWeight.w600, color: c.accentInk)),
        ],
      ),
    );
  }
}

/// Barra de nível: trecho-base (já tinha) em azul apagado e o **ganho** desta
/// sessão num degradê vivo.
class _XpTrack extends StatelessWidget {
  const _XpTrack({required this.base, required this.gain});
  final double base;
  final double gain;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 9,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.track)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: gain.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    c.primary,
                    Color.lerp(c.primary, Colors.white, 0.38)!,
                  ]),
                ),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: base.clamp(0.0, 1.0),
              child: ColoredBox(
                  color: Color.alphaBlend(
                      c.primary.withValues(alpha: 0.32), c.track)),
            ),
          ],
        ),
      ),
    );
  }
}
