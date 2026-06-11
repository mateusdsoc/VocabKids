import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/confetti_burst.dart';
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
                const Positioned.fill(child: ConfettiBurst()),
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

// O burst de confete foi extraído para `core/widgets/confetti_burst.dart`
// (compartilhado com a chegada ao nó da Trilha).
