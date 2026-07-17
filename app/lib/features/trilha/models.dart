/// Modelos de apresentação da Trilha (mapa) — produto 3.7.
///
/// Porte do design `Refino/Vocab - Trilha (mapa) v5 escuro` (variação B). Hoje
/// alimentado por um exemplo ([sampleTrilha]); a estrutura espelha o que
/// `GET /v1/trilha` deve entregar (nó atual, destinos, "você está aqui").
library;

/// Tipos de nó da taxonomia do design (tipo × estado).
enum NodeType {
  /// Passo comum — a maioria, sem recompensa.
  comum,

  /// Marco de destino — medalhão que rende um cartão-postal.
  medal,

  /// Portão — fronteira que dá entrada no próximo país (rende carimbo).
  gate,

  /// Bandeira de início da jornada.
  start,
}

enum NodeState { done, current, locked }

/// Marco geográfico desenhado como "vista-fantasma" nos nós bloqueados.
enum Landmark { eiffel, monument, mountain }

/// Bandeira de país **pintada em código** — a cara do portão (decisão 17/07:
/// o arco com arte de cidade duplicava a arte do 1º marco do país).
enum CountryFlag { brasil, franca, japao }

/// Um nó posicionado no mapa (coordenadas no espaço 340×540 do design).
class MapNode {
  const MapNode({
    required this.id,
    required this.type,
    required this.state,
    required this.x,
    required this.y,
    this.label,
    this.sub,
    this.art,
    this.ghost,
    this.flag,
    this.cta = false,
    this.next = false,
    this.progresso,
  });

  final String id;
  final NodeType type;
  final NodeState state;
  final double x;
  final double y;
  final String? label;
  final String? sub;

  /// Arte do destino (cartão-postal/cidade). `null` → placeholder.
  final String? art;

  /// Marco fantasma do nó bloqueado.
  final Landmark? ghost;

  /// Bandeira do país (só nos portões).
  final CountryFlag? flag;

  /// Mostra o botão "Continuar" ao lado (só no nó atual).
  final bool cta;

  /// Realça o rótulo como "próximo".
  final bool next;

  /// Progresso de XP dentro do nó (0..1) — só o nó atual carrega; alimenta o
  /// anel de progresso do pin (telas.md §6). `null` = sem anel de progresso.
  final double? progresso;
}

/// Faixa de fronteira (passagem de país) posicionada no mapa contínuo.
class MapFrontier {
  const MapFrontier({required this.label, required this.y});

  final String label;

  /// Posição vertical (top-down) no espaço lógico do mapa.
  final double y;
}

/// Cabeçalho do país atual (variação "carimbo champanhe").
class TrilhaCountry {
  const TrilhaCountry({
    required this.name,
    required this.tagline,
    required this.destinationsDone,
    required this.destinationsTotal,
  });

  final String name;
  final String tagline;
  final int destinationsDone;
  final int destinationsTotal;

  double get fraction =>
      destinationsTotal == 0 ? 0 : destinationsDone / destinationsTotal;
}

/// Mapa completo da Trilha.
class TrilhaMapData {
  const TrilhaMapData({
    required this.level,
    required this.xpCurrent,
    required this.xpTarget,
    required this.country,
    required this.nodes,
    this.frontiers = const [],
    this.mapHeight = 540,
  });

  final int level;
  final int xpCurrent;
  final int xpTarget;
  final TrilhaCountry country;
  final List<MapNode> nodes;

  /// Faixas de fronteira (passagens de país) — no mapa contínuo pode
  /// haver várias.
  final List<MapFrontier> frontiers;

  /// Altura do espaço lógico (340 de largura fixa). 540 no template de
  /// janela do demo; no mapa contínuo, cresce com a trilha.
  final double mapHeight;

  /// Exemplo que espelha o frame escuro (variação B) do design.
  static const TrilhaMapData sample = TrilhaMapData(
    level: 4,
    xpCurrent: 3120,
    xpTarget: 4500,
    frontiers: [MapFrontier(label: 'França', y: 134)],
    country: TrilhaCountry(
      name: 'Brasil',
      tagline: 'país atual',
      destinationsDone: 3,
      destinationsTotal: 6,
    ),
    nodes: [
      MapNode(
          id: 'franca',
          type: NodeType.gate,
          state: NodeState.locked,
          x: 170,
          y: 54,
          flag: CountryFlag.franca),
      MapNode(
          id: 'brasilia',
          type: NodeType.medal,
          state: NodeState.locked,
          x: 248,
          y: 174,
          sub: 'Brasília · bloqueado',
          ghost: Landmark.monument),
      MapNode(
          id: 's1', type: NodeType.comum, state: NodeState.locked, x: 166, y: 236),
      MapNode(
          id: 'foz',
          type: NodeType.comum,
          state: NodeState.locked,
          x: 92,
          y: 280,
          label: 'Foz',
          sub: 'próximo',
          next: true),
      MapNode(
          id: 'rio',
          type: NodeType.medal,
          state: NodeState.current,
          x: 252,
          y: 354,
          label: 'Rio de Janeiro',
          art: 'assets/images/rio.webp',
          cta: true,
          progresso: 0.69), // 3120/4500 do frame do design
      MapNode(
          id: 's3', type: NodeType.comum, state: NodeState.done, x: 166, y: 432),
      MapNode(
          id: 'salvador',
          type: NodeType.medal,
          state: NodeState.done,
          x: 90,
          y: 472,
          sub: 'Salvador · concluído',
          art: 'assets/images/rio.webp'),
      MapNode(
          id: 'start',
          type: NodeType.start,
          state: NodeState.done,
          x: 166,
          y: 524,
          label: 'Início'),
    ],
  );
}
