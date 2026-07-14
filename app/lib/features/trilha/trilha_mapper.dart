import 'dart:math' as math;

import '../home/data/trilha_models.dart';
import '../home/home_mapper.dart';
import 'models.dart';

/// Traduz `GET /v1/trilha` no **mapa vertical contínuo** (decisão do dono,
/// 13/07 — revisa a "janela com template fixo" de 12/07): a serpentina do
/// design (4 nós por destino, largura 340) repete-se de baixo para cima num
/// canvas único; a tela rola livremente e abre centrada no nó atual. Entre
/// países entra o **portão** com a faixa de fronteira. Sem paginação.
///
/// Gramática (de baixo para cima):
///   bandeira de início
///   → por destino: nós 1..3 (fichas comuns) + nó 4 = **marco** (medalhão;
///     rende o cartão-postal)
///   → entre países: faixa de fronteira + portão do próximo país
abstract final class TrilhaMapper {
  /// Serpentina do design por destino: x fixo, dy = altura ACIMA da base
  /// do segmento do destino (espaço lógico, largura 340).
  static const _slots = [
    (x: 90.0, dy: 56.0),
    (x: 200.0, dy: 104.0),
    (x: 252.0, dy: 184.0),
    (x: 140.0, dy: 260.0), // marco (medal)
  ];

  /// Bandeira de início: altura acima da borda inferior do mapa.
  static const _yInicio = 16.0;
  static const _xInicio = 166.0;

  /// Passo vertical entre bases de destinos consecutivos do mesmo país
  /// (marco→nó1 seguinte = 300+56−260 = 96, o respiro do template).
  static const _passo = 300.0;

  /// Espaço extra na troca de país (fronteira + portão).
  static const _extraFronteira = 210.0;

  /// Portão e faixa de fronteira, acima da base do destino que fecha o país.
  static const _dyPortao = 410.0;
  static const _dyFaixa = 344.0;
  static const _xPortao = 170.0;

  /// Folga acima do último marco.
  static const _topo = 110.0;

  /// Índice do destino atual na trilha linear: o marcado `atual`; senão o
  /// primeiro não concluído; senão o último (trilha inteira concluída).
  static int indiceAtual(List<TrilhaDestino> destinos) {
    if (destinos.isEmpty) return -1;
    final atual = destinos.indexWhere((d) => d.atual);
    if (atual != -1) return atual;
    final pendente = destinos.indexWhere((d) => !d.concluido);
    return pendente != -1 ? pendente : destinos.length - 1;
  }

  /// Monta o mapa contínuo da trilha inteira, de baixo (início) para cima.
  static TrilhaMapData mapaCompleto(Trilha trilha) {
    final destinos = trilha.destinosEmOrdem;

    // Base (altura acima da borda inferior) de cada destino; a troca de
    // país abre espaço extra para a fronteira + portão.
    final bases = <double>[];
    var base = _yInicio;
    for (var i = 0; i < destinos.length; i++) {
      bases.add(base);
      base += _passo + (_fechaPais(trilha, destinos, i) ? _extraFronteira : 0);
    }
    final altura = bases.last + _slots.last.dy + _topo;
    double y(double acimaDaBase) => altura - acimaDaBase; // p/ top-down

    // Nós de baixo para cima; o TrilhaMap espera de cima para baixo.
    final nos = <MapNode>[
      MapNode(
        id: 'start',
        type: NodeType.start,
        state: NodeState.done,
        x: _xInicio,
        y: y(_yInicio),
        label: 'Início',
      ),
    ];
    final fronteiras = <MapFrontier>[];
    for (var i = 0; i < destinos.length; i++) {
      final d = destinos[i];
      final quantos = math.min(d.nosTotal, _slots.length);
      for (var ordem = 1; ordem <= quantos; ordem++) {
        final slot = _slots[ordem - 1];
        nos.add(_no(d, ordem,
            marco: ordem == quantos, x: slot.x, y: y(bases[i] + slot.dy)));
      }
      if (_fechaPais(trilha, destinos, i)) {
        final pais = _paisDe(trilha, d);
        final proximoPais = _paisDe(trilha, destinos[i + 1]);
        fronteiras.add(MapFrontier(
            label: 'Fronteira · ${proximoPais.nome}',
            y: y(bases[i] + _dyFaixa)));
        nos.add(
            _portao(pais, proximoPais, x: _xPortao, y: y(bases[i] + _dyPortao)));
      }
    }

    final atualIdx = indiceAtual(destinos);
    final pais = _paisDe(trilha, destinos[atualIdx]);
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
      nodes: nos.reversed.toList(),
      frontiers: fronteiras,
      mapHeight: altura,
    );
  }

  /// Posição vertical (top-down, espaço lógico) do nó atual — alvo do scroll
  /// inicial. Sem nó atual (trilha concluída), o topo do percorrido.
  static double yAtual(TrilhaMapData data) {
    for (final n in data.nodes) {
      if (n.state == NodeState.current) return n.y;
    }
    for (final n in data.nodes) {
      if (n.state == NodeState.done) return n.y; // lista é top-down
    }
    return data.mapHeight;
  }

  /// O destino [i] é o último do seu país (e há um próximo país)?
  static bool _fechaPais(
      Trilha trilha, List<TrilhaDestino> destinos, int i) {
    if (i + 1 >= destinos.length) return false;
    return _paisDe(trilha, destinos[i]).id !=
        _paisDe(trilha, destinos[i + 1]).id;
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

  /// Um nó do destino nas coordenadas dadas (1..3 comuns, último = marco).
  /// Estados: concluídos até `nosConcluidos`; o seguinte é o atual quando o
  /// destino é o atual; o resto bloqueado.
  static MapNode _no(TrilhaDestino d, int ordem,
      {required bool marco, required double x, required double y}) {
    final state = ordem <= d.nosConcluidos
        ? NodeState.done
        : (d.atual && ordem == d.nosConcluidos + 1)
            ? NodeState.current
            : NodeState.locked;
    final atual = state == NodeState.current;
    if (!marco) {
      return MapNode(
        id: 'd${d.id}-n$ordem',
        type: NodeType.comum,
        state: state,
        x: x,
        y: y,
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
      x: x,
      y: y,
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

  /// Portão do próximo país (na faixa de fronteira).
  static MapNode _portao(TrilhaPais paisAtual, TrilhaPais proximoPais,
      {required double x, required double y}) {
    final aberto = paisAtual.concluido;
    return MapNode(
      id: 'portao-p${proximoPais.id}',
      type: NodeType.gate,
      state: aberto ? NodeState.done : NodeState.locked,
      x: x,
      y: y,
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
