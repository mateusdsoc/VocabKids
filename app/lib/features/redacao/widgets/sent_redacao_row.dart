import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import '../format.dart';
import '../models.dart';
import 'status_chip.dart';

/// Linha compacta do histórico de redações enviadas. Toca → resultado (hoje,
/// placeholder honesto, pois a análise é fatia C).
class SentRedacaoRow extends StatelessWidget {
  const SentRedacaoRow({super.key, required this.redacao, required this.onTap});

  final Redacao redacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enviada = redacao.enviadaEm;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(redacao.tema,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.fredoka(
                        size: 16, weight: FontWeight.w500, color: c.ink)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    StatusChip(status: redacao.status, compact: true),
                    if (enviada != null) ...[
                      const SizedBox(width: 8),
                      Text('Enviada ${dataCurta(enviada)}',
                          style: AppType.nunito(
                              size: 11,
                              weight: FontWeight.w700,
                              color: c.muted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(AppIcons.chevron, size: 22, color: c.muted),
        ],
      ),
    );
  }
}
