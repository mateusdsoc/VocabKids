import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/surface_card.dart';
import '../professor_data.dart';
import '../professor_providers.dart';

/// **Detalhe do aluno** (telas §8.2) — drill-down do painel. Só leitura
/// (ver≠configurar, §3.11): progresso da meta, palavras dominadas/em progresso,
/// vocabulário recente e redações do aluno. Sem ações de configurar.
///
/// Página própria (push) com voltar; o nome chega pelo construtor para o
/// cabeçalho pintar na hora, sem flash enquanto o detalhe carrega.
class AlunoDetalheScreen extends ConsumerWidget {
  const AlunoDetalheScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  final int alunoId;
  final String alunoNome;

  /// Largura máxima da coluna — mais estreita que o painel: é uma leitura focada.
  static const double _maxWidth = 860;

  static Route<void> route(int alunoId, String alunoNome) =>
      MaterialPageRoute<void>(
        builder: (_) =>
            AlunoDetalheScreen(alunoId: alunoId, alunoNome: alunoNome),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(alunoDetalheProvider(alunoId));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackBar(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: async.when(
                    loading: () => _LoadingBody(nome: alunoNome),
                    error: (e, _) => _ErroBody(
                      nome: alunoNome,
                      onRetry: () =>
                          ref.invalidate(alunoDetalheProvider(alunoId)),
                    ),
                    data: (data) => _DetalheBody(data: data),
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

class _BackBar extends StatelessWidget {
  const _BackBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 24, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.back, size: 22, color: c.primary),
                  const SizedBox(width: 4),
                  Text('Voltar ao painel',
                      style: AppType.nunito(
                          size: 14, weight: FontWeight.w700, color: c.primary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.nome, required this.subtitulo});
  final String nome;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: c.avatarGradient),
          ),
          child: Text(nome.isEmpty ? '?' : nome[0],
              style: AppType.fredoka(size: 20, color: c.onPrimary)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome,
                  style: AppType.fredoka(size: 25, color: c.ink),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitulo,
                  style: AppType.nunito(
                      size: 13.5, weight: FontWeight.w600, color: c.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: [
        _Header(nome: nome, subtitulo: 'Carregando…'),
        const SizedBox(height: 48),
        const Center(child: CircularProgressIndicator.adaptive()),
      ],
    );
  }
}

class _DetalheBody extends StatelessWidget {
  const _DetalheBody({required this.data});
  final AlunoDetalhe data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: [
        Entrance(
          child: _Header(
            nome: data.nome,
            subtitulo: 'Turma ${data.turmaNome} · ${data.anoEscolar}º ano',
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 60),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MetaCard(data: data),
              _Kpi(
                  label: 'Palavras dominadas',
                  valor: '${data.palavrasDominadas}',
                  sub: 'no total',
                  cor: context.colors.goal),
              _Kpi(
                  label: 'Em progresso',
                  valor: '${data.palavrasEmProgresso}',
                  sub: 'aprendendo agora',
                  cor: context.colors.primary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 120),
          child: _VocabCard(palavras: data.palavras),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 180),
          child: _RedacoesCard(redacoes: data.redacoes),
        ),
      ],
    );
  }
}

// --- KPIs --------------------------------------------------------------------

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.data});
  final AlunoDetalhe data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cor = data.metaCumprida ? c.goal : c.primary;
    final sub = data.metaCumprida
        ? 'meta da semana cumprida'
        : 'faltam ${data.faltamMeta} para a meta';
    return SizedBox(
      width: 300,
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('META DA SEMANA', style: AppType.mono(size: 10, color: c.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${data.palavrasSemana}',
                        style: AppType.fredoka(size: 32, color: cor)),
                    TextSpan(
                        text: ' / ${data.metaSemana}',
                        style: AppType.fredoka(size: 20, color: c.muted)),
                  ]),
                ),
                const Spacer(),
                if (data.metaCumprida)
                  Icon(AppIcons.check, size: 22, color: c.goal),
              ],
            ),
            const SizedBox(height: 10),
            ProgressBar(value: data.metaFraction, color: cor),
            const SizedBox(height: 8),
            Text(sub,
                style: AppType.nunito(
                    size: 12.5, weight: FontWeight.w600, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.valor,
    required this.sub,
    required this.cor,
  });

  final String label;
  final String valor;
  final String sub;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 200,
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: AppType.mono(size: 10, color: c.muted)),
            const SizedBox(height: 8),
            Text(valor, style: AppType.fredoka(size: 32, color: cor)),
            const SizedBox(height: 2),
            Text(sub,
                style: AppType.nunito(
                    size: 12.5, weight: FontWeight.w600, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

// --- Vocabulário -------------------------------------------------------------

class _VocabCard extends StatelessWidget {
  const _VocabCard({required this.palavras});
  final List<PalavraAluno> palavras;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Mais avançadas primeiro (dominadas no topo). Cópia: não muta a fonte.
    final ordenadas = [...palavras]
      ..sort((a, b) => b.estado.rank.compareTo(a.estado.rank));

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Vocabulário',
                        style: AppType.fredoka(size: 18, color: c.ink)),
                    const Spacer(),
                    Text('${palavras.length}',
                        style: AppType.nunito(
                            size: 13, weight: FontWeight.w700, color: c.muted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                    'Palavras recentes e em progresso. A origem mostra de onde '
                    'a palavra entrou na trilha.',
                    style: AppType.nunito(
                        size: 12.5, weight: FontWeight.w600, color: c.muted)),
              ],
            ),
          ),
          if (ordenadas.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ainda sem palavras registradas.',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w600, color: c.muted)),
              ),
            )
          else
            for (final p in ordenadas) _PalavraRow(palavra: p),
        ],
      ),
    );
  }
}

