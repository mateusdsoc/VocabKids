import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../format.dart';
import '../models.dart';

/// Herói da área de Redação: a redação aberta agora, como uma carta esperando
/// resposta. Tema em destaque, prazo com urgência e o CTA de envio.
class OpenRedacaoCard extends StatelessWidget {
  const OpenRedacaoCard({super.key, required this.redacao, required this.onEnviar});

  final Redacao redacao;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prazo = prazoStatus(redacao.prazo);
    final prazoColor = prazo.urgente ? c.warn : c.muted;

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(AppIcons.redacao, size: 15, color: c.accentStrong),
                  const SizedBox(width: 7),
                  Text('REDAÇÃO ABERTA',
                      style: AppType.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: c.muted)),
                ],
              ),
              if (redacao.prazo != null)
                Text(dataCurta(redacao.prazo!),
                    style: AppType.mono(
                        size: 10,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: c.muted)),
            ],
          ),
          const SizedBox(height: 13),
          Text(redacao.tema,
              style: AppType.fredoka(size: 24, color: c.ink, height: 1.08)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                prazo.urgente ? AppIcons.eventos : AppIcons.meta,
                size: 15,
                color: prazoColor,
              ),
              const SizedBox(width: 7),
              Text(prazo.texto,
                  style: AppType.nunito(
                      size: 13.5, weight: FontWeight.w800, color: prazoColor)),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Enviar redação',
            leadingIcon: AppIcons.camera,
            onTap: onEnviar,
          ),
        ],
      ),
    );
  }
}
