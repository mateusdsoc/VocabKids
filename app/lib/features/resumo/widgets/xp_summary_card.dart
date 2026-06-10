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
///
/// Anima uma vez ao entrar (sequência curta, não-bloqueante): o número-herói
/// **conta de 0 até o XP ganho**, depois a barra de nível **enche** do ponto
/// onde estava até o novo XP (com o contador 3.120 → 3.600 acompanhando) e o
/// chip de combo pipoca no final. Os valores são os do resumo recebido — a
/// tela só apresenta, nunca calcula (cliente fino).
class XpSummaryCard extends StatefulWidget {
  const XpSummaryCard({super.key, required this.summary});

  final SessionSummary summary;

  @override
  State<XpSummaryCard> createState() => _XpSummaryCardState();
}

class _XpSummaryCardState extends State<XpSummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  /// Count-up do número-herói (+0 → +480 XP).
  late final Animation<double> _count = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.60, curve: Curves.easeOutCubic));

  /// Encher da barra de nível (e contador xpFrom → xpTo junto).
  late final Animation<double> _bar = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic));

  /// Pop do chip de combo, no fim da sequência.
  late final Animation<double> _chip = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.85, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final summary = widget.summary;
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
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final xpShown = (summary.xpGained * _count.value).round();
              final xpToShown = (summary.xpFrom +
                      (summary.xpTo - summary.xpFrom) * _bar.value)
                  .round();
              final gainShown = summary.baseFraction +
                  (summary.gainFraction - summary.baseFraction) * _bar.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text('+$xpShown XP',
                            style: AppType.fredoka(
                                size: 36,
                                weight: FontWeight.w700,
                                color: c.primary,
                                height: 0.92)),
                      ),
                      if (summary.combo != null) ...[
                        const SizedBox(width: 8),
                        Opacity(
                          opacity: _chip.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * _chip.value,
                            child: _ComboChip(value: summary.combo!),
                          ),
                        ),
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
                              size: 14,
                              weight: FontWeight.w500,
                              color: c.ink)),
                      const Spacer(),
                      Text.rich(
                        TextSpan(
                          style: AppType.mono(
                              size: 11,
                              weight: FontWeight.w700,
                              color: c.muted),
                          children: [
                            TextSpan(text: '${milhar(summary.xpFrom)} '),
                            TextSpan(
                                text: '→ ${milhar(xpToShown)}',
                                style: TextStyle(color: c.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _XpTrack(base: summary.baseFraction, gain: gainShown),
                ],
              );
            },
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
/// sessão num degradê vivo (o pai anima [gain] da base até o valor final).
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
