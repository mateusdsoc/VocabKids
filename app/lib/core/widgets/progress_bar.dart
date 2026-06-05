import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de progresso fina e arredondada, reutilizada em três contextos
/// (XP do nível, meta da semana, progresso da lição). Centraliza a aparência
/// para que todas tenham o mesmo trilho/raio; só mudam cor, altura e fração.
///
/// [value] é clampeado em 0..1. Quando [gradient] é true, o preenchimento
/// ganha um leve degradê (clareando para a direita), como no mockup do XP.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.trackColor,
    this.height = 9,
    this.gradient = false,
  });

  final double value;
  final Color color;
  final Color? trackColor;
  final double height;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height / 2 + 1);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: trackColor ?? context.colors.track,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction == 0 ? 0.0001 : fraction,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: gradient ? null : color,
                gradient: gradient
                    ? LinearGradient(
                        colors: [color, Color.lerp(color, Colors.white, 0.4)!],
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
