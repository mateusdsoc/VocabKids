import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../trilha/trilha_screen.dart';
import 'models.dart';
import 'widgets/achievement_card.dart';
import 'widgets/resumo_background.dart';
import 'widgets/resumo_header.dart';
import 'widgets/word_progress_row.dart';
import 'widgets/xp_summary_card.dart';

/// Resumo de sessão (produto 3.7) — comemoração curta e gentil ao fim da
/// prática. **Não é boletim:** XP da sessão como número-herói, progressão das
/// palavras (o que importa) e volta para a Trilha. Sem % de acerto, sem tempo,
/// sem streak. Quando há item novo, mostra o teaser dourado do Passaporte.
///
/// Porte fiel do design `Refino/Vocab - Resumo de sessão`. Claro e escuro saem
/// dos tokens de [AppColors] — no claro os cards são "vidro fosco".
class ResumoScreen extends StatelessWidget {
  const ResumoScreen({super.key, this.summary = SessionSummary.sample});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ach = summary.achievement;

    return Scaffold(
      body: ResumoBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 3),
                        // Entrada escalonada: cabeçalho → XP (que então conta
                        // e enche a barra) → conquista → palavras. Curta e
                        // não-bloqueante: o CTA do rodapé já responde.
                        Entrance(
                          child: ResumoHeader(
                              city: summary.city, lesson: summary.lesson),
                        ),
                        const SizedBox(height: 13),
                        Entrance(
                          delay: const Duration(milliseconds: 120),
                          child: XpSummaryCard(summary: summary),
                        ),
                        if (ach != null) ...[
                          const SizedBox(height: 16),
                          Entrance(
                            delay: const Duration(milliseconds: 260),
                            scaleFrom: 0.96,
                            child: AchievementCard(ach: ach),
                          ),
                        ],
                        const SizedBox(height: 13),
                        Entrance(
                          delay: const Duration(milliseconds: 320),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              'PALAVRAS DESTA SESSÃO',
                              style: AppType.mono(
                                  size: 9.5,
                                  weight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: c.muted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < summary.words.length; i++) ...[
                          if (i > 0) const SizedBox(height: 9),
                          Entrance(
                            delay: Duration(milliseconds: 380 + 80 * i),
                            child: WordProgressRow(word: summary.words[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Footer(
                  onTrilha: () => Navigator.of(context).pushReplacement(
                    adaptivePageRoute(builder: (_) => const TrilhaScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rodapé: CTA "Ver trilha" (aterrissagem pós-sessão) + link discreto pra Home.
class _Footer extends StatelessWidget {
  const _Footer({required this.onTrilha});
  final VoidCallback onTrilha;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: 'Ver trilha',
          leadingIcon: AppIcons.map,
          onTap: onTrilha,
        ),
        const SizedBox(height: 9),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Voltar ao início',
              style: AppType.nunito(
                  size: 13.5, weight: FontWeight.w800, color: c.muted)),
        ),
      ],
    );
  }
}
