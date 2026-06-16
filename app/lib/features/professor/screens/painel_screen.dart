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
import '../widgets/scope_toggle.dart';
import 'aluno_screen.dart';
import 'atribuir_redacao_screen.dart';
import 'meta_semanal_screen.dart';

/// **Painel** (telas §8.2) com **toggle de escopo** (produto §3.11):
/// - **Minha turma** (professor): KPIs + sinal + alunos, com ações de configurar.
/// - **Escola** (coordenador): agregado por turmas, **só leitura**.
/// Cliente fino: observa os providers e renderiza. Tocar num aluno abre o
/// **detalhe** (drill-down — fase 3); "Atribuir redação" (fase 4) e "Meta
/// semanal" (fase 5) abrem suas telas de configurar (só no escopo turma).
class PainelScreen extends ConsumerWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(professorScopeProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ScopeToggle(
              scope: scope,
              onChanged: (s) =>
                  ref.read(professorScopeProvider.notifier).set(s),
            ),
          ),
        ),
        Expanded(
          child: scope == ProfessorScope.turma
              ? const _TurmaView()
              : const _EscolaView(),
        ),
      ],
    );
  }
}

// --- Escopo: Minha turma ----------------------------------------------------

class _TurmaView extends ConsumerWidget {
  const _TurmaView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(painelTurmaProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => _Erro(onRetry: () => ref.invalidate(painelTurmaProvider)),
      data: (data) => _TurmaBody(data: data),
    );
  }
}

class _TurmaBody extends ConsumerWidget {
  const _TurmaBody({required this.data});
  final PainelData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final turmas = ref.watch(turmasProvider);
    final selecionada = ref.watch(turmaSelecionadaProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        turmas.maybeWhen(
          data: (lista) => lista.length > 1
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TurmaSelector(
                    turmas: lista,
                    selecionada: selecionada ?? lista.first.id,
                    onSelect: (id) =>
                        ref.read(turmaSelecionadaProvider.notifier).set(id),
                  ),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        Entrance(
          child: Text('Turma ${data.turmaNome}',
              style: AppType.fredoka(size: 26, color: c.ink)),
        ),
        const SizedBox(height: 4),
        Text('${data.anoEscolar}º ano · acompanhamento da turma',
            style: AppType.nunito(
                size: 14, weight: FontWeight.w600, color: c.muted)),
        const SizedBox(height: 16),
        // Ações de configurar — exclusivas do escopo turma (ver≠configurar, §3.11).
        Entrance(
          delay: const Duration(milliseconds: 40),
          child: _AcoesTurma(
            turmaId: data.turmaId,
            turmaNome: data.turmaNome,
            metaAtual: data.metaSemanal,
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 80),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Kpi(label: 'Alunos ativos', valor: '${data.alunosAtivos}', sub: 'de ${data.alunosTotal}', cor: c.primary),
              _Kpi(label: 'Palavras dominadas', valor: '${data.palavrasDominadasSemana}', sub: 'nesta semana', cor: c.goal),
              _Kpi(label: 'Meta semanal', valor: '${data.metaSemanal}', sub: 'palavras / aluno', cor: c.accentStrong),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 140),
          child: _SinalCard(
            titulo: 'Sinal de turma',
            descricao:
                'Palavras que a turma mais repete ou evita — entram na trilha de todos.',
            palavras: data.sinalTurma,
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 200),
          child: _Alunos(
            alunos: data.alunos,
            onAbrir: (a) => Navigator.of(context)
                .push(AlunoDetalheScreen.route(a.id, a.nome)),
          ),
        ),
      ],
    );
  }
}

class _TurmaSelector extends StatelessWidget {
  const _TurmaSelector({
    required this.turmas,
    required this.selecionada,
    required this.onSelect,
  });

  final List<TurmaRef> turmas;
  final int selecionada;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in turmas)
          _Chip(
            label: t.nome,
            selected: t.id == selecionada,
            onTap: () => onSelect(t.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(999);
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.14) : c.paper,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
                color: selected ? c.primary.withValues(alpha: 0.5) : c.line),
          ),
          child: Text(label,
              style: AppType.nunito(
                  size: 13,
                  weight: FontWeight.w700,
                  color: selected ? c.ink : c.muted)),
        ),
      ),
    );
  }
}

class _AcoesTurma extends StatelessWidget {
  const _AcoesTurma({
    required this.turmaId,
    required this.turmaNome,
    required this.metaAtual,
  });
  final int turmaId;
  final String turmaNome;
  final int metaAtual;

  @override
  Widget build(BuildContext context) {
    // Ações exclusivas do escopo turma (somem no escopo escola — ver≠configurar).
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _AcaoChip(
            icon: AppIcons.meta,
            label: 'Meta semanal',
            onTap: () => _abrirMeta(context)),
        _AcaoChip(
            icon: AppIcons.redacao,
            label: 'Atribuir redação',
            onTap: () => _abrirAtribuir(context)),
      ],
    );
  }

  Future<void> _abrirMeta(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nova = await Navigator.of(context).push(
      MetaSemanalScreen.route(
          turmaId: turmaId, turmaNome: turmaNome, metaAtual: metaAtual),
    );
    if (nova == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(
              'Meta de $turmaNome atualizada para $nova palavras/semana')));
  }

  Future<void> _abrirAtribuir(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final atribuida = await Navigator.of(context).push(
      AtribuirRedacaoScreen.route(turmaId: turmaId, turmaNome: turmaNome),
    );
    if (atribuida == null) return;
    final prazo = atribuida.prazoCurto;
    final quando = prazo == null ? 'sem prazo' : 'entrega até $prazo';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(
              'Redação "${atribuida.tema}" atribuída a $turmaNome · $quando')));
  }
}

