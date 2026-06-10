import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import 'models.dart';
import 'passaporte_screen.dart';
import 'widgets/passaporte_background.dart';
import 'widgets/postcard_face.dart';
import 'widgets/seal_badge.dart';

/// Passaporte — **Modo Conquista** (produto §3.10, `telas.md` §7): o reveal
/// que dispara uma única vez após o Resumo, quando há item novo.
///
/// Coreografia (curta e não-bloqueante; o X pula a qualquer momento):
/// 1. o passaporte **sobe** em tela cheia (rota deslizando de baixo);
/// 2. **flip decorativo único** da capa, abrindo direto na página do item
///    (não folheia histórico);
/// 3. o item espera **embaçado** ("toque para revelar" pulsando);
/// 4. toque → revela **nítido** (só aqui — na Trilha continua embaçado),
///    com brilhos dourados, e **encaixa** com uma leve inclinação de
///    "colado no caderno". Selo: cai no grid, pulsa e encaixa; os antigos
///    ficam estáticos.
/// 5. CTA "Ver no Passaporte" aterrissa no Modo Exploração (a tela
///    scrollável), onde a peça está guardada.
///
/// Desempenho: nada de `BackdropFilter`; um único item anima, com transforms
/// (rotate/scale/translate) sob `RepaintBoundary`. O embaçado é um overlay de
/// sigma fixo que só tem a **opacidade** animada e sai da árvore ao terminar.
class ConquistaScreen extends StatefulWidget {
  const ConquistaScreen({super.key, required this.conquista});

  final Conquista conquista;

  /// Rota em tela cheia que **sobe** do rodapé (o "passaporte sobe").
  static Route<void> route(Conquista conquista) => PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => ConquistaScreen(conquista: conquista),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation),
          child: child,
        ),
      );

  @override
  State<ConquistaScreen> createState() => _ConquistaScreenState();
}

enum _Fase { capa, espera, revelando, pronto }

class _ConquistaScreenState extends State<ConquistaScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850));
  late final CurvedAnimation _flipT =
      CurvedAnimation(parent: _flip, curve: Curves.easeInOutCubic);

  /// Pulso do "toque para revelar" (repete em vai-e-vem até o toque).
  late final AnimationController _hint = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  late final AnimationController _reveal = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  _Fase _fase = _Fase.capa;
  Timer? _inicio;

  @override
  void initState() {
    super.initState();
    // Espera a rota terminar de subir antes do flip decorativo único.
    _inicio = Timer(const Duration(milliseconds: 480), () {
      if (mounted) _flip.forward();
    });
    _flip.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _fase = _Fase.espera);
        _hint.repeat(reverse: true);
      }
    });
    _reveal.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _fase = _Fase.pronto);
      }
    });
  }

  @override
  void dispose() {
    _inicio?.cancel();
    _flipT.dispose();
    _flip.dispose();
    _hint.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _revelar() {
    if (_fase != _Fase.espera) return;
    HapticFeedback.mediumImpact();
    _hint.stop();
    setState(() => _fase = _Fase.revelando);
    _reveal.forward();
  }

  void _verPassaporte() {
    Navigator.of(context).pushReplacement(
      adaptivePageRoute(builder: (_) => const PassaporteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pronto = _fase == _Fase.pronto;
    final size = MediaQuery.sizeOf(context);
    final cardW = math.min(320.0, size.width - 44);
    final cardH = math.min(cardW * 1.38, size.height * 0.62);

    return Scaffold(
      body: PassaporteBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    _CloseButton(
                        onTap: () => Navigator.of(context).maybePop()),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _revelar,
                    behavior: HitTestBehavior.opaque,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _flipT,
                        builder: (context, _) => _FlipCard(
                          t: _flipT.value,
                          width: cardW,
                          height: cardH,
                          front: const _CoverFace(),
                          back: _PageFace(
                            conquista: widget.conquista,
                            fase: _fase,
                            reveal: _reveal,
                            hint: _hint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Rodapé com altura reservada: o CTA entra sem pular o layout.
              SizedBox(
                height: 124,
                child: IgnorePointer(
                  ignoring: !pronto,
                  child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (context, child) {
                      final t = const Interval(0.72, 1.0,
                              curve: Curves.easeOutCubic)
                          .transform(_reveal.value);
                      if (t == 0) return const SizedBox.shrink();
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                            offset: Offset(0, 16 * (1 - t)), child: child),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                      child: Column(
                        children: [
                          PrimaryButton(
                            label: 'Ver no Passaporte',
                            leadingIcon: AppIcons.passaporte,
                            onTap: _verPassaporte,
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).maybePop(),
                            child: Text('Voltar ao resumo',
                                style: AppType.nunito(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: context.colors.muted)),
                          ),
                        ],
                      ),
                    ),
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

/// Fechar/pular — disponível o tempo todo (animação nunca prende o aluno).
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.glass,
      shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(AppIcons.close, size: 20, color: c.ink),
        ),
      ),
    );
  }
}

/// Flip 3D de página única: frente até 90°, depois o verso (desespelhado).
/// Um leve mergulho de escala no meio dá peso de "capa virando".
class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.t,
    required this.width,
    required this.height,
    required this.front,
    required this.back,
  });

  final double t;
  final double width;
  final double height;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final angle = t * math.pi;
    final showBack = angle > math.pi / 2;
    final face = showBack
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: back,
          )
        : front;
    return Transform.scale(
      scale: 1 - 0.05 * math.sin(t * math.pi),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(angle),
        child: SizedBox(width: width, height: height, child: face),
      ),
    );
  }
}

