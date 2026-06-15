import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/surface_card.dart';
import '../professor_providers.dart';
import '../widgets/back_bar.dart';

/// **Meta semanal** (telas §8.2; produto §3.5) — ação **só do professor**
/// (ver≠configurar, §3.11). Configura a meta da turma em **palavras dominadas
/// por semana, por aluno**. Pré-preenche com a meta atual; devolve a nova via
/// `Navigator.pop`. DEMO simula o sucesso (sem backend).
class MetaSemanalScreen extends ConsumerStatefulWidget {
  const MetaSemanalScreen({
    super.key,
    required this.turmaId,
    required this.turmaNome,
    required this.metaAtual,
  });

  final int turmaId;
  final String turmaNome;
  final int metaAtual;

  static const double _maxWidth = 680;
  static const int _min = 1;
  static const int _max = 30;

  static Route<int> route({
    required int turmaId,
    required String turmaNome,
    required int metaAtual,
  }) =>
      MaterialPageRoute<int>(
        builder: (_) => MetaSemanalScreen(
            turmaId: turmaId, turmaNome: turmaNome, metaAtual: metaAtual),
      );

  @override
  ConsumerState<MetaSemanalScreen> createState() => _MetaSemanalScreenState();
}

class _MetaSemanalScreenState extends ConsumerState<MetaSemanalScreen> {
  late int _meta = widget.metaAtual.clamp(
      MetaSemanalScreen._min, MetaSemanalScreen._max);

  void _ajustar(int delta) {
    final novo = (_meta + delta)
        .clamp(MetaSemanalScreen._min, MetaSemanalScreen._max);
    if (novo != _meta) setState(() => _meta = novo);
  }

  Future<void> _salvar() async {
    final nova = await ref.read(metaProvider.notifier).atualizar(
          turmaId: widget.turmaId,
          metaSemanal: _meta,
        );
    if (!mounted) return;
    if (nova != null) {
      Navigator.of(context).pop(nova);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Não consegui salvar. Tente de novo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enviando = ref.watch(metaProvider).isLoading;
    final mudou = _meta != widget.metaAtual;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: MetaSemanalScreen._maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfessorBackBar(
                  onBack:
                      enviando ? () {} : () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
                    children: [
                      Entrance(child: _Cabecalho(turmaNome: widget.turmaNome)),
                      const SizedBox(height: 20),
                      Entrance(
                        delay: const Duration(milliseconds: 60),
                        child: _Stepper(
                          meta: _meta,
                          habilitado: !enviando,
                          noMinimo: _meta <= MetaSemanalScreen._min,
                          noMaximo: _meta >= MetaSemanalScreen._max,
                          onMenos: () => _ajustar(-1),
                          onMais: () => _ajustar(1),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Entrance(
                        delay: const Duration(milliseconds: 120),
                        child: _BotaoSalvar(
                          enviando: enviando,
                          onPressed: mudou && !enviando ? _salvar : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Medida em palavras dominadas por semana — concreta e '
                        'pedagógica (§3.5). Cumprir aparece na home do aluno, sem '
                        'virar colecionável. Há um padrão por ano; ajuste se quiser.',
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: c.muted),
                      ),
                    ],
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

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.turmaNome});
  final String turmaNome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meta semanal', style: AppType.fredoka(size: 25, color: c.ink)),
        const SizedBox(height: 4),
        Text('Turma $turmaNome · palavras dominadas por semana',
            style: AppType.nunito(
                size: 14, weight: FontWeight.w600, color: c.muted)),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.meta,
    required this.habilitado,
    required this.noMinimo,
    required this.noMaximo,
    required this.onMenos,
    required this.onMais,
  });

  final int meta;
  final bool habilitado;
  final bool noMinimo;
  final bool noMaximo;
  final VoidCallback onMenos;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      child: Column(
        children: [
          Text('META POR ALUNO', style: AppType.mono(size: 10, color: c.muted)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BotaoPasso(
                icon: AppIcons.minus,
                onTap: habilitado && !noMinimo ? onMenos : null,
              ),
              SizedBox(
                width: 120,
                child: Text('$meta',
                    textAlign: TextAlign.center,
                    style: AppType.fredoka(size: 56, color: c.primary)),
              ),
              _BotaoPasso(
                icon: AppIcons.add,
                onTap: habilitado && !noMaximo ? onMais : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('palavras / semana',
              style: AppType.nunito(
                  size: 13, weight: FontWeight.w600, color: c.muted)),
        ],
      ),
    );
  }
}

class _BotaoPasso extends StatelessWidget {
  const _BotaoPasso({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ativo = onTap != null;
    return Material(
      color: ativo ? c.primary.withValues(alpha: 0.12) : c.track,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon,
              size: 28, color: ativo ? c.primary : c.muted),
        ),
      ),
    );
  }
}

class _BotaoSalvar extends StatelessWidget {
  const _BotaoSalvar({required this.enviando, required this.onPressed});
  final bool enviando;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.4),
          disabledForegroundColor: c.onPrimary.withValues(alpha: 0.8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: enviando
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: c.onPrimary),
              )
            : Text('Salvar meta',
                style: AppType.nunito(
                    size: 15.5, weight: FontWeight.w800, color: c.onPrimary)),
      ),
    );
  }
}
