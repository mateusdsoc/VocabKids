import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_icons.dart';
import '../home/data/trilha_models.dart';
import '../home/home_screen.dart';
import '../identidade/perfil_screen.dart';
import '../sessao/session_screen.dart';
import 'models.dart';
import 'trilha_mapper.dart';
import 'trilha_providers.dart';
import 'widgets/country_stamp.dart';
import 'widgets/trilha_map.dart';

/// Trilha (mapa) — aterrissagem pós-sessão (produto 3.7). Porte do design
/// `Refino/Vocab - Trilha (mapa) v5 escuro` (variação B · Capa do Passaporte).
///
/// **Janela com template fixo** (decisão do dono, 12/07): o desenho travado
/// (340×540) mostra **um destino por vez** — âncora de contexto embaixo, os
/// 4 nós do destino, prévia do próximo (ou portão do país) em cima. Swipe ou
/// chevrons ao lado do carimbo do país trocam de janela; abre na janela do nó
/// atual. Em `AppConfig.demo`, a janela única de exemplo ([TrilhaMapData.sample]).
///
/// Profundidade por relevo, nós como pontos tocáveis, e a recompensa **não**
/// se revela aqui — fica embaçada até o Passaporte. **Sem bob/flutuação
/// contínua no nó atual** (decisão do dono, 11/06).
///
/// [celebrarChegada] toca a animação de **completar nó** ao aterrissar (o
/// trecho verde se desenha, o pin pipoca com confete e assenta) — passado
/// pelo "Ver trilha" do Resumo quando a sessão de fato fechou um nó. Só toca
/// na janela do destino atual. Respeita reduce-motion.
class TrilhaScreen extends ConsumerStatefulWidget {
  const TrilhaScreen({super.key, this.celebrarChegada = false});

  final bool celebrarChegada;

  @override
  ConsumerState<TrilhaScreen> createState() => _TrilhaScreenState();
}

class _TrilhaScreenState extends ConsumerState<TrilhaScreen>
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

  /// Janela (destino) exibida; criada quando os dados chegam, na janela atual.
  PageController? _paginas;
  int? _pagina;

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
    _paginas?.dispose();
    super.dispose();
  }

  Animation<double>? get _chegadaAtiva =>
      widget.celebrarChegada && !_reduzido ? _chegada : null;

  void _abrirSessao() {
    Navigator.of(context).push(
      adaptivePageRoute(builder: (_) => const SessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                if (AppConfig.demo)
                  _demo()
                else
                  ref.watch(trilhaProvider).when(
                        loading: () => const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                        error: (_, _) => _ErrorView(
                          onRetry: () => ref.invalidate(trilhaProvider),
                        ),
                        data: _mapa,
                      ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(top: false, child: _nav(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Demo: a janela única de exemplo do design, sem paginação.
  Widget _demo() {
    const data = TrilhaMapData.sample;
    return Column(
      children: [
        _Header(data: data),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: TrilhaMap(
              data: data,
              chegada: _chegadaAtiva,
              onContinue: _abrirSessao,
            ),
          ),
        ),
      ],
    );
  }

  /// Mapa real: uma janela por destino, abrindo na do nó atual.
  Widget _mapa(Trilha trilha) {
    final destinos = trilha.destinosEmOrdem;
    if (destinos.isEmpty) {
      return _ErrorView(onRetry: () => ref.invalidate(trilhaProvider));
    }
    final atual = TrilhaMapper.indiceAtual(destinos);
    _paginas ??= PageController(initialPage: atual);
    final pagina = (_pagina ?? atual).clamp(0, destinos.length - 1);
    final janela = TrilhaMapper.janela(trilha, pagina);

    return Column(
      children: [
        _Header(
          data: janela,
          onAnterior: pagina > 0 ? () => _irPara(pagina - 1) : null,
          onProximo:
              pagina < destinos.length - 1 ? () => _irPara(pagina + 1) : null,
        ),
        Expanded(
          child: PageView.builder(
            controller: _paginas,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemCount: destinos.length,
            itemBuilder: (_, i) => Align(
              alignment: Alignment.topCenter,
              child: TrilhaMap(
                data: TrilhaMapper.janela(trilha, i),
                // A celebração pertence à janela do nó atual.
                chegada: i == atual ? _chegadaAtiva : null,
                onContinue: _abrirSessao,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _irPara(int pagina) {
    _paginas?.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  AppBottomNav _nav(BuildContext context) {
    return AppBottomNav(
      destinations: _destinations,
      currentIndex: 1,
      onSelect: (i) {
        if (i == 0) {
          // "Início": volta direto pra Home num toque. A pilha
          // pode ter mais de uma Trilha (Home→Trilha→Sessão→
          // Resumo→Trilha), então `popUntil` em vez de `pop`
          // evita parar numa Trilha intermediária. Para na Home
          // (nomeada no demo) ou na raiz (Home em produção).
          Navigator.of(context).popUntil(
              (r) => r.isFirst || r.settings.name == HomeScreen.routeName);
        } else if (i == 2) {
          _abrirSessao();
        } else if (i == 4) {
          Navigator.of(context).push(
              adaptivePageRoute(builder: (_) => const PerfilScreen()));
        }
      },
    );
  }
}

/// Cabeçalho: título + nível/XP e o carimbo do país da janela, flanqueado
/// pelos chevrons de navegação entre destinos (quando há para onde ir).
class _Header extends StatelessWidget {
  const _Header({required this.data, this.onAnterior, this.onProximo});
  final TrilhaMapData data;
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final comChevrons = onAnterior != null || onProximo != null;
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
          Row(
            children: [
              if (comChevrons) ...[
                _Chevron(icon: AppIcons.back, onTap: onAnterior),
                const SizedBox(width: 8),
              ],
              Expanded(child: CountryStamp(country: data.country)),
              if (comChevrons) ...[
                const SizedBox(width: 8),
                _Chevron(icon: AppIcons.chevron, onTap: onProximo),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão redondo de navegação entre janelas (desabilitado nas pontas).
class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ativo = onTap != null;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.alphaBlend(c.paper, c.bg),
            border: Border.all(color: c.line, width: 1),
          ),
          child: Icon(icon,
              size: 22,
              color: ativo ? c.ink : c.muted.withValues(alpha: 0.45)),
        ),
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
              'Não consegui carregar o mapa.',
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
