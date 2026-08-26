import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/surface_card.dart';
import 'data/redacao_models.dart';
import 'models.dart';
import 'redacao_controller.dart';
import 'widgets/redacao_background.dart';
import 'widgets/status_chip.dart';

/// Resultado da redação (`GET /v1/redacoes/{id}/analise`). R-RD-5: nunca uma
/// nota numérica — só conquistas (`pontos_fortes`) e anotações pontuais no
/// próprio texto, por dimensão (vocabulário/ortografia/coesão/estrutura/
/// adequação ao tema).
class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key, required this.redacao});

  final Redacao redacao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final redacaoId = redacao.redacaoId;
    final async = redacaoId == null
        ? null
        : ref.watch(analiseProvider(redacaoId));

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
                      style:
                          AppType.fredoka(size: 25, color: c.ink, height: 1.06)),
                  const SizedBox(height: 10),
                  StatusChip(status: redacao.status),
                  const SizedBox(height: 20),
                  Expanded(
                    child: async == null
                        ? const _EmAnalisePlaceholder()
                        : async.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Center(
                              child: _MensagemCard(
                                icon: AppIcons.report,
                                iconColor: c.error,
                                titulo: 'Não deu para carregar',
                                corpo: e is ApiException
                                    ? e.message
                                    : 'Tente de novo em instantes.',
                              ),
                            ),
                            data: (dto) => _Conteudo(dto: dto),
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

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.dto});
  final AnaliseOutDto dto;

  @override
  Widget build(BuildContext context) {
    return switch (redacaoStatusDe(dto.status)) {
      RedacaoStatus.analisada when dto.analise != null =>
        _Analisada(dto: dto, analise: dto.analise!),
      RedacaoStatus.revisaoHumana => const _RevisaoHumanaPlaceholder(),
      RedacaoStatus.erroIngestao => const _ErroIngestaoPlaceholder(),
      RedacaoStatus.erroAnalise => const _ErroAnalisePlaceholder(),
      _ => const _EmAnalisePlaceholder(),
    };
  }
}

class _MensagemCard extends StatelessWidget {
  const _MensagemCard({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.corpo,
  });

  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String corpo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(height: 14),
          Text(titulo,
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 19, color: c.ink)),
          const SizedBox(height: 7),
          Text(corpo,
              textAlign: TextAlign.center,
              style: AppType.nunito(
                  size: 13, weight: FontWeight.w600, color: c.muted, height: 1.4)),
        ],
      ),
    );
  }
}

class _EmAnalisePlaceholder extends StatelessWidget {
  const _EmAnalisePlaceholder();
  @override
  Widget build(BuildContext context) => Center(
        child: _MensagemCard(
          icon: AppIcons.clock,
          iconColor: context.colors.warn,
          titulo: 'Recebemos sua redação!',
          corpo: 'Estamos lendo com carinho. Sua análise aparece aqui em breve.',
        ),
      );
}

class _RevisaoHumanaPlaceholder extends StatelessWidget {
  const _RevisaoHumanaPlaceholder();
  @override
  Widget build(BuildContext context) => Center(
        child: _MensagemCard(
          icon: AppIcons.info,
          iconColor: context.colors.warn,
          titulo: 'Sua redação está com a gente',
          corpo:
              'Antes de continuar, um adulto de confiança vai dar uma olhada '
              'com você. Fale com o seu responsável.',
        ),
      );
}

class _ErroIngestaoPlaceholder extends StatelessWidget {
  const _ErroIngestaoPlaceholder();
  @override
  Widget build(BuildContext context) => Center(
        child: _MensagemCard(
          icon: AppIcons.report,
          iconColor: context.colors.warn,
          titulo: 'Queremos ler mais!',
          corpo:
              'Sua redação ficou mais curta do que o esperado para essa fase. '
              'Na próxima, capriche nos detalhes.',
        ),
      );
}

class _ErroAnalisePlaceholder extends StatelessWidget {
  const _ErroAnalisePlaceholder();
  @override
  Widget build(BuildContext context) => Center(
        child: _MensagemCard(
          icon: AppIcons.report,
          iconColor: context.colors.error,
          titulo: 'Algo não saiu certo',
          corpo: 'Não conseguimos analisar essa redação agora. Tente enviar a '
              'próxima mais tarde.',
        ),
      );
}

