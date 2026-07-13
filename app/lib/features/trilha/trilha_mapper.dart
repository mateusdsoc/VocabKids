import 'dart:math' as math;

import '../home/data/trilha_models.dart';
import '../home/home_mapper.dart';
import 'models.dart';

/// Traduz `GET /v1/trilha` na **janela** do mapa (decisão do dono, 12/07):
/// o desenho travado do contrato (espaço 340×540, template fixo de posições)
/// é reutilizado por destino — a "câmera" enquadra um destino por vez e a
/// navegação lateral (swipe/chevrons) troca de janela. Nada de layout
/// procedural para os 80 nós.
///
/// Gramática da janela (de baixo para cima, como o mockup):
///   âncora (início da jornada ou marco do destino anterior)
///   → nós 1..3 do destino (fichas comuns)
///   → nó 4 = **marco** do destino (medalhão; rende o cartão-postal)
///   → contexto do topo: prévia do próximo destino, ou o **portão** do
///     próximo país (com a faixa de fronteira) quando o destino é o último
///     do seu país. Última janela da trilha não tem topo.
abstract final class TrilhaMapper {
  /// Posições do template no espaço lógico 340×540 (serpentina do design).
  static const _slotAncora = (x: 166.0, y: 524.0);
  static const _slotsNos = [
    (x: 90.0, y: 468.0),
    (x: 200.0, y: 420.0),
    (x: 252.0, y: 340.0),
    (x: 140.0, y: 264.0), // marco (medal)
  ];
  static const _slotPrevia = (x: 248.0, y: 168.0);
  static const _slotPortao = (x: 170.0, y: 54.0);
  // Abaixo do rótulo do portão (que termina ~155) e acima do marco (~228):
  // a faixa não colide com texto e o caminho "cruza a fronteira".
  static const _fronteiraY = 168.0;

  /// Índice do destino atual na trilha linear: o marcado `atual`; senão o
  /// primeiro não concluído; senão o último (trilha inteira concluída).
  static int indiceAtual(List<TrilhaDestino> destinos) {
    if (destinos.isEmpty) return -1;
    final atual = destinos.indexWhere((d) => d.atual);
    if (atual != -1) return atual;
    final pendente = destinos.indexWhere((d) => !d.concluido);
    return pendente != -1 ? pendente : destinos.length - 1;
  }

  /// Monta a janela do destino [destinoIdx] (índice na trilha linear).
  static TrilhaMapData janela(Trilha trilha, int destinoIdx) {
    final destinos = trilha.destinosEmOrdem;
    final destino = destinos[destinoIdx];
    final pais = _paisDe(trilha, destino);
    final anterior = destinoIdx > 0 ? destinos[destinoIdx - 1] : null;
    final proximo =
        destinoIdx + 1 < destinos.length ? destinos[destinoIdx + 1] : null;
    final proximoPais = proximo == null ? null : _paisDe(trilha, proximo);
    final trocaDePais = proximoPais != null && proximoPais.id != pais.id;

    // A lista de nós é de cima para baixo (ordem que o TrilhaMap espera).
    final nos = <MapNode>[
      if (proximo != null)
        trocaDePais
            ? _portao(pais, proximoPais)
            : _previa(proximo),
      ..._nosDoDestino(destino).reversed,
      _ancora(anterior),
    ];

    return TrilhaMapData(
      level: _nivel(destinos),
      xpCurrent: trilha.xpTotal,
      xpTarget: trilha.noAtual?.xpLimiar ?? math.max(trilha.xpTotal, 1),
      country: TrilhaCountry(
        name: pais.nome,
        tagline: _taglineDoPais(pais, destinos),
        destinationsDone: pais.destinos.where((d) => d.concluido).length,
        destinationsTotal: pais.destinos.length,
      ),
      nodes: nos,
      frontierLabel: trocaDePais ? 'Fronteira · ${proximoPais.nome}' : null,
      frontierY: _fronteiraY,
    );
  }

  /// Nível de gamificação = nós concluídos + 1 (mesma regra da Home/Resumo).
  static int _nivel(List<TrilhaDestino> destinos) =>
      destinos.fold<int>(0, (sum, d) => sum + d.nosConcluidos) + 1;

  static TrilhaPais _paisDe(Trilha trilha, TrilhaDestino destino) =>
      trilha.paises
          .firstWhere((p) => p.destinos.any((d) => d.id == destino.id));

  static String _taglineDoPais(TrilhaPais pais, List<TrilhaDestino> destinos) {
    final atualIdx = indiceAtual(destinos);
    final contemAtual = atualIdx >= 0 &&
        pais.destinos.any((d) => d.id == destinos[atualIdx].id);
    if (contemAtual) return 'país atual';
    return pais.concluido ? 'concluído' : 'em breve';
  }

