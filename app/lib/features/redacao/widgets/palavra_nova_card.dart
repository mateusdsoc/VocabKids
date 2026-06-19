import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../analise.dart';

/// Mostra uma palavra que a redação rendeu (produto 3.2): do gatilho repetido/
/// fraco para a alternativa nova. É a tradução visível do diferencial —
/// "errou na redação → ganhou vocabulário para a trilha".
class PalavraNovaCard extends StatelessWidget {
  const PalavraNovaCard({super.key, required this.palavra});

  final PalavraNova palavra;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Nasce do vocabulário, então usa a cor dessa dimensão (amarra ao grifo).
    final cor = Dimensao.vocabulario.cor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Icon(AppIcons.novaPalavra, size: 22, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(palavra.palavra,
                    style: AppType.fredoka(size: 18, color: c.ink)),
                const SizedBox(height: 2),
                Text('no lugar de “${palavra.gatilho}”',
                    style: AppType.nunito(
                        size: 12.5, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