class _PalavraRow extends StatelessWidget {
  const _PalavraRow({required this.palavra});
  final PalavraAluno palavra;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(palavra.texto,
                    style: AppType.nunito(
                        size: 15, weight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 3),
                _Badge(
                  texto: palavra.origem.rotulo,
                  cor: _corOrigem(c, palavra.origem),
                  pequeno: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Badge(texto: palavra.estado.rotulo, cor: _corEstado(c, palavra.estado)),
        ],
      ),
    );
  }
}

// --- Redações ----------------------------------------------------------------

class _RedacoesCard extends StatelessWidget {
  const _RedacoesCard({required this.redacoes});
  final List<RedacaoAluno> redacoes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Text('Redações', style: AppType.fredoka(size: 18, color: c.ink)),
                const Spacer(),
                Text('${redacoes.length}',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
          if (redacoes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Nenhuma redação atribuída ainda.',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w600, color: c.muted)),
              ),
            )
          else
            for (final r in redacoes) _RedacaoRow(redacao: r),
        ],
      ),
    );
  }
}

class _RedacaoRow extends StatelessWidget {
  const _RedacaoRow({required this.redacao});
  final RedacaoAluno redacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = redacao.dataCurta;
    final sub = data != null ? 'enviada em $data' : 'ainda não enviada';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(AppIcons.redacao, size: 20, color: c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(redacao.tema,
                    style: AppType.nunito(
                        size: 14.5, weight: FontWeight.w700, color: c.ink),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(sub,
                    style: AppType.nunito(
                        size: 12, weight: FontWeight.w600, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Badge(
              texto: redacao.status.rotulo, cor: _corStatus(c, redacao.status)),
        ],
      ),
    );
  }
}

// --- Compartilhados ----------------------------------------------------------

/// Pílula tingida (fundo suave + texto na cor). Mesma linguagem dos chips do
/// "sinal" do painel; [pequeno] para as tags de origem.
class _Badge extends StatelessWidget {
  const _Badge({required this.texto, required this.cor, this.pequeno = false});
  final String texto;
  final Color cor;
  final bool pequeno;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: pequeno ? 8 : 10, vertical: pequeno ? 3 : 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto,
          style: AppType.nunito(
              size: pequeno ? 11 : 12,
              weight: FontWeight.w700,
              color: cor)),
    );
  }
}

Color _corEstado(AppColors c, EstadoPalavra estado) => switch (estado) {
      EstadoPalavra.dominada => c.goal,
      EstadoPalavra.descoberta => c.muted,
      _ => c.primary,
    };

Color _corOrigem(AppColors c, OrigemPalavra origem) => switch (origem) {
      OrigemPalavra.pessoalRedacao => c.accentStrong,
      OrigemPalavra.sinalTurma => c.warn,
      OrigemPalavra.bancoBase => c.muted,
    };

Color _corStatus(AppColors c, StatusRedacao status) => switch (status) {
      StatusRedacao.analisada => c.goal,
      StatusRedacao.emAnalise => c.warn,
      StatusRedacao.pendente => c.muted,
      StatusRedacao.rascunho => c.muted,
    };

class _ErroBody extends StatelessWidget {
  const _ErroBody({required this.nome, required this.onRetry});
  final String nome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: [
        _Header(nome: nome, subtitulo: ''),
        const SizedBox(height: 40),
        Icon(Icons.cloud_off_rounded, size: 40, color: c.muted),
        const SizedBox(height: 12),
        Text('Não consegui carregar o aluno.',
            textAlign: TextAlign.center,
            style: AppType.fredoka(size: 17, color: c.ink)),
        const SizedBox(height: 14),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
            ),
            child: const Text('Tentar de novo'),
          ),
        ),
      ],
    );
  }
}
