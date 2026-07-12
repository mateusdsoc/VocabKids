import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de progresso fina e arredondada, reutilizada em três contextos
/// (XP do nível, meta da semana, progresso da lição). Centraliza a aparência
/// para que todas tenham o mesmo trilho/raio; só mudam cor, altura e fração.
///
/// [value] é clampeado em 0..1. Quando [gradient] é true, o preenchimento
/// ganha um leve degradê (clareando para a direita), como no mockup do XP.
///
/// **Mudanças de [value] são animadas** (encher suave, ~380 ms): a primeira
/// pintura mostra o valor direto — só as atualizações (ex.: avançar questão na
/// Sessão) deslizam até a nova fração.
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
          // Tween com begin == end: o primeiro build não anima; quando [value]
          // muda, o TweenAnimationBuilder anima do valor corrente ao novo end.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: fraction, end: fraction),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            builder: (context, animated, child) => FractionallySizedBox(
              widthFactor: animated <= 0 ? 0.0001 : animated.clamp(0.0, 1.0),
              // Sem heightFactor o DecoratedBox (sem filho) colapsa a altura 0
              // dentro do Align e o preenchimento nunca aparece.
              heightFactor: 1,
              child: child,
            ),
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
