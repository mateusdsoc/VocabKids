import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../professor_providers.dart';

/// Segmented control do escopo (produto §3.11): "Minha turma" (professor) ↔
/// "Escola" (coordenador, só leitura). Reusa os tokens da marca.
class ScopeToggle extends StatelessWidget {
  const ScopeToggle({super.key, required this.scope, required this.onChanged});

  final ProfessorScope scope;
  final ValueChanged<ProfessorScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Minha turma',
            icon: Icons.groups_outlined,
            selected: scope == ProfessorScope.turma,
            onTap: () => onChanged(ProfessorScope.turma),
          ),
          _Segment(
            label: 'Escola',
            icon: Icons.apartment_outlined,
            selected: scope == ProfessorScope.escola,
            onTap: () => onChanged(ProfessorScope.escola),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(10);
    final fg = selected ? c.onPrimary : c.muted;
    return Material(
      color: selected ? c.primary : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 7),
              Text(label,
                  style: AppType.nunito(
                      size: 13.5, weight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