/// Capa do passaporte (decorativa — o flip passa por ela uma vez).
class _CoverFace extends StatelessWidget {
  const _CoverFace();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cover = dark
        ? const [Color(0xFF1C2F4B), Color(0xFF0F2034)]
        : [c.primary, Color.lerp(c.primary, Colors.black, 0.22)!];

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border:
              Border.all(color: c.accent.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('PASSAPORTE',
                style: AppType.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 4,
                    color: c.accent)),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: c.accent.withValues(alpha: 0.7), width: 1.6),
              ),
              child: Icon(AppIcons.globe, size: 34, color: c.accent),
            ),
            const SizedBox(height: 18),
            Text('uma nova lembrança',
                style: AppType.caveat(
                    size: 22, color: Colors.white.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

/// A página do item — abre direto nela (não folheia histórico).
class _PageFace extends StatelessWidget {
  const _PageFace({
    required this.conquista,
    required this.fase,
    required this.reveal,
    required this.hint,
  });

  final Conquista conquista;
  final _Fase fase;
  final Animation<double> reveal;
  final Animation<double> hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titulo = switch (conquista) {
      ConquistaPostal() => 'Cartão-postal',
      ConquistaSelo(:final todos, :final novoIndex) => todos[novoIndex].titulo,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text('NOVO NO PASSAPORTE',
              style: AppType.mono(
                  size: 9.5,
                  weight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: c.accentStrong)),
          const SizedBox(height: 4),
          Text(titulo,
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 20, color: c.ink, height: 1.05)),
          const Spacer(),
          switch (conquista) {
            ConquistaPostal(:final destino, :final pais) => _PolaroidReveal(
                destino: destino,
                pais: pais,
                fase: fase,
                reveal: reveal,
              ),
            ConquistaSelo(:final todos, :final novoIndex) => _SeloGridReveal(
                todos: todos,
                novoIndex: novoIndex,
                fase: fase,
                reveal: reveal,
              ),
          },
          const Spacer(),
          // Área do hint com altura fixa (não pula quando some).
          SizedBox(
            height: 26,
            child: fase == _Fase.espera
                ? AnimatedBuilder(
                    animation: hint,
                    builder: (context, child) => Opacity(
                      opacity: 0.55 + 0.45 * hint.value,
                      child: Transform.scale(
                          scale: 1 + 0.04 * hint.value, child: child),
                    ),
                    child: Text('toque para revelar',
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: c.muted)),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Cartão-postal: polaroid grande, embaçada até o toque; revela nítida com
/// brilhos dourados e encaixa com uma leve inclinação de "colada no caderno".
class _PolaroidReveal extends StatelessWidget {
  const _PolaroidReveal({
    required this.destino,
    required this.pais,
    required this.fase,
    required this.reveal,
  });

  final Destino destino;
  final Pais pais;
  final _Fase fase;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final t = reveal.value;
        final desfoque = 1 -
            const Interval(0.0, 0.5, curve: Curves.easeOut).transform(t);
        final pop = math.sin(
            const Interval(0.10, 0.65).transform(t) * math.pi);
        final encaixe = const Interval(0.55, 1.0, curve: Curves.easeOutBack)
            .transform(t);
        final revelado = t > 0.45;

        final face = PostcardFace(
            destino: destino, pais: pais, width: 224, height: 150, radius: 5);

        return Transform.rotate(
          angle: -0.045 * encaixe,
          child: Transform.scale(
            scale: 1 + 0.06 * pop,
            child: Container(
              width: 240,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              decoration: BoxDecoration(
                color: c.paper,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: c.line, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      face,
                      // Embaçado: sigma fixo, só a opacidade anima; sai da
                      // árvore quando o reveal termina (custo zero depois).
                      if (fase != _Fase.pronto && desfoque > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: desfoque.clamp(0.0, 1.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                          sigmaX: 7,
                                          sigmaY: 7,
                                          tileMode: TileMode.decal),
                                      child: face,
                                    ),
                                    ColoredBox(
                                        color: c.paper
                                            .withValues(alpha: 0.28)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Brilhos dourados do reveal.
                      if (t > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _Sparkles(
                                progress: const Interval(0.15, 1.0)
                                    .transform(t),
                                colors: [
                                  c.accent,
                                  c.accentStrong,
                                  Colors.white,
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Fita adesiva (como no caderno do Modo Exploração).
                      Positioned(
                        top: -10,
                        child: Transform.rotate(
                          angle: -0.05,
                          child: Container(
                            width: 52,
                            height: 17,
                            color: c.accent.withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      revelado ? destino.cidade : '? ? ?',
                      key: ValueKey(revelado),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.caveat(
                          size: 22, color: revelado ? c.ink : c.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Selo de feito: grid com os antigos estáticos; o novo **cai** no lugar da
/// silhueta, pulsa e encaixa.
class _SeloGridReveal extends StatelessWidget {
  const _SeloGridReveal({
    required this.todos,
    required this.novoIndex,
    required this.fase,
    required this.reveal,
  });

  final List<Selo> todos;
  final int novoIndex;
  final _Fase fase;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < todos.length; i++)
          SizedBox(
            width: 84,
            child: i == novoIndex
                ? _NovoSelo(selo: todos[i], reveal: reveal)
                : SeloBadge(selo: todos[i], mostrarDescricao: false),
          ),
      ],
    );
  }
}

class _NovoSelo extends StatelessWidget {
  const _NovoSelo({required this.selo, required this.reveal});

  final Selo selo;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    // O "slot" embaixo é a silhueta pontilhada (o selo ainda não ganho).
    final silhueta = Selo(
      titulo: selo.titulo,
      descricao: selo.descricao,
      icone: selo.icone,
      conquistado: false,
    );

    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final t = reveal.value;
        final queda =
            const Interval(0.05, 0.55, curve: Curves.bounceOut).transform(t);
        final entrada = const Interval(0.05, 0.25).transform(t);
        final pulso =
            math.sin(const Interval(0.60, 0.95).transform(t) * math.pi);

        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: (1 - const Interval(0.35, 0.55).transform(t))
                  .clamp(0.0, 1.0),
              child: SeloBadge(selo: silhueta, mostrarDescricao: false),
            ),
            if (t > 0)
              Opacity(
                opacity: entrada.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -72 * (1 - queda)),
                  child: Transform.scale(
                    scale: 1 + 0.15 * pulso,
                    child: SeloBadge(selo: selo, mostrarDescricao: false),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Brilhos dourados do reveal — explosão curta a partir do centro do item,
/// subindo de leve (faíscas, não confete: a cor da conquista é o ouro).
class _Sparkles extends CustomPainter {
  _Sparkles({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  /// (ângulo em voltas, alcance 0..1, raio px, índice de cor, losango?)
  static const _bits = [
    (0.96, 1.00, 3.2, 0, true),
    (0.84, 0.80, 2.4, 2, false),
    (0.70, 0.95, 3.6, 1, true),
    (0.58, 0.75, 2.6, 0, false),
    (0.46, 1.00, 3.0, 2, true),
    (0.34, 0.85, 2.4, 1, false),
    (0.22, 0.95, 3.4, 0, true),
    (0.10, 0.70, 2.6, 2, false),
    (0.90, 0.60, 2.0, 1, false),
    (0.64, 0.55, 2.2, 0, false),
    (0.40, 0.60, 2.0, 1, false),
    (0.16, 0.55, 2.4, 2, true),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final spread = Curves.easeOutCubic.transform(progress);
    final fade = progress < 0.5 ? 1.0 : 1 - (progress - 0.5) / 0.5;
    final center = Offset(size.width / 2, size.height / 2);
    final paintBit = Paint();

    for (final (turns, reach, r, colorIx, losango) in _bits) {
      final angle = turns * 2 * math.pi;
      final pos = center +
          Offset(
            math.cos(angle) * size.width * 0.58 * reach * spread,
            math.sin(angle) * size.height * 0.66 * reach * spread -
                8 * progress, // sobe de leve
          );
      paintBit.color = colors[colorIx].withValues(alpha: 0.95 * fade);
      if (losango) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
            paintBit);
        canvas.restore();
      } else {
        canvas.drawCircle(pos, r, paintBit);
      }
    }
  }

  @override
  bool shouldRepaint(_Sparkles old) =>
      old.progress != progress || old.colors != colors;
}