/// Análise concluída: conquistas + texto grifado por dimensão + anotações.
class _Analisada extends StatelessWidget {
  const _Analisada({required this.dto, required this.analise});
  final AnaliseOutDto dto;
  final AnaliseDto analise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      children: [
        if (analise.pontosFortes.isNotEmpty)
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.star, size: 15, color: c.goal),
                    const SizedBox(width: 7),
                    Text('O QUE FICOU BOM',
                        style: AppType.mono(
                            size: 9.5,
                            weight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: c.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                for (final ponto in analise.pontosFortes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $ponto',
                        style: AppType.nunito(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: c.ink,
                            height: 1.4)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: RichText(
            text: TextSpan(
              children: _spansDoTexto(context, dto.textoExtraido, analise.anotacoes),
            ),
          ),
        ),
        if (analise.anotacoes.isNotEmpty) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text('PONTOS DE MELHORIA',
                style: AppType.mono(
                    size: 9.5,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: c.muted)),
          ),
          const SizedBox(height: 9),
          for (var i = 0; i < analise.anotacoes.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _AnotacaoCard(anotacao: analise.anotacoes[i]),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AnotacaoCard extends StatelessWidget {
  const _AnotacaoCard({required this.anotacao});
  final AnotacaoDto anotacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cor = _corDimensao(context, anotacao.dimensao);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(top: 2, right: 12),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelDimensao(anotacao.dimensao),
                    style: AppType.mono(
                        size: 9.5,
                        weight: FontWeight.w700,
                        letterSpacing: 1,
                        color: cor)),
                const SizedBox(height: 3),
                Text(anotacao.titulo,
                    style: AppType.fredoka(size: 15.5, color: c.ink)),
                const SizedBox(height: 4),
                Text(anotacao.comentario,
                    style: AppType.nunito(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: c.muted,
                        height: 1.4)),
                if (anotacao.sugestoes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in anotacao.sugestoes)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(s,
                              style: AppType.nunito(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: cor)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grifa no texto original os trechos com âncora, um span por anotação (sem
/// sobrepor); trechos sem anotação ficam no estilo normal.
List<InlineSpan> _spansDoTexto(
    BuildContext context, String texto, List<AnotacaoDto> anotacoes) {
  final c = context.colors;
  final baseStyle = AppType.nunito(
      size: 14, weight: FontWeight.w600, color: c.ink, height: 1.6);

  final marcas = <(int inicio, int fim, Color cor)>[];
  for (final a in anotacoes) {
    final cor = _corDimensao(context, a.dimensao);
    for (final ancora in a.ancoras) {
      if (ancora.inicio < 0 ||
          ancora.fim > texto.length ||
          ancora.inicio >= ancora.fim) {
        continue;
      }
      marcas.add((ancora.inicio, ancora.fim, cor));
    }
  }
  marcas.sort((x, y) => x.$1.compareTo(y.$1));

  final spans = <InlineSpan>[];
  var pos = 0;
  for (final m in marcas) {
    if (m.$1 < pos) continue; // sobreposição com uma marca já aceita
    if (m.$1 > pos) {
      spans.add(TextSpan(text: texto.substring(pos, m.$1), style: baseStyle));
    }
    spans.add(TextSpan(
      text: texto.substring(m.$1, m.$2),
      style: baseStyle.copyWith(
        backgroundColor: m.$3.withValues(alpha: 0.22),
        color: m.$3,
        fontWeight: FontWeight.w800,
      ),
    ));
    pos = m.$2;
  }
  if (pos < texto.length) {
    spans.add(TextSpan(text: texto.substring(pos), style: baseStyle));
  }
  return spans;
}

Color _corDimensao(BuildContext context, String dimensao) {
  final c = context.colors;
  return switch (dimensao) {
    'vocabulario' => c.accentStrong,
    'ortografia' => c.error,
    'coesao' => c.primary,
    'estrutura' => c.goal,
    'adequacao_ao_tema' => c.warn,
    _ => c.muted,
  };
}

String _labelDimensao(String dimensao) => switch (dimensao) {
      'vocabulario' => 'VOCABULÁRIO',
      'ortografia' => 'ORTOGRAFIA',
      'coesao' => 'COESÃO',
      'estrutura' => 'ESTRUTURA',
      'adequacao_ao_tema' => 'ADEQUAÇÃO AO TEMA',
      _ => dimensao.toUpperCase(),
    };
