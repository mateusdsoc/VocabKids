import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';

/// Teaser dourado do colecionável recém-desbloqueado (frame "com conquista").
/// É um painel **sólido** (não é vidro) — comemora o item novo no Passaporte.
/// [onVerPassaporte] abre o Modo Conquista (o reveal); `null` desativa o CTA.
class AchievementCard extends StatelessWidget {
  const AchievementCard({super.key, required this.ach, this.onVerPassaporte});

  final SummaryAchievement ach;
  final VoidCallback? onVerPassaporte;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final smallColor = dark ? const Color(0xFFCAA23A) : const Color(0xFF7A6024);
    final ctaInk = dark ? const Color(0xFF23200F) : const Color(0xFF3A2A00);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(c.accent.withValues(alpha: 0.26), c.paper),
            Color.alphaBlend(c.accent.withValues(alpha: 0.12), c.paper),
          ],
        ),
        border:
            Border.all(color: c.accentStrong.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Postcard(asset: ach.imageAsset),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ach.kicker.toUpperCase(),
                        style: AppType.mono(
                            size: 9,
                            weight: FontWeight.w700,
                            letterSpacing: 1.26,
                            color: c.accentStrong)),
                    const SizedBox(height: 2),
                    Text(ach.title,
                        style: AppType.fredoka(
                            size: 17, color: c.ink, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(ach.subtitle,
                        style: AppType.nunito(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: smallColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _GoldButton(
            label: 'Ver no Passaporte',
            icon: AppIcons.passaporte,
            ink: ctaInk,
            onTap: onVerPassaporte,
          ),
        ],
      ),
    );
  }
}

class _Postcard extends StatelessWidget {
  const _Postcard({this.asset});
  final String? asset;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Transform.rotate(
      angle: -0.07,
      child: SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: c.muted,
                image: asset != null
                    ? DecorationImage(
                        image: AssetImage(asset!), fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  const BoxShadow(
                      color: Color(0x80281E0A),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                      spreadRadius: -6),
                  BoxShadow(
                      color: c.accentStrong.withValues(alpha: 0.55),
                      spreadRadius: 5),
                  BoxShadow(color: c.paper, spreadRadius: 3),
                ],
              ),
            ),
            Positioned(
              bottom: -7,
              right: -7,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                  border: Border.all(color: c.paper, width: 2),
                ),
                child: const Icon(AppIcons.star,
                    size: 13, color: Color(0xFF3A2A00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.icon,
    required this.ink,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(13);
    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(c.accent, Colors.white, 0.26)!, c.accent],
            ),
            boxShadow: [
              BoxShadow(
                  color: c.accentStrong.withValues(alpha: 0.80),
                  offset: const Offset(0, 4)),
              BoxShadow(
                  color: c.accentStrong.withValues(alpha: 0.55),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                  spreadRadius: -8),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: 8),
              Text(label,
                  style: AppType.fredoka(
                      size: 14.5, weight: FontWeight.w600, color: ink)),
            ],
          ),
        ),
      ),
    );
  }
}
