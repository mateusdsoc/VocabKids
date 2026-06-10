import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';
import 'highlighted_text.dart';

enum OptionState { neutral, selected, correct, wrong }

/// Alternativa de múltipla escolha (A/B/C/D). Renderiza os quatro estados do
/// design, com borda em transição suave ao responder e o ícone de check/X
/// "pipocando". No acerto dispara um **burst curto de confete** (uma vez,
/// não-bloqueante); no erro, um **shake gentil** de amplitude pequena —
/// feedback claro sem tom punitivo (produto 3.4).
class OptionTile extends StatefulWidget {
  const OptionTile({
    super.key,
    required this.option,
    required this.state,
    this.onTap,
    this.showConfetti = false,
  });

  final QuestionOption option;
  final OptionState state;
  final VoidCallback? onTap;
  final bool showConfetti;

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didUpdateWidget(OptionTile old) {
    super.didUpdateWidget(old);
    if (widget.state == OptionState.wrong && old.state != OptionState.wrong) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(15);

    final (border, borderW, bg) = switch (widget.state) {
      OptionState.neutral => (c.line, 1.5, c.paper),
      OptionState.selected => (
          c.primary,
          2.0,
          Color.alphaBlend(c.primary.withValues(alpha: 0.08), c.paper)
        ),
      OptionState.correct => (
          c.goal,
          2.0,
          Color.alphaBlend(c.goal.withValues(alpha: 0.12), c.paper)
        ),
      OptionState.wrong => (
          c.error,
          2.0,
          Color.alphaBlend(c.error.withValues(alpha: 0.12), c.paper)
        ),
    };

    final tile = Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: border, width: borderW),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _Key(letter: widget.option.key, state: widget.state),
                  const SizedBox(width: 12),
                  Expanded(child: _text(c)),
                  if (widget.state == OptionState.correct ||
                      widget.state == OptionState.wrong) ...[
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Icon(
                        widget.state == OptionState.correct
                            ? AppIcons.check
                            : AppIcons.wrong,
                        size: 21,
                        color: widget.state == OptionState.correct
                            ? c.goal
                            : c.error,
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.showConfetti)
                const Positioned.fill(child: _ConfettiBurst()),
            ],
          ),
        ),
      ),
    );

    // Shake do erro: senoide amortecida de amplitude pequena (~4 px).
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx =
            t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi * 4) * 4 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: tile,
    );
  }

  Widget _text(AppColors c) {
    final style = AppType.nunito(
        size: 14.5, weight: FontWeight.w700, color: c.ink, height: 1.3);
    if (widget.option.boldWord == null) {
      return Text(widget.option.text, style: style);
    }
    return HighlightedText(
      text: widget.option.text,
      baseStyle: style,
      token: widget.option.boldWord!,
      tokenStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.letter, required this.state});

  final String letter;
  final OptionState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final flat = switch (state) {
      OptionState.correct => c.goal,
      OptionState.wrong => c.error,
      _ => null,
    };

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: flat,
        gradient: flat == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, Color.lerp(c.primary, Colors.white, 0.3)!],
              )
            : null,
        boxShadow: flat == null
            ? [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.5),
                  blurRadius: 9,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Text(letter,
          style: AppType.fredoka(
              size: 14, weight: FontWeight.w600, color: c.onPrimary)),
    );
  }
}

/// Burst de confete do acerto: roda **uma vez** (~800 ms) e desvanece. Nunca
/// bloqueia o avanço (IgnorePointer + o CTA segue ativo). Cores dos tokens
/// (primária / ouro / sucesso), nunca hardcoded.
class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst();

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
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
            colors: [c.primary, c.accent, c.goal],
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
