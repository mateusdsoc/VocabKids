import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../analise.dart';

/// Pílula de uma dimensão da correção: ponto na cor da dimensão + rótulo, com
/// uma contagem opcional ("3"). Serve de legenda no resumo e de cabeçalho na
/// folha de dica — a cor amarra o grifo do texto ao seu significado.
class DimensaoChip extends StatelessWidget {
  const DimensaoChip({super.key, required this.dimensao, this.contagem});

  final Dimensao dimensao;

  /// Quantos grifos desta dimensão; `null` esconde o número (uso de legenda).
  final int? contagem;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cor = dimensao.cor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cor.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(dimensao.rotulo,
              style: AppType.nunito(
                  size: 12, weight: FontWeight.w800, color: c.ink)),
          if (contagem != null) ...[
            const SizedBox(width: 6),
            Text('$contagem',
                style: AppType.nunito(
                    size: 12, weight: FontWeight.w800, color: cor)),
          ],
        ],
      ),
    );
  }
}
