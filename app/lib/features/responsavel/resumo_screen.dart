import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/surface_card.dart';
import '../identidade/models.dart';
import 'data/responsavel_models.dart';
import 'responsavel_controller.dart';

/// Resumo semanal de um filho (produto §08, itens 1-3): meta/minutos/sessões,
/// as palavras que ele aprendeu essa semana (o item de maior valor
/// percebido) e a evolução da redação por dimensão. R-RS-2/R-RS-3: nunca taxa
/// de acerto, tempo por questão nem comparação entre crianças — só o que está
/// aqui.
class ResumoScreen extends ConsumerWidget {
  const ResumoScreen({super.key, required this.perfil});

  final PerfilCrianca perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(resumoSemanalProvider(perfil.usuarioId));

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  apelido: perfil.apelido,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        e is ApiException
                            ? e.message
                            : 'Não deu para carregar o resumo.',
                        textAlign: TextAlign.center,
                        style: AppType.nunito(
                            size: 13.5, weight: FontWeight.w700, color: c.muted),
                      ),
                    ),
                    data: (resumo) => _Corpo(resumo: resumo),
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

class _Header extends StatelessWidget {
  const _Header({required this.apelido, required this.onBack});
  final String apelido;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: c.glass,
              shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(AppIcons.back, size: 24, color: c.ink),
                ),
              ),
            ),
          ),
          Text('Resumo de $apelido',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.fredoka(size: 18, color: c.ink)),
        ],
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.resumo});
  final ResumoSemanalDto resumo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _MetaCard(meta: resumo.palavrasDominadas),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: AppIcons.clock,
                value: '${resumo.minutosNaSemana}',
                label: 'MINUTOS NA SEMANA',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: AppIcons.praticar,
                value: '${resumo.sessoesNaSemana}',
                label: 'SESSÕES NA SEMANA',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (resumo.aprendeuEssaSemana.isNotEmpty) ...[
          const _Eyebrow('O QUE ELE APRENDEU ESSA SEMANA'),
          const SizedBox(height: 9),
          for (var i = 0; i < resumo.aprendeuEssaSemana.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _PalavraCard(palavra: resumo.aprendeuEssaSemana[i]),
          ],
          const SizedBox(height: 22),
        ],
        if (resumo.evolucaoRedacao.isNotEmpty) ...[
          const _Eyebrow('EVOLUÇÃO DA REDAÇÃO'),
          const SizedBox(height: 9),
          for (var i = 0; i < resumo.evolucaoRedacao.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _EvolucaoCard(entrada: resumo.evolucaoRedacao[i]),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(text,
          style: AppType.mono(
              size: 9.5,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
              color: c.muted)),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.meta});
  final MetaSemanalDto meta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fracao = meta.alvo <= 0 ? 0.0 : meta.atual / meta.alvo;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.goal,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(AppIcons.meta, size: 17, color: c.onGoal),
              ),
              const SizedBox(width: 10),
              Text('Palavras dominadas',
                  style: AppType.fredoka(size: 15, color: c.ink)),
              const Spacer(),
              Text('${meta.atual}/${meta.alvo}',
                  style: AppType.fredoka(size: 17, color: c.accentStrong)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: fracao, color: c.goal),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: c.primary),
          const SizedBox(height: 10),
          Text(value, style: AppType.fredoka(size: 23, color: c.ink, height: 1.0)),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 2,
              style: AppType.mono(
                  size: 8.5,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: c.muted)),
        ],
      ),
    );
  }
}

class _PalavraCard extends StatelessWidget {
  const _PalavraCard({required this.palavra});
  final PalavraAprendidaDto palavra;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.novaPalavra, size: 18, color: c.accentStrong),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(palavra.palavra,
                    style: AppType.fredoka(size: 16, color: c.ink)),
                const SizedBox(height: 2),
                Text(palavra.definicao,
                    style: AppType.nunito(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: c.muted,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolucaoCard extends StatelessWidget {
  const _EvolucaoCard({required this.entrada});
  final NivelDimensaoDto entrada;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dimensoes = entrada.niveis.keys.toList()..sort();
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entrada.analisadaEm == null
                ? 'Redação analisada'
                : 'Redação de ${_dataCurta(entrada.analisadaEm!)}',
            style: AppType.mono(
                size: 9.5,
                weight: FontWeight.w700,
                letterSpacing: 1,
                color: c.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dimensao in dimensoes)
                _NivelChip(
                  dimensao: dimensao,
                  nivel: entrada.niveis[dimensao]!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NivelChip extends StatelessWidget {
  const _NivelChip({required this.dimensao, required this.nivel});
  final String dimensao;
  final String nivel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cor = _corNivel(c, nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_labelDimensao(dimensao),
              style: AppType.mono(
                  size: 8, weight: FontWeight.w700, letterSpacing: 0.6, color: cor)),
          const SizedBox(height: 2),
          Text(_capitalizar(nivel),
              style:
                  AppType.nunito(size: 12, weight: FontWeight.w800, color: cor)),
        ],
      ),
    );
  }
}

Color _corNivel(AppColors c, String nivel) => switch (nivel) {
      'começando' => c.muted,
      'avançando' => c.warn,
      'consolidando' => c.primary,
      'dominando' => c.goal,
      _ => c.muted,
    };

String _labelDimensao(String dimensao) => switch (dimensao) {
      'vocabulario' => 'VOCABULÁRIO',
      'ortografia' => 'ORTOGRAFIA',
      'coesao' => 'COESÃO',
      'estrutura' => 'ESTRUTURA',
      'adequacao_ao_tema' => 'ADEQUAÇÃO AO TEMA',
      _ => dimensao.toUpperCase(),
    };

String _capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _dataCurta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';
