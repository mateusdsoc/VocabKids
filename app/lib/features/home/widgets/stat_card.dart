import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/surface_card.dart';
import '../home_data.dart';

/// Bloco consolidado do topo: **palavras dominadas** (o número que importa),
/// **nível + barra de XP**, e a **meta da semana** — tudo num só card para
/// parecer "menos informação", como pedido no refino.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Dominadas(value: data.wordsMastered),
                const SizedBox(width: 16),
                VerticalDivider(width: 1, thickness: 1, color: c.line),
                const SizedBox(width: 16),
                Expanded(child: _NivelXp(data: data)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MetaSemana(goal: data.weeklyGoal),
        ],
      ),
    );
  }
}

class _Dominadas extends StatelessWidget {
  const _Dominadas({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: AppType.fredoka(size: 38, color: c.primary, height: 0.9),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 92,
          child: Text(
            'palavras dominadas',
            style: AppType.nunito(
                size: 10.5, weight: FontWeight.w800, color: c.muted, height: 1.15),
          ),
        ),
      ],
    );
  }
}

class _NivelXp extends StatelessWidget {
  const _NivelXp({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Nível ${data.level}',
              style: AppType.fredoka(
                  size: 15, weight: FontWeight.w500, color: c.ink),
            ),
            const Spacer(),
            Text(
              '${milhar(data.xpCurrent)} / ${milhar(data.xpTarget)} XP',
              style: AppType.nunito(
                  size: 11, weight: FontWeight.w800, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(value: data.xpFraction, color: c.xp, gradient: true),
      ],
    );
  }
}

class _MetaSemana extends StatelessWidget {
  const _MetaSemana({required this.goal});
  final WeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        // Faixa colorida discreta: goal sobre o papel.
        color: Color.alphaBlend(c.goal.withValues(alpha: 0.14), c.paper),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.goal,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: c.goal.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(AppIcons.meta, size: 17, color: c.onGoal),
          ),
          const SizedBox(width: 10),
          Text(
            'Meta da semana',
            style:
                AppType.fredoka(size: 13, weight: FontWeight.w500, color: c.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProgressBar(
              value: goal.fraction,
              color: c.goal,
              trackColor: Color.alphaBlend(c.goal.withValues(alpha: 0.22), c.paper),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: c.goal,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${goal.current}/${goal.target}',
              style: AppType.fredoka(
                  size: 12.5, weight: FontWeight.w600, color: c.onGoal),
            ),
          ),
        ],
      ),
    );
  }
}
