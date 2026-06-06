import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_icons.dart';
import '../sessao/session_screen.dart';
import 'home_data.dart';
import 'home_providers.dart';
import 'widgets/continue_card.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/quick_actions.dart';
import 'widgets/stat_card.dart';
import 'widgets/trilha_ribbon.dart';

/// Home-hub (produto 3.7) — hub ao abrir o app, com a prática a um toque.
///
/// É um cliente fino: observa [homeDataProvider] e renderiza. A composição é
/// feita por widgets de feature pequenos (topbar, stat card, continue, trilha,
/// atalhos), todos sobre os componentes reutilizáveis do core.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  static const _destinations = [
    NavDestination(icon: AppIcons.home, label: 'Início'),
    NavDestination(icon: AppIcons.map, label: 'Trilha'),
    NavDestination(icon: AppIcons.praticar, label: 'Praticar'),
    NavDestination(icon: AppIcons.eventos, label: 'Eventos'),
    NavDestination(icon: AppIcons.perfil, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(homeDataProvider);

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: async.when(
                  loading: () => const _Loading(),
                  error: (e, _) => _ErrorView(
                    onRetry: () => ref.invalidate(homeDataProvider),
                  ),
                  data: (data) => _Content(
                    data: data,
                    onRefresh: () async {
                      ref.invalidate(homeDataProvider);
                      await ref.read(homeDataProvider.future);
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: AppBottomNav(
                    destinations: _destinations,
                    currentIndex: _navIndex,
                    onSelect: (i) {
                      // "Praticar" abre a Sessão; as demais abas são visuais
                      // por enquanto.
                      if (i == 2) {
                        _abrirSessao(context);
                      } else {
                        setState(() => _navIndex = i);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.onRefresh});

  final HomeData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.colors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppGaps.screenH, 8, AppGaps.screenH, 104),
        children: [
          HomeTopBar(
            name: data.studentName,
            initial: data.avatarInitial,
            onAvatarTap: () => _emBreve(context, 'Passaporte'),
            onPassportTap: () => _emBreve(context, 'Passaporte'),
          ),
          const SizedBox(height: AppGaps.section),
          StatCard(data: data),
          const SizedBox(height: AppGaps.section),
          ContinueCard(
            lesson: data.lesson,
            onTap: () => _abrirSessao(context),
          ),
          const SizedBox(height: AppGaps.section),
          TrilhaRibbon(
            nodes: data.trail,
            onSeeMap: () => _emBreve(context, 'Mapa da trilha'),
          ),
          const SizedBox(height: AppGaps.section),
          QuickActions(
            onRedacao: () => _emBreve(context, 'Redação'),
            onEventos: () => _emBreve(context, 'Eventos'),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    // Adaptativo: spinner Cupertino no iOS, Material no Android.
    return Center(
      child: CircularProgressIndicator.adaptive(
        valueColor: AlwaysStoppedAnimation(context.colors.primary),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: c.muted),
            const SizedBox(height: 14),
            Text(
              'Não consegui carregar sua jornada.',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 17, color: c.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Confira a conexão e tente de novo.',
              textAlign: TextAlign.center,
              style: AppType.nunito(
                  size: 13, weight: FontWeight.w600, color: c.muted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
              ),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

void _abrirSessao(BuildContext context) {
  Navigator.of(context).push(
    adaptivePageRoute(builder: (_) => const SessionScreen()),
  );
}

void _emBreve(BuildContext context, String label) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$label — em breve')));
}