  /// Os 4 nós do destino, de baixo para cima (1..3 comuns, 4 = marco).
  /// Estados: concluídos até `nosConcluidos`; o seguinte é o atual quando o
  /// destino é o atual; o resto bloqueado.
  static List<MapNode> _nosDoDestino(TrilhaDestino d) {
    final quantos = math.min(d.nosTotal, _slotsNos.length);
    return [
      for (var i = 1; i <= quantos; i++) _no(d, i, marco: i == quantos),
    ];
  }

  static MapNode _no(TrilhaDestino d, int ordem, {required bool marco}) {
    final state = ordem <= d.nosConcluidos
        ? NodeState.done
        : (d.atual && ordem == d.nosConcluidos + 1)
            ? NodeState.current
            : NodeState.locked;
    final slot = _slotsNos[ordem - 1];
    final atual = state == NodeState.current;
    if (!marco) {
      return MapNode(
        id: 'd${d.id}-n$ordem',
        type: NodeType.comum,
        state: state,
        x: slot.x,
        y: slot.y,
        // O aside (nome + "Continuar") identifica o nó atual; os demais
        // comuns ficam sem rótulo, como no mockup.
        label: atual ? d.nome : null,
        cta: atual,
      );
    }
    return MapNode(
      id: 'd${d.id}-marco',
      type: NodeType.medal,
      state: state,
      x: slot.x,
      y: slot.y,
      label: atual ? d.nome : null,
      sub: switch (state) {
        NodeState.done => '${d.nome} · concluído',
        NodeState.current => null,
        NodeState.locked => '${d.nome} · marco',
      },
      art: state == NodeState.locked
          ? null
          : HomeMapper.assetParaCidade(d.nome),
      ghost: state == NodeState.locked ? Landmark.monument : null,
      cta: atual,
    );
  }

  /// Âncora inferior: bandeira de início (1ª janela) ou o marco do destino
  /// anterior — contexto de onde o aluno veio.
  static MapNode _ancora(TrilhaDestino? anterior) {
    if (anterior == null) {
      return const MapNode(
        id: 'start',
        type: NodeType.start,
        state: NodeState.done,
        x: 166,
        y: 524,
        label: 'Início',
      );
    }
    final state = anterior.concluido ? NodeState.done : NodeState.locked;
    return MapNode(
      id: 'ancora-d${anterior.id}',
      type: NodeType.medal,
      state: state,
      x: _slotAncora.x,
      y: _slotAncora.y,
      sub: anterior.atual
          ? '${anterior.nome} · atual'
          : '${anterior.nome} · ${anterior.concluido ? 'concluído' : 'bloqueado'}',
      art: anterior.concluido
          ? HomeMapper.assetParaCidade(anterior.nome)
          : null,
      ghost: anterior.concluido ? null : Landmark.monument,
      next: anterior.atual,
    );
  }

  /// Prévia do próximo destino do mesmo país (topo da janela).
  static MapNode _previa(TrilhaDestino proximo) {
    final state = proximo.concluido ? NodeState.done : NodeState.locked;
    return MapNode(
      id: 'previa-d${proximo.id}',
      type: NodeType.medal,
      state: state,
      x: _slotPrevia.x,
      y: _slotPrevia.y,
      sub: proximo.atual
          ? '${proximo.nome} · atual'
          : '${proximo.nome} · ${proximo.concluido ? 'concluído' : 'bloqueado'}',
      art: proximo.concluido
          ? HomeMapper.assetParaCidade(proximo.nome)
          : null,
      ghost: proximo.concluido ? null : Landmark.monument,
      next: proximo.atual,
    );
  }

  /// Portão do próximo país (última janela de cada país) + fronteira.
  static MapNode _portao(TrilhaPais paisAtual, TrilhaPais proximoPais) {
    final aberto = paisAtual.concluido;
    return MapNode(
      id: 'portao-p${proximoPais.id}',
      type: NodeType.gate,
      state: aberto ? NodeState.done : NodeState.locked,
      x: _slotPortao.x,
      y: _slotPortao.y,
      label: proximoPais.nome,
      sub: aberto
          ? 'Portão · aberto'
          : 'Portão · ao concluir o ${paisAtual.nome}',
      art: HomeMapper.assetParaCidade(_cidadeSimbolo(proximoPais)),
      ghost: _marcoDoPais(proximoPais.nome),
    );
  }

  /// Primeira cidade do país — usada só para tentar resolver uma arte.
  static String _cidadeSimbolo(TrilhaPais pais) =>
      pais.destinos.isEmpty ? pais.nome : pais.destinos.first.nome;

  static Landmark _marcoDoPais(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('fran')) return Landmark.eiffel;
    if (n.contains('jap')) return Landmark.mountain;
    return Landmark.monument;
  }
}
