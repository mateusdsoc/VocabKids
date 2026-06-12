import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';
import 'highlighted_text.dart';

/// Card de descoberta: herói com a palavra nova, e o corpo com definição
/// conversacional e exemplo destacado. Sem áudio de pronúncia — TTS ficou
/// fora do MVP (decisão do dono, 11/06; ver `design/notas-implementacao.md`).
class DiscoveryCard extends StatelessWidget {
  const DiscoveryCard({super.key, required this.card});

  final SessionDiscovery card;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Hero(card: card),
        const SizedBox(height: 14),
        // Corpo: definição + exemplo.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
          decoration: BoxDecoration(
            color: c.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.definition,
                  style: AppType.nunito(
                      size: 16, weight: FontWeight.w600, color: c.ink, height: 1.5)),
              const SizedBox(height: 15),
              _Example(card: card),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.card});

  final SessionDiscovery card;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 19, 18, 20),
        decoration: BoxDecoration(color: c.primary),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Círculos decorativos translúcidos.
            Positioned(
              right: -46,
              top: -46,
              child: _circle(150, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              right: 24,
              bottom: -40,
              child: _circle(90, Colors.white.withValues(alpha: 0.08)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Tag(),
                const SizedBox(height: 12),
                Text(card.word,
                    style: AppType.fredoka(
                        size: 42, color: Colors.white, height: 0.95)),
                const SizedBox(height: 8),
                Text(card.partOfSpeech,
                    style: AppType.nunito(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.82))
                        .copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _Tag extends StatelessWidget {
  const _Tag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.novaPalavra, size: 12, color: Colors.white),
          const SizedBox(width: 7),
          Text('PALAVRA NOVA',
              style: AppType.mono(
                  size: 9.5, weight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

class _Example extends StatelessWidget {
  const _Example({required this.card});
  final SessionDiscovery card;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.accent.withValues(alpha: 0.13), c.paper),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(AppIcons.quote, size: 12, color: c.accentStrong),
              const SizedBox(width: 6),
              Text('EXEMPLO',
                  style: AppType.mono(
                      size: 9.5, weight: FontWeight.w700, color: c.muted)),
            ],
          ),
          const SizedBox(height: 7),
          HighlightedText(
            text: card.example,
            baseStyle: AppType.nunito(
                size: 14.5, weight: FontWeight.w600, color: c.ink, height: 1.5),
            token: card.exampleHighlight,
            tokenStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: c.accentStrong,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: c.accentStrong.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
