import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import 'models.dart';
import 'variants/journal_view.dart';
import 'widgets/passaporte_background.dart';

/// Passaporte (produto §3.10) — Modo Exploração: a coleção de recompensas
/// (carimbos, cartões-postais, selos) na direção **Caderno de Viagem** (escolha
/// do dono). O Modo Conquista (reveal pós-Resumo) vive em
/// `conquista_screen.dart` e aterrissa aqui ao "guardar" o item.
class PassaporteScreen extends StatelessWidget {
  const PassaporteScreen({super.key, this.passaporte = Passaporte.sample});

  final Passaporte passaporte;

  @override
  Widget build(BuildContext context) {
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: PassaporteBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 8, 17, 10),
                  child: _TopBar(onBack: () => Navigator.of(context).maybePop()),
                ),
                Expanded(
                  child: _Reveal(child: JournalView(p: passaporte)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Topo: voltar + selo manuscrito "Passaporte".
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: c.glass,
              shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(AppIcons.back, size: 24, color: c.ink),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.passaporte, size: 18, color: c.accentStrong),
              const SizedBox(width: 7),
              Text('Passaporte', style: AppType.caveat(size: 24, color: c.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Entrada suave (fade + leve subida) ao montar.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}
