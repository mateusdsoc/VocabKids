import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_icons.dart';
import '../sessao/session_screen.dart';
import 'models.dart';
import 'widgets/country_stamp.dart';
import 'widgets/trilha_map.dart';

/// Trilha (mapa) — aterrissagem pós-sessão (produto 3.7). Porte do design
/// `Refino/Vocab - Trilha (mapa) v5 escuro` (variação B · Capa do Passaporte).
///
/// Profundidade por relevo (gradientes + sombras + aba inferior), nós como
/// pontos tocáveis, e a recompensa **não** se revela aqui — fica embaçada até o
/// Passaporte. **Sem bob/flutuação contínua no nó atual** (decisão do dono,
/// 11/06): o destaque é estático (maior + anel + halo).
///
/// [celebrarChegada] toca a animação de **completar nó** ao aterrissar (o
/// trecho verde se desenha, o pin pipoca com confete e assenta) — passado
/// pelo "Ver trilha" do Resumo. Abrir pela Home/nav fica estático. Com o
/// backend, o gatilho real será "completou nó nesta sessão" (hoje, demo:
/// toda vinda do Resumo celebra). Respeita reduce-motion.
class TrilhaScreen extends StatefulWidget {
  const TrilhaScreen({
    super.key,
    this.data = TrilhaMapData.sample,
    this.celebrarChegada = false,
  });

  final TrilhaMapData data;
  final bool celebrarChegada;

  @override
  State<TrilhaScreen> createState() => _TrilhaScreenState();
}

class _TrilhaScreenState extends State<TrilhaScreen>
    with SingleTickerProviderStateMixin {
  static const _destinations = [
    NavDestination(icon: AppIcons.home, label: 'Início'),
    NavDestination(icon: AppIcons.map, label: 'Trilha'),
    NavDestination(icon: AppIcons.praticar, label: 'Praticar'),
    NavDestination(icon: AppIcons.eventos, label: 'Eventos'),
    NavDestination(icon: AppIcons.perfil, label: 'Perfil'),
  ];

  late final AnimationController _chegada = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  bool _arrancou = false;
  bool _hapticDado = false;
  bool _reduzido = false;

  @override
  void initState() {
    super.initState();
    // Haptic leve no instante do pop do pin (~55% da coreografia).
    _chegada.addListener(() {
      if (!_hapticDado && _chegada.value >= 0.55) {
        _hapticDado = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancou) return;
    _arrancou = true;
    _reduzido = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.celebrarChegada || _reduzido) {
      _hapticDado = true;
      _chegada.value = 1; // estado final, sem animação
    } else {
      // Pequena espera para a transição da rota assentar antes do desenho.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _chegada.forward();
      });
    }
  }

  @override
  void dispose() {
    _chegada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = widget.data;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.bg,
        body: _Background(
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    _Header(data: data),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: TrilhaMap(
                          data: data,
                          chegada: widget.celebrarChegada && !_reduzido
                              ? _chegada
                              : null,
                          onContinue: () => Navigator.of(context).push(
                            adaptivePageRoute(
                                builder: (_) => const SessionScreen()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: AppBottomNav(
                      destinations: _destinations,
                      currentIndex: 1,
                      onSelect: (i) {
                        if (i == 0) {
                          Navigator.of(context).maybePop();
                        } else if (i == 2) {
                          Navigator.of(context).push(adaptivePageRoute(
                              builder: (_) => const SessionScreen()));
                        }
                      },
                    ),
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

/// Cabeçalho: título + nível/XP e o carimbo do país.
class _Header extends StatelessWidget {
  const _Header({required this.data});
  final TrilhaMapData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trilha',
                  style: AppType.fredoka(
                      size: 25, weight: FontWeight.w600, color: c.ink, height: 1)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Nível ${data.level}',
                      style: AppType.fredoka(
                          size: 14, weight: FontWeight.w600, color: c.primary)),
                  Text('${milhar(data.xpCurrent)} / ${milhar(data.xpTarget)} XP',
                      style: AppType.mono(
                          size: 10,
                          weight: FontWeight.w400,
                          letterSpacing: 0.4,
                          color: c.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          CountryStamp(country: data.country),
        ],
      ),
    );
  }
}

/// Fundo navy "Capa do Passaporte": glow azul no topo + amanhecer dourado
/// embaixo (variação B). No claro, fica só a areia.
class _Background extends StatelessWidget {
  const _Background({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.bg),
      child: Stack(
        children: [
          if (dark) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -1),
                    radius: 1.3,
                    colors: [c.primary.withValues(alpha: 0.24), c.primary.withValues(alpha: 0)],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.4, 1),
                    radius: 1.4,
                    colors: [c.accent.withValues(alpha: 0.26), c.accent.withValues(alpha: 0)],
                    stops: const [0, 0.65],
                  ),
                ),
              ),
            ),
          ],
          // Banhos de cor + textura cartográfica cobrindo a tela inteira.
          const Positioned.fill(child: TrilhaBackdrop()),
          child,
        ],
      ),
    );
  }
}
