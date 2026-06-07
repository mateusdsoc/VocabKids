import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/surface_card.dart';
import 'format.dart';
import 'models.dart';
import 'widgets/redacao_background.dart';
import 'widgets/status_chip.dart';

/// Resultado da redação. Como o pipeline OCR→análise é **fatia C**, aqui não há
/// métricas inventadas: "em análise" mostra um aguardo honesto; "analisada"
/// mostra um placeholder do que virá (sem números falsos), até o contrato real
/// da análise existir.
class ResultadoScreen extends StatelessWidget {
  const ResultadoScreen({super.key, required this.redacao});

  final Redacao redacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final analisada = redacao.status == RedacaoStatus.analisada;
    final enviada = redacao.enviadaEm;

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: RedacaoBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: c.glass,
                      shape: CircleBorder(
                          side: BorderSide(color: c.line, width: 1)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(AppIcons.back, size: 24, color: c.ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(redacao.tema,
                      style: AppType.fredoka(size: 25, color: c.ink, height: 1.06)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatusChip(status: redacao.status),
                      if (enviada != null) ...[
                        const SizedBox(width: 9),
                        Text('Enviada ${dataCurta(enviada)} · ${redacao.paginas} pág.',
                            style: AppType.nunito(
                                size: 12,
                                weight: FontWeight.w700,
                                color: c.muted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: analisada
                          ? const _AnalisadaPlaceholder()
                          : const _EmAnalisePlaceholder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aguardando análise — honesto, sem prometer número nenhum.
class _EmAnalisePlaceholder extends StatelessWidget {
  const _EmAnalisePlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.clock, size: 40, color: c.warn),
          const SizedBox(height: 14),
          Text('Recebemos sua redação!',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 19, color: c.ink)),
          const SizedBox(height: 7),
          Text(
            'Estamos lendo com carinho. Sua análise e as\npalavras novas aparecem aqui em breve.',
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 13, weight: FontWeight.w600, color: c.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Análise concluída — placeholder do que virá (sem métricas fabricadas).
class _AnalisadaPlaceholder extends StatelessWidget {
  const _AnalisadaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.check, size: 40, color: c.goal),
          const SizedBox(height: 14),
          Text('Análise concluída',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 19, color: c.ink)),
          const SizedBox(height: 7),
          Text(
            'O detalhamento da análise (palavras, coesão e\nas sugestões) entra com o motor de correção.',
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 13, weight: FontWeight.w600, color: c.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
