import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Desfoque do "vidro fosco" dos cards translúcidos (claro). Centralizado para
/// que [SurfaceCard] e a barra inferior usem a mesma intensidade.
const double kGlassBlur = 18;

/// Card "papel" base de toda a Home: superfície [AppColors.paper] com a borda
/// hairline interna [AppColors.line] (o `inset 0 0 0 1px` dos mockups) e raio
/// configurável. Reaproveitado pelo stat card, trilha, atalhos, etc., para que
/// a moldura seja idêntica em todos.
///
/// Quando [AppColors.paper] é **translúcido** (cards de vidro do tema claro),
/// o card aplica um [BackdropFilter] para frostar o que está atrás — é isso que
/// dá o efeito de vidro pedido no refino. No escuro o papel é opaco e o desfoque
/// é dispensado automaticamente (sem custo).
///
/// - [onTap]: torna a superfície clicável com ripple recortado ao raio.
/// - [shadow]: para cards que "flutuam" (ex.: o card Continuar).
/// - [clip]: recorta o conteúdo ao raio (necessário quando uma imagem sangra
///   até a borda do card).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.shadow,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = BorderRadius.circular(radius);
    final glass = c.glass.a < 1.0;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: border,
        border: Border.all(color: c.line, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );

    // Vidro: recorta ao raio e desfoca o fundo sob a superfície translúcida.
    if (glass) {
      surface = ClipRRect(
        borderRadius: border,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
          child: surface,
        ),
      );
    } else if (clip) {
      surface = ClipRRect(borderRadius: border, child: surface);
    }

    // A sombra fica por fora do recorte para não ser cortada pelo clip do vidro.
    final box = shadow == null
        ? surface
        : DecoratedBox(
            decoration: BoxDecoration(borderRadius: border, boxShadow: shadow),
            child: surface,
          );

    if (onTap == null) return box;

    return Material(
      type: MaterialType.transparency,
      borderRadius: border,
      child: InkWell(onTap: onTap, borderRadius: border, child: box),
    );
  }
}
