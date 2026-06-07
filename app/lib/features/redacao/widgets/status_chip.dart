import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../models.dart';

/// Pílula de status da redação. Cores semânticas da marca: âmbar gentil para
/// "em análise" (aguardando), verde da meta para "analisada" (pronto),
/// primária para "aberta".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final RedacaoStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color tint, IconData icon, String label) = switch (status) {
      RedacaoStatus.aberta => (c.primary, AppIcons.redacao, 'Aberta'),
      RedacaoStatus.emAnalise => (c.warn, AppIcons.retry, 'Em análise'),
      RedacaoStatus.analisada => (c.goal, AppIcons.check, 'Analisada'),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 13, color: tint),
          const SizedBox(width: 5),
          Text(label,
              style: AppType.nunito(
                  size: compact ? 10.5 : 11.5,
                  weight: FontWeight.w800,
                  color: tint)),
        ],
      ),
    );
  }
}
