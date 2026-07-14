import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models.dart';
import 'highlighted_text.dart';

/// Painel do enunciado: cartão com gradiente sutil (azul→dourado) e selos de
/// viagem ao fundo. Destaca a palavra marcada (azul-negrito) ou a lacuna
/// "_____" das questões de completar.
class QuestionPanel extends StatelessWidget {
  const QuestionPanel({super.key, required this.question});

  final SessionQuestion question;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stemStyle =
        AppType.fredoka(size: 20, weight: FontWeight.w500, color: c.ink, height: 1.32);

    final Widget stem;
    if (question.blank) {
      stem = HighlightedText(
        text: question.stem,
        baseStyle: stemStyle,
        token: '_____',
        tokenStyle: TextStyle(
            color: c.primary, fontWeight: FontWeight.w800, letterSpacing: 1),
      );
    } else if (question.highlightWord != null) {
      // Palavra-alvo do enunciado: só cor (azul-negrito). Sozinha não precisa
      // de sublinhado — a cor já a destaca (decisão do dono, 14/07).
      stem = HighlightedText(
        text: question.stem,
        baseStyle: stemStyle,
        token: question.highlightWord!,
        tokenStyle: TextStyle(
          color: c.primary,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      stem = Text(question.stem, style: stemStyle);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(c.primary.withValues(alpha: 0.16), c.paper),
              Color.alphaBlend(c.accent.withValues(alpha: 0.13), c.paper),
            ],
          ),
          border: Border.all(
              color: c.primary.withValues(alpha: 0.22), width: 1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Selos de viagem decorativos (cantos translúcidos).
            Positioned(
              right: -20,
              top: -20,
              child: _stampCircle(84, c.primary.withValues(alpha: 0.30)),
            ),
            Positioned(
              right: 14,
              top: 30,
              child: _stampCircle(40, c.accentStrong.withValues(alpha: 0.28)),
            ),
            stem,
          ],
        ),
      ),
    );
  }

  Widget _stampCircle(double size, Color color) => Opacity(
        opacity: 0.5,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: size > 60 ? 3 : 2),
          ),
        ),
      );
}
