import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../analise.dart';
import 'dimensao_chip.dart';

/// Abre a dica de uma anotação como folha inferior — o aluno tocou num trecho
/// sublinhado e quer entender o porquê. Tom de apoio (nunca punitivo).
Future<void> mostrarAnotacaoSheet(BuildContext context, Anotacao a) {
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _AnotacaoSheet(anotacao: a),
  );
}

class _AnotacaoSheet extends StatelessWidget {
  const _AnotacaoSheet({required this.anotacao});

  final Anotacao anotacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cor = anotacao.dimensao.cor(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: c.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            DimensaoChip(dimensao: anotacao.dimensao),
            const SizedBox(height: 12),
            Text(anotacao.titulo,
                style: AppType.fredoka(size: 19, color: c.ink, height: 1.15)),
            const SizedBox(height: 8),
            Text(anotacao.comentario,
                style: AppType.nunito(
                    size: 14, weight: FontWeight.w600, color: c.muted, height: 1.5)),
            if (anotacao.sugestoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('SUGESTÕES',
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
                  for (final s in anotacao.sugestoes)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: cor.withValues(alpha: 0.32), width: 1),
                      ),
                      child: Text(s,
                          style: AppType.nunito(
                              size: 13.5, weight: FontWeight.w800, color: cor)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
