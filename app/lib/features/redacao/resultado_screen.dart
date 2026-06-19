import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/surface_card.dart';
import 'analise.dart';
import 'format.dart';
import 'models.dart';
import 'redacao_providers.dart';
import 'widgets/annotated_text.dart';
import 'widgets/annotation_sheet.dart';
import 'widgets/dimensao_chip.dart';
import 'widgets/palavra_nova_card.dart';
import 'widgets/redacao_background.dart';
import 'widgets/status_chip.dart';

/// Resultado da redação — a **correção** que é o diferencial do produto (4.4):
/// o texto do aluno anotado com grifos por dimensão, o resumo do que foi olhado,
/// os pontos fortes e as palavras novas que a redação rendeu (loop 3.2).
///
/// Consome `GET /v1/redacoes/{id}/analise` (em demo, [AnaliseRedacao.demo]).
/// Mesmo contrato da fatia C — quando o OCR→LLM entrar, só muda a fonte do dado.
class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key, required this.redacao});

  final Redacao redacao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      style:
                          AppType.fredoka(size: 25, color: c.ink, height: 1.06)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatusChip(status: redacao.status),
                      if (enviada != null) ...[
                        const SizedBox(width: 9),
                        Text(
                            'Enviada ${dataCurta(enviada)} · ${redacao.paginas} pág.',
                            style: AppType.nunito(
                                size: 12,
                                weight: FontWeight.w700,
                                color: c.muted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: analisada
                        ? _Correcao(redacaoId: redacao.id)
                        : const Center(child: _EmAnalisePlaceholder()),
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

/// Carrega e desenha a correção. Estados honestos: carregando, erro de rede e o
/// resultado completo.
class _Correcao extends ConsumerWidget {
  const _Correcao({required this.redacaoId});

  final int redacaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analiseRedacaoProvider(redacaoId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => const Center(child: _ErroAnalise()),
      data: (analise) {
        if (analise == null || !analise.analisada) {
          return const Center(child: _EmAnalisePlaceholder());
        }
        return _CorrecaoBody(analise: analise);
      },
    );
  }
}

class _CorrecaoBody extends StatelessWidget {
  const _CorrecaoBody({required this.analise});

  final AnaliseRedacao analise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final comGrifo = analise.ancoradas;
    final notas = analise.holisticas;
    // Dimensões com pontos a revisar (têm grifo) — o resumo "do que olhamos".
    final resumo = [
      for (final d in analise.dimensoes)
        if (analise.marcasDe(d) > 0) d,
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) Resumo da correção — contagens por dimensão, sem nota nem %.
          if (resumo.isNotEmpty) ...[
            Text('O QUE OLHAMOS',
                style: AppType.mono(
                    size: 9.5,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: c.muted)),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in resumo)
                  DimensaoChip(dimensao: d, contagem: analise.marcasDe(d)),
              ],
            ),
            const SizedBox(height: 18),
          ],

          // 2) A redação anotada — o coração da tela.
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.redacao, size: 15, color: c.accentStrong),
                    const SizedBox(width: 7),
                    Text('Sua redação',
                        style: AppType.fredoka(size: 17, color: c.ink)),
                  ],
                ),
                if (comGrifo.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Toque nos trechos sublinhados para ver as dicas.',
                      style: AppType.nunito(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: c.muted)),
                ],
                const SizedBox(height: 14),
                AnnotatedText(
                  texto: analise.textoExtraido,
                  anotacoes: comGrifo,
                  onTocar: (a) => mostrarAnotacaoSheet(context, a),
                ),
              ],
            ),
          ),

          // 3) Observações gerais (holísticas, ex.: coesão) — sem grifo.
          if (notas.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (var i = 0; i < notas.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _NotaCard(anotacao: notas[i]),
            ],
          ],

          // 4) Pontos fortes — começa pelo que ficou bom.
          if (analise.pontosFortes.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PontosFortes(pontos: analise.pontosFortes),
          ],

          // 5) Palavras que a redação rendeu — o loop redação→vocabulário.
          if (analise.palavrasNovas.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PalavrasNovas(palavras: analise.palavrasNovas),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Nota geral sem grifo (anotação holística), ex.: coesão/estrutura.
class _NotaCard extends StatelessWidget {
  const _NotaCard({required this.anotacao});

  final Anotacao anotacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DimensaoChip(dimensao: anotacao.dimensao),
          const SizedBox(height: 10),
          Text(anotacao.titulo,
              style: AppType.fredoka(size: 16, color: c.ink, height: 1.15)),
          const SizedBox(height: 5),
          Text(anotacao.comentario,
              style: AppType.nunito(
                  size: 13, weight: FontWeight.w600, color: c.muted, height: 1.5)),
        ],
      ),
    );
  }
}

class _PontosFortes extends StatelessWidget {
  const _PontosFortes({required this.pontos});

  final List<String> pontos;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('O que ficou ótimo 🎉',
              style: AppType.fredoka(size: 17, color: c.ink)),
          const SizedBox(height: 12),
          for (var i = 0; i < pontos.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.check, size: 18, color: c.goal),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(pontos[i],
                      style: AppType.nunito(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: c.ink,
                          height: 1.4)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PalavrasNovas extends StatelessWidget {
  const _PalavrasNovas({required this.palavras});

  final List<PalavraNova> palavras;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Palavras que você ganhou',
            style: AppType.fredoka(size: 17, color: c.ink)),
        const SizedBox(height: 3),
        Text('Elas aparecem nas suas próximas práticas.',
            style:
                AppType.nunito(size: 12, weight: FontWeight.w600, color: c.muted)),
        const SizedBox(height: 12),
        for (var i = 0; i < palavras.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          PalavraNovaCard(palavra: palavras[i]),
        ],
      ],
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

/// Falha ao carregar a correção (rede) — sem drama, com convite a tentar de novo.
class _ErroAnalise extends StatelessWidget {
  const _ErroAnalise();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.retry, size: 36, color: c.muted),
          const SizedBox(height: 12),
          Text('Não foi possível abrir a correção',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 17, color: c.ink)),
          const SizedBox(height: 6),
          Text('Verifique a conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: AppType.nunito(
                  size: 12.5, weight: FontWeight.w600, color: c.muted)),
        ],
      ),
    );
  }
}
