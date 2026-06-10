import 'dart:async';

import 'package:flutter/material.dart';

/// Entrada suave reutilizável (fade + deslize + escala opcional), com [delay]
/// para escalonar seções. Roda **uma vez**, ao entrar na árvore, e é
/// não-bloqueante (princípio do produto 3.7): o conteúdo já ocupa o layout e
/// responde a toque — só opacidade/posição animam por cima.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 260),
    this.offset = const Offset(0, 14),
    this.scaleFrom = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;

  /// Espera antes de começar (para stagger entre seções).
  final Duration delay;
  final Duration duration;

  /// Deslocamento inicial em pixels (anima até zero).
  final Offset offset;

  /// Escala inicial; 1.0 desliga a escala.
  final double scaleFrom;
  final Curve curve;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _anim =
      CurvedAnimation(parent: _controller, curve: widget.curve);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        Widget w = Opacity(
          // clamp: curvas com overshoot (easeOutBack) passam de 1.
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
                widget.offset.dx * (1 - t), widget.offset.dy * (1 - t)),
            child: child,
          ),
        );
        if (widget.scaleFrom != 1.0) {
          w = Transform.scale(
            scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
            child: w,
          );
        }
        return w;
      },
      child: widget.child,
    );
  }
}
