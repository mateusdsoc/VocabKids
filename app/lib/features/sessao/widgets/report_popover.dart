import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Overlay de report: escurece a tela e abre um popover com motivos
/// predefinidos, ancorado abaixo do botão de bandeira. Reportar não pula a
/// questão nem dá XP (mock na fatia A).
class ReportPopover extends StatelessWidget {
  const ReportPopover({
    super.key,
    required this.reasons,
    required this.onClose,
    required this.onSelect,
  });

  final List<String> reasons;
  final VoidCallback onClose;

  /// Recebe o índice do motivo em [reasons] (o chamador mapeia para o código).
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: const Color(0x29140E08)),
          ),
        ),
        Positioned(
          top: 50,
          right: 15,
          child: Container(
            width: 224,
            padding: const EdgeInsets.fromLTRB(12, 13, 12, 11),
            decoration: BoxDecoration(
              color: c.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line, width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x73140E08),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                  spreadRadius: -14,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reportar questão',
                    style: AppType.fredoka(
                        size: 14, weight: FontWeight.w600, color: c.ink)),
                const SizedBox(height: 2),
                Text('Não pula a questão nem dá XP.',
                    style: AppType.nunito(
                        size: 10.5, weight: FontWeight.w700, color: c.muted)),
                const SizedBox(height: 9),
                for (var i = 0; i < reasons.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                  _ReasonItem(text: reasons[i], onTap: () => onSelect(i)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonItem extends StatelessWidget {
  const _ReasonItem({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text,
                  style: AppType.nunito(
                      size: 12.5, weight: FontWeight.w700, color: c.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