class _AcaoChip extends StatelessWidget {
  const _AcaoChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12);
    return Material(
      color: c.primary.withValues(alpha: 0.10),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Text(label,
                  style: AppType.nunito(
                      size: 13.5, weight: FontWeight.w700, color: c.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Escopo: Escola (coordenador, só leitura) -------------------------------

class _EscolaView extends ConsumerWidget {
  const _EscolaView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(painelEscolaProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) =>
          _Erro(onRetry: () => ref.invalidate(painelEscolaProvider)),
      data: (data) => _EscolaBody(data: data),
    );
  }
}

class _EscolaBody extends ConsumerWidget {
  const _EscolaBody({required this.data});
  final EscolaPainelData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        Entrance(
          child: Row(
            children: [
              Flexible(
                child: Text(data.escolaNome,
                    style: AppType.fredoka(size: 26, color: c.ink),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 10),
              const _SomenteLeituraBadge(),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Visão da coordenação · ${data.turmasTotal} turmas',
            style: AppType.nunito(
                size: 14, weight: FontWeight.w600, color: c.muted)),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 80),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Kpi(label: 'Turmas', valor: '${data.turmasTotal}', sub: 'na escola', cor: c.primary),
              _Kpi(label: 'Alunos ativos', valor: '${data.alunosAtivos}', sub: 'de ${data.alunosTotal}', cor: c.goal),
              _Kpi(label: 'Palavras dominadas', valor: '${data.palavrasDominadasSemana}', sub: 'nesta semana', cor: c.accentStrong),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 140),
          child: _SinalCard(
            titulo: 'Sinal da escola',
            descricao:
                'Palavras fracas recorrentes em várias turmas — leitura pedagógica do conjunto.',
            palavras: data.sinalEscola,
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 200),
          child: _Turmas(
            turmas: data.turmas,
            onAbrir: (id) {
              ref.read(turmaSelecionadaProvider.notifier).set(id);
              ref.read(professorScopeProvider.notifier).set(ProfessorScope.turma);
            },
          ),
        ),
      ],
    );
  }
}

class _SomenteLeituraBadge extends StatelessWidget {
  const _SomenteLeituraBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.muted.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.lock, size: 13, color: c.muted),
          const SizedBox(width: 5),
          Text('somente leitura',
              style: AppType.nunito(
                  size: 11.5, weight: FontWeight.w700, color: c.muted)),
        ],
      ),
    );
  }
}

class _Turmas extends StatelessWidget {
  const _Turmas({required this.turmas, required this.onAbrir});
  final List<TurmaLinha> turmas;
  final ValueChanged<int> onAbrir;

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
                Text('Turmas', style: AppType.fredoka(size: 18, color: c.ink)),
                const Spacer(),
                Text('${turmas.length}',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
          for (final t in turmas) _TurmaRow(turma: t, onTap: () => onAbrir(t.id)),
        ],
      ),
    );
  }
}

class _TurmaRow extends StatelessWidget {
  const _TurmaRow({required this.turma, required this.onTap});
  final TurmaLinha turma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turma.nome,
                      style: AppType.nunito(
                          size: 14.5, weight: FontWeight.w700, color: c.ink)),
                  Text('${turma.alunosAtivos}/${turma.alunosTotal} ativos · ${turma.palavrasDominadasSemana} palavras',
                      style: AppType.nunito(
                          size: 12, weight: FontWeight.w600, color: c.muted)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ProgressBar(value: turma.ativosFraction, color: c.primary),
            ),
            const SizedBox(width: 8),
            Icon(AppIcons.chevron, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }
}

// --- Compartilhados ---------------------------------------------------------

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
      width: 220,
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

class _SinalCard extends StatelessWidget {
  const _SinalCard({
    required this.titulo,
    required this.descricao,
    required this.palavras,
  });

  final String titulo;
  final String descricao;
  final List<String> palavras;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppType.fredoka(size: 18, color: c.ink)),
          const SizedBox(height: 4),
          Text(descricao,
              style: AppType.nunito(
                  size: 13, weight: FontWeight.w600, color: c.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in palavras)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.warn.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.warn.withValues(alpha: 0.4)),
                  ),
                  child: Text(p,
                      style: AppType.nunito(
                          size: 13, weight: FontWeight.w700, color: c.ink)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Alunos extends StatelessWidget {
  const _Alunos({required this.alunos, required this.onAbrir});
  final List<AlunoLinha> alunos;
  final ValueChanged<AlunoLinha> onAbrir;

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
                Text('Alunos', style: AppType.fredoka(size: 18, color: c.ink)),
                const Spacer(),
                Text('${alunos.length}',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
          for (final a in alunos)
            _AlunoRow(aluno: a, onTap: () => onAbrir(a)),
        ],
      ),
    );
  }
}

class _AlunoRow extends StatelessWidget {
  const _AlunoRow({required this.aluno, required this.onTap});
  final AlunoLinha aluno;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: c.avatarGradient),
              ),
              child: Text(aluno.nome.isEmpty ? '?' : aluno.nome[0],
                  style: AppType.fredoka(size: 15, color: c.onPrimary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(aluno.nome,
                  style: AppType.nunito(
                      size: 14.5, weight: FontWeight.w700, color: c.ink),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: ProgressBar(
                      value: aluno.metaFraction,
                      color: aluno.metaCumprida ? c.goal : c.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    child: Text('${aluno.palavrasSemana}/${aluno.metaSemana}',
                        textAlign: TextAlign.right,
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: c.muted)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(AppIcons.chevron, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: c.muted),
          const SizedBox(height: 12),
          Text('Não consegui carregar o painel.',
              style: AppType.fredoka(size: 17, color: c.ink)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
            ),
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
