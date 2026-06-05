import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';
import 'highlighted_text.dart';

enum OptionState { neutral, selected, correct, wrong }

/// Alternativa de múltipla escolha (A/B/C/D). Renderiza os quatro estados do
/// design; no acerto, sobrepõe um confete estático.
///
/// NOTA: o confete aqui é **estático** (placeholder fiel ao mockup). A animação
/// fica para depois — ver `design/notas-implementacao.md`.
class OptionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(15);

    final (border, borderW, bg) = switch (state) {
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
          c.warn,
          2.0,
          Color.alphaBlend(c.warn.withValues(alpha: 0.12), c.paper)
        ),
    };

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: radius,
        child: Container(
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
                  _Key(letter: option.key, state: state),
                  const SizedBox(width: 12),
                  Expanded(child: _text(c)),
                  if (state == OptionState.correct ||
                      state == OptionState.wrong) ...[
                    const SizedBox(width: 8),
                    Icon(
                      state == OptionState.correct
                          ? AppIcons.check
                          : AppIcons.retry,
                      size: 21,
                      color: state == OptionState.correct ? c.goal : c.warn,
                    ),
                  ],
                ],
              ),
              if (showConfetti) const Positioned.fill(child: _Confetti()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(AppColors c) {
    final style =
        AppType.nunito(size: 14.5, weight: FontWeight.w700, color: c.ink, height: 1.3);
    if (option.boldWord == null) {
      return Text(option.text, style: style);
    }
    return HighlightedText(
      text: option.text,
      baseStyle: style,
      token: option.boldWord!,
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
      OptionState.wrong => c.warn,
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

/// Confete estático (7 confetes posicionados como no mockup). Placeholder para
/// a animação futura.
class _Confetti extends StatelessWidget {
  const _Confetti();

  // (xFrac, yFrac, cor, círculo?, rotação)
  static const _bits = [
    (0.16, 0.28, Color(0xFF1E7FD6), false, 0.35),
    (0.40, 0.16, Color(0xFFE0A82E), false, -0.26),
    (0.63, 0.24, Color(0xFF16A971), true, 0.0),
    (0.85, 0.20, Color(0xFF1E7FD6), false, 0.70),
    (0.52, 0.64, Color(0xFFE0A82E), true, 0.0),
    (0.26, 0.66, Color(0xFF16A971), false, 0.44),
    (0.76, 0.60, Color(0xFFE0A82E), false, -0.35),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              for (final (x, y, color, round, rot) in _bits)
                Positioned(
                  left: x * w,
                  top: y * h,
                  child: Transform.rotate(
                    angle: rot,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.9),
                        borderRadius:
                            BorderRadius.circular(round ? 3.5 : 2),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
