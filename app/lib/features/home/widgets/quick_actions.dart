import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';

/// Linha de atalhos secundários da Home (Redação · Eventos). Cada item é um
/// [QuickActionCard] reutilizável — adicionar um novo atalho é trivial.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.onRedacao, this.onEventos});

  final VoidCallback? onRedacao;
  final VoidCallback? onEventos;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: QuickActionCard(
            icon: AppIcons.redacao,
            iconColor: c.accentStrong,
            iconBg: Color.alphaBlend(c.accent.withValues(alpha: 0.20), c.paper),
            title: 'Redação',
            subtitle: 'escreva & ganhe XP',
            onTap: onRedacao,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: QuickActionCard(
            icon: AppIcons.eventos,
            iconColor: c.primary,
            iconBg: Color.alphaBlend(c.primary.withValues(alpha: 0.14), c.paper),
            title: 'Eventos',
            subtitle: 'novidades da viagem',
            onTap: onEventos,
          ),
        ),
      ],
    );
  }
}

/// Card de atalho genérico: ícone em quadro colorido + título + legenda.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.fredoka(
                      size: 14.5, weight: FontWeight.w500, color: c.ink, height: 1.05),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.nunito(
                      size: 10, weight: FontWeight.w800, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
