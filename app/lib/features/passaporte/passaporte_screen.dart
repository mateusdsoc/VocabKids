import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import 'conquista_queue.dart';
import 'conquista_screen.dart';
import 'passaporte_providers.dart';
import 'variants/journal_view.dart';
import 'widgets/passaporte_background.dart';

/// Passaporte (produto §3.10) — Modo Exploração: a coleção de recompensas
/// (carimbos, cartões-postais, selos) na direção **Caderno de Viagem** (escolha
/// do dono). O Modo Conquista (reveal) vive em `conquista_screen.dart`.
///
/// A coleção vem do servidor ([passaporteProvider]; em `DEMO`, a amostra). Ao
/// carregar, **drena a fila de conquistas pendentes** — a pendência real do
/// servidor (`conquistado && !revelado`): se o aluno terminou sessões e não
/// tocou "Ver no Passaporte" (mesmo em outro dia), os reveals tocam aqui, um
/// de cada vez, antes de mostrar a coleção.
class PassaporteScreen extends ConsumerStatefulWidget {
  const PassaporteScreen({super.key});

  @override
  ConsumerState<PassaporteScreen> createState() => _PassaporteScreenState();
}

class _PassaporteScreenState extends ConsumerState<PassaporteScreen> {
  /// O reveal dispara uma única vez por abertura (não repete ao voltar dele).
  bool _drenou = false;

  void _drenarFila() {
    if (_drenou) return;
    _drenou = true;
    // Pós-frame: empurra o Modo Conquista por cima desta tela (que fica
    // pronta por baixo).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fila = ConquistaQueue.instance.pendentes;
      if (fila.isNotEmpty) {
        Navigator.of(context).push(ConquistaScreen.route(fila));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final carregado = ref.watch(passaporteProvider);

    if (carregado.hasValue) _drenarFila();

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
                  child: carregado.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _Erro(
                        onTentarDeNovo: () =>
                            ref.invalidate(passaporteProvider)),
                    data: (dados) =>
                        _Reveal(child: JournalView(p: dados.passaporte)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Falha ao carregar a coleção: mensagem gentil + tentar de novo.
class _Erro extends StatelessWidget {
  const _Erro({required this.onTentarDeNovo});
  final VoidCallback onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Não deu para abrir o Passaporte',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 22, color: c.ink)),
          const SizedBox(height: 8),
          Text('Confira sua conexão e tente de novo.',
              textAlign: TextAlign.center,
              style: AppType.nunito(
                  size: 15, weight: FontWeight.w600, color: c.muted)),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Tentar de novo', onTap: onTentarDeNovo),
        ],
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
