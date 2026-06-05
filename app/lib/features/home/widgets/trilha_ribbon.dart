import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import '../home_data.dart';

/// Fita "Sua trilha": progressão enxuta de 3 nós (anterior · atual · próximo)
/// centrada no card, com segmentos preenchidos até o nó atual e o link
/// "Ver mapa" no topo direito.
class TrilhaRibbon extends StatelessWidget {
  const TrilhaRibbon({super.key, required this.nodes, this.onSeeMap});

  final List<TrailNode> nodes;
  final VoidCallback? onSeeMap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sua trilha',
                  style: AppType.fredoka(
                      size: 14.5, weight: FontWeight.w500, color: c.ink)),
              InkWell(
                onTap: onSeeMap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.map, size: 15, color: c.primary),
                      const SizedBox(width: 5),
                      Text('Ver mapa',
                          style: AppType.nunito(
                              size: 11.5,
                              weight: FontWeight.w800,
                              color: c.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRibbon(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRibbon() {
    final children = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      children.add(_TrailNodeView(node: nodes[i]));
      if (i < nodes.length - 1) {
        // Segmento preenchido quando o nó anterior já foi concluído.
        children.add(_Segment(filled: nodes[i].status == TrailNodeStatus.done));
      }
    }
    return children;
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Padding(
        // Alinha o segmento ao centro vertical dos medalhões.
        padding: const EdgeInsets.only(top: 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 46),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: filled ? c.goal : c.track,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailNodeView extends StatelessWidget {
  const _TrailNodeView({required this.node});
  final TrailNode node;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isCurrent = node.status == TrailNodeStatus.current;
    final nameColor = isCurrent ? c.primary : c.muted;

    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(node: node),
          const SizedBox(height: 9),
          Text(
            node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 11, weight: FontWeight.w800, color: nameColor, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            _statusLabel(node.status),
            style: AppType.nunito(
                size: 9,
                weight: FontWeight.w800,
                letterSpacing: 0.4,
                color: nameColor),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.node});
  final TrailNode node;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isCurrent = node.status == TrailNodeStatus.current;
    final isLocked = node.status == TrailNodeStatus.locked;
    final size = isCurrent ? 62.0 : 56.0;

    // Duplo anel via sombras concêntricas (gap de papel + linha/primária).
    final ringColor = isCurrent ? c.primary : c.line;
    final ringSpread = isCurrent ? 5.0 : 4.0;

    Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.track,
        image: node.imageAsset != null
            ? DecorationImage(
                image: AssetImage(node.imageAsset!), fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(color: c.paper, spreadRadius: 3),
          BoxShadow(color: ringColor, spreadRadius: ringSpread),
        ],
      ),
    );

    if (isLocked) {
      dot = Opacity(
        opacity: 0.6,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_saturation(0.4)),
          child: dot,
        ),
      );
    }

    return SizedBox(
      // Espaço para os anéis não serem cortados pelo layout acima.
      height: 62 + 6,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            dot,
            if (node.status != TrailNodeStatus.current)
              Positioned(
                bottom: -3,
                right: -4,
                child: _Badge(status: node.status),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.status});
  final TrailNodeStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = status == TrailNodeStatus.done;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? c.goal : c.muted,
        border: Border.all(color: c.paper, width: 2),
      ),
      child: Icon(
        done ? AppIcons.check : AppIcons.lock,
        size: 11,
        color: Colors.white,
      ),
    );
  }
}

String _statusLabel(TrailNodeStatus s) => switch (s) {
      TrailNodeStatus.done => 'CONCLUÍDO',
      TrailNodeStatus.current => 'ATUAL',
      TrailNodeStatus.locked => 'PRÓXIMO',
    };

/// Matriz de saturação (s=1 mantém; s<1 dessatura) para o nó bloqueado.
List<double> _saturation(double s) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final inv = 1 - s;
  final r = inv * lr, g = inv * lg, b = inv * lb;
  return [
    r + s, g, b, 0, 0, //
    r, g + s, b, 0, 0, //
    r, g, b + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}
