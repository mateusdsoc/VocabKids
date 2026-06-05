import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';

/// Topo da Home: avatar com anel, saudação ("Bom te ver, <nome>") e o selo
/// **Passaporte** em destaque (pílula preenchida na cor primária).
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.name,
    required this.initial,
    this.onAvatarTap,
    this.onPassportTap,
  });

  final String name;
  final String initial;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onPassportTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        _Avatar(initial: initial, onTap: onAvatarTap),
        const SizedBox(width: 11),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bom te ver,',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.nunito(
                    size: 11.5, weight: FontWeight.w800, color: c.muted),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.fredoka(size: 21, color: c.ink, height: 1.12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _PassportChip(onTap: onPassportTap),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.onTap});

  final String initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Anel decorativo separado do avatar por um respiro do fundo.
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.ring, width: 1.5),
        ),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: c.avatarGradient,
            ),
          ),
          child: Text(
            initial,
            style: AppType.fredoka(size: 19, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PassportChip extends StatelessWidget {
  const _PassportChip({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 9),
                spreadRadius: -7,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.passaporte, size: 19, color: c.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Passaporte',
                style: AppType.caveat(size: 19, color: c.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
