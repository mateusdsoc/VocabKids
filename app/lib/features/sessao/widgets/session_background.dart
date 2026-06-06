import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Fundo "A" da Sessão (direção escolhida no refino): base areia (claro) ou
/// navy (escuro) com um **brilho radial azul** suave no topo. Mais sóbrio que
/// a Home — a tela de prática precisa de foco.
class SessionBackground extends StatelessWidget {
  const SessionBackground({super.key, required this.child});

  final Widget child;

  // Base do Fundo A (ligeiramente diferente do fundo da Home, por decisão de
  // design): areia mais neutra no claro; o navy coincide com o tema escuro.
  static const _baseLight = Color(0xFFF4F0E7);
  static const _baseDark = Color(0xFF172A44);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? _baseDark : _baseLight;
    final glow = c.primary.withValues(alpha: dark ? 0.22 : 0.13);

    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [glow, glow.withValues(alpha: 0)],
                  stops: const [0, 0.58],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
