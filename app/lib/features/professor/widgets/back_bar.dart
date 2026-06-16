import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';

/// Barra superior de "voltar" das páginas empurradas do professor (detalhe do
/// aluno, atribuir redação). Centralizada para que o afford de volta seja
/// idêntico em todas. Reusa os tokens da marca.
class ProfessorBackBar extends StatelessWidget {
  const ProfessorBackBar({
    super.key,
    required this.onBack,
    this.label = 'Voltar ao painel',
  });

  final VoidCallback onBack;
  final String label;

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
                  Text(label,
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
