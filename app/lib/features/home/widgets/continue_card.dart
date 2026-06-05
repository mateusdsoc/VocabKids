import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/surface_card.dart';
import '../home_data.dart';

/// CTA dominante da Home — retoma a próxima lição a um toque. Arte do destino
/// estendida à esquerda (com a bandeira do país), cidade no alto, status da
/// lição abaixo e botão de play à direita.
class ContinueCard extends StatelessWidget {
  const ContinueCard({super.key, required this.lesson, this.onTap});

  /// `null` quando a trilha foi concluída (modo livre).
  final ContinueLesson? lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = lesson;
    return SurfaceCard(
      radius: 22,
      padding: EdgeInsets.zero,
      clip: true,
      onTap: onTap,
      shadow: [
        BoxShadow(
          color: const Color(0x80281E0A),
          blurRadius: 26,
          offset: const Offset(0, 14),
          spreadRadius: -16,
        ),
      ],
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 112,
              child: _Art(asset: l?.imageAsset, country: l?.country ?? 'Brasil'),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: l == null
                    ? _ModoLivre(color: c)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.fredoka(
                                size: 20, color: c.ink, height: 1.04),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: ProgressBar(
                                  value: l.fraction,
                                  color: c.primary,
                                  height: 6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Lição ${l.lessonIndex} de ${l.lessonTotal}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.nunito(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: c.muted),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PlayButton(color: c),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.asset, required this.country});

  final String? asset;
  final String country;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (asset != null)
          Image.asset(asset!, fit: BoxFit.cover)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, c.accent],
              ),
            ),
          ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.pin, size: 11, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  country,
                  style: AppType.nunito(
                      size: 10, weight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.color});
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.primary,
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(AppIcons.play, size: 20, color: color.onPrimary),
      ),
    );
  }
}

class _ModoLivre extends StatelessWidget {
  const _ModoLivre({required this.color});
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modo livre',
            style: AppType.fredoka(size: 20, color: color.ink, height: 1.04)),
        const SizedBox(height: 11),
        Row(
          children: [
            Flexible(
              child: Text(
                'Continue praticando',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.nunito(
                    size: 11, weight: FontWeight.w800, color: color.muted),
              ),
            ),
            const SizedBox(width: 8),
            _PlayButton(color: color),
          ],
        ),
      ],
    );
  }
}
