import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/surface_card.dart';
import 'analise_mock.dart';
import 'format.dart';
import 'models.dart';
import 'widgets/redacao_background.dart';
import 'widgets/status_chip.dart';
import 'widgets/texto_anotado.dart';

/// Resultado da redação. "Em análise" mostra um aguardo honesto; "analisada"
/// mostra a **análise mockada** (telas §8.1 — dados fictícios): o texto do
/// aluno anotado por dimensão + notas qualitativas + as palavras novas que
/// entram na trilha (§4.5). O pipeline real (OCR→IA) é fatia C; aqui a fonte é
/// [AnaliseRedacao.sample] e a tela já renderiza o formato definitivo.
///
/// Sem nota, sem percentual, sem gráfico (decisão 12/06): o feedback do aluno
/// é qualitativo — dashboards são do professor (telas §8.2).
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
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: analisada
                        ? const SingleChildScrollView(
                            padding: EdgeInsets.only(bottom: 20),
                            child: _AnaliseView(analise: AnaliseRedacao.sample),
                          )
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

/// A análise inteira, na ordem do tom do produto: **elogio primeiro** (pontos
/// fortes), depois o texto anotado (com detalhe sob toque), a nota de
/// estrutura e, fechando o ciclo, as palavras novas que entram na trilha.
class _AnaliseView extends StatefulWidget {
  const _AnaliseView({required this.analise});

  final AnaliseRedacao analise;

  @override
  State<_AnaliseView> createState() => _AnaliseViewState();
}

class _AnaliseViewState extends State<_AnaliseView> {
  /// Índice da anotação selecionada (toque num grifo); nula = dica de uso.
  int? _selecionada;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final analise = widget.analise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(child: _PontosFortes(itens: analise.pontosFortes)),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('SUA REDAÇÃO, LIDA DE PERTO',
              style: AppType.mono(
                  size: 9.5,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: c.muted)),
        ),
        const SizedBox(height: 9),
        _Legenda(),
        const SizedBox(height: 9),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: TextoAnotado(
            analise: analise,
            selecionada: _selecionada,
            onTapAnotacao: (i) => setState(
                () => _selecionada = _selecionada == i ? null : i),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selecionada == null
              ? const _DicaToque(key: ValueKey('dica'))
              : _DetalheAnotacao(
                  key: ValueKey(_selecionada),
                  anotacao: analise.anotacoes[_selecionada!],
                ),
        ),
        const SizedBox(height: 20),
        _NotaEstrutura(nota: analise.estrutura),
        const SizedBox(height: 12),
        _PalavrasNovas(palavras: analise.palavrasNovas),
      ],
    );
  }
}

/// "Você mandou bem" — o elogio abre a análise (errar é aprender; o ajuste vem
/// depois do reconhecimento).
class _PontosFortes extends StatelessWidget {
  const _PontosFortes({required this.itens});

  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.star, size: 19, color: c.accentStrong),
              const SizedBox(width: 7),
              Text('Você mandou bem',
                  style: AppType.fredoka(size: 16.5, color: c.ink)),
            ],
          ),
          const SizedBox(height: 10),
          for (final p in itens) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(AppIcons.check, size: 16, color: c.goal),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p,
                        style: AppType.nunito(
                            size: 13,
                            weight: FontWeight.w700,
                            color: c.ink,
                            height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Legenda das dimensões grifáveis (estrutura não grifa — vira nota).
class _Legenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const dims = [
      DimensaoAnalise.vocabulario,
      DimensaoAnalise.acentuacao,
      DimensaoAnalise.pontuacao,
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final d in dims)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: estiloDimensao(c, d).cor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(estiloDimensao(c, d).rotulo,
                  style: AppType.nunito(
                      size: 11, weight: FontWeight.w800, color: c.muted)),
            ],
          ),
      ],
    );
  }
}

/// Estado vazio do detalhe: convida a tocar nos grifos.
class _DicaToque extends StatelessWidget {
  const _DicaToque({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(AppIcons.tocar, size: 18, color: c.muted),
          const SizedBox(width: 9),
          Expanded(
            child: Text('Toque nas partes coloridas para ver as dicas.',
                style: AppType.nunito(
                    size: 12.5, weight: FontWeight.w700, color: c.muted)),
          ),
        ],
      ),
    );
  }
}

/// Detalhe da anotação tocada: chip da dimensão, achado, explicação e os chips
/// de sugestão. A resposta "pronta" não substitui o texto do aluno — sugere.
class _DetalheAnotacao extends StatelessWidget {
  const _DetalheAnotacao({super.key, required this.anotacao});

  final Anotacao anotacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final estilo = estiloDimensao(c, anotacao.dimensao);

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ChipDimensao(cor: estilo.cor, rotulo: estilo.rotulo),
              const SizedBox(width: 9),
              Expanded(
                child: Text(anotacao.titulo,
                    style: AppType.fredoka(size: 15, color: c.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(anotacao.comentario,
              style: AppType.nunito(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: c.muted,
                  height: 1.45)),
          if (anotacao.sugestoes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final s in anotacao.sugestoes)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                          estilo.cor.withValues(alpha: 0.12), c.paper),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(s,
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: c.ink)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipDimensao extends StatelessWidget {
  const _ChipDimensao({required this.cor, required this.rotulo});

  final Color cor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withValues(alpha: 0.16), c.paper),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(rotulo,
          style: AppType.nunito(
              size: 10.5, weight: FontWeight.w800, color: c.ink)),
    );
  }
}

/// Nota holística de estrutura/coesão (produto §4.2: informativa, sem grifo).
class _NotaEstrutura extends StatelessWidget {
  const _NotaEstrutura({required this.nota});

  final Anotacao nota;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final estilo = estiloDimensao(c, nota.dimensao);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.dica, size: 18, color: estilo.cor),
              const SizedBox(width: 7),
              _ChipDimensao(cor: estilo.cor, rotulo: estilo.rotulo),
            ],
          ),
          const SizedBox(height: 10),
          Text(nota.titulo, style: AppType.fredoka(size: 15.5, color: c.ink)),
          const SizedBox(height: 6),
          Text(nota.comentario,
              style: AppType.nunito(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: c.muted,
                  height: 1.45)),
        ],
      ),
    );
  }
}

/// Fecho do ciclo central (§4.5): as palavras repetidas/fracas da redação
/// viram palavras novas na trilha — feedback que vira prática, não boletim.
class _PalavrasNovas extends StatelessWidget {
  const _PalavrasNovas({required this.palavras});

  final List<PalavraNova> palavras;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.novaPalavra, size: 19, color: c.primary),
              const SizedBox(width: 7),
              Text('Da sua redação para a trilha',
                  style: AppType.fredoka(size: 16, color: c.ink)),
            ],
          ),
          const SizedBox(height: 11),
          for (final p in palavras) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.line, width: 1.5),
                    ),
                    child: Text(p.gatilho,
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: c.muted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(AppIcons.arrow, size: 16, color: c.muted),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                          c.primary.withValues(alpha: 0.12), c.paper),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(p.palavra,
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: c.ink)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('Essas palavras vão aparecer nas suas próximas sessões.',
              style: AppType.nunito(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: c.muted,
                  height: 1.35)),
        ],
      ),
    );
  }
}
