import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card "papel" base de toda a Home: superfície [AppColors.paper] com a borda
/// hairline interna [AppColors.line] (o `inset 0 0 0 1px` dos mockups) e raio
/// configurável. Reaproveitado pelo stat card, trilha, atalhos, etc., para que
/// a moldura seja idêntica em todos.
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

    Widget content = Padding(padding: padding, child: child);
    if (clip) content = ClipRRect(borderRadius: border, child: content);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: border,
        border: Border.all(color: c.line, width: 1),
        boxShadow: shadow,
      ),
      child: content,
    );

    if (onTap == null) return box;

    return Material(
      type: MaterialType.transparency,
      borderRadius: border,
      child: InkWell(onTap: onTap, borderRadius: border, child: box),
    );
  }
}
