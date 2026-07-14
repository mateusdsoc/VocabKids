import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/home/data/trilha_models.dart';
import 'package:vocabkids/features/trilha/models.dart';
import 'package:vocabkids/features/trilha/trilha_mapper.dart';

/// Trilha de exemplo: 2 países × 2 destinos × 4 nós.
/// Rio concluído; Foz é o atual (2 nós concluídos → nó 3 é o atual);
/// Paris e Lyon bloqueados.
Trilha _trilha({TrilhaNoAtual? noAtual}) {
  TrilhaDestino destino(int id, String nome,
          {required int concluidos, bool atual = false}) =>
      TrilhaDestino(
        id: id,
        nome: nome,
        ordem: id,
        nosTotal: 4,
        nosConcluidos: concluidos,
        concluido: concluidos >= 4,
        atual: atual,
      );

  return Trilha(
    xpTotal: 27000,
    noAtual: noAtual ??
        TrilhaNoAtual(
          destinoId: 2,
          destinoNome: 'Foz do Iguaçu',
          paisNome: 'Brasil',
          noOrdem: 3,
          xpInicio: 27000,
          xpLimiar: 31500,
        ),
    paises: [
      TrilhaPais(
        id: 1,
        nome: 'Brasil',
        ordem: 1,
        concluido: false,
        destinos: [
          destino(1, 'Rio de Janeiro', concluidos: 4),
          destino(2, 'Foz do Iguaçu', concluidos: 2, atual: true),
        ],
      ),
      TrilhaPais(
        id: 2,
        nome: 'França',
        ordem: 2,
        concluido: false,
        destinos: [
          destino(3, 'Paris', concluidos: 0),
          destino(4, 'Lyon', concluidos: 0),
        ],
      ),
    ],
  );
}

void main() {
  group('TrilhaMapper.indiceAtual', () {
    test('usa o destino marcado como atual', () {
      expect(TrilhaMapper.indiceAtual(_trilha().destinosEmOrdem), 1);
    });

    test('sem atual, cai no primeiro não concluído; senão no último', () {
      final destinos = _trilha().destinosEmOrdem;
      final semAtual = [
        for (final d in destinos)
          TrilhaDestino(
            id: d.id,
            nome: d.nome,
            ordem: d.ordem,
            nosTotal: d.nosTotal,
            nosConcluidos: d.nosConcluidos,
            concluido: d.concluido,
            atual: false,
          ),
      ];
      expect(TrilhaMapper.indiceAtual(semAtual), 1); // Foz não concluído
      final tudoConcluido = [
        for (final d in semAtual)
          TrilhaDestino(
            id: d.id,
            nome: d.nome,
            ordem: d.ordem,
            nosTotal: 4,
            nosConcluidos: 4,
            concluido: true,
            atual: false,
          ),
      ];
      expect(TrilhaMapper.indiceAtual(tudoConcluido), 3); // último
    });
  });

  group('TrilhaMapper.mapaCompleto', () {
    test('mapa contínuo: início + 16 nós + portão, CTA no nó atual', () {
      final m = TrilhaMapper.mapaCompleto(_trilha());

      // Cabeçalho: nível = nós concluídos (4+2) + 1; XP do contrato; o
      // carimbo é o do país ATUAL do aluno (Brasil).
      expect(m.level, 7);
      expect(m.xpCurrent, 27000);
      expect(m.xpTarget, 31500);
      expect(m.country.name, 'Brasil');
      expect(m.country.tagline, 'país atual');
      expect(m.country.destinationsDone, 1); // só o Rio
      expect(m.country.destinationsTotal, 2);

      // Estrutura: bandeira de início + 4 destinos × 4 nós + 1 portão.
      expect(m.nodes, hasLength(18));
      expect(m.nodes.last.type, NodeType.start);
      expect(m.nodes.last.label, 'Início');
      expect(m.mapHeight, greaterThan(540)); // canvas cresce com a trilha

      // A lista é de cima para baixo: y estritamente crescente.
      for (var i = 1; i < m.nodes.length; i++) {
        expect(m.nodes[i].y, greaterThan(m.nodes[i - 1].y));
      }

      // Nó atual único (Foz nó 3), com CTA.
      final atuais = m.nodes.where((n) => n.state == NodeState.current);
      expect(atuais, hasLength(1));
      expect(atuais.first.cta, isTrue);
      expect(atuais.first.label, 'Foz do Iguaçu');
      expect(atuais.first.id, 'd2-n3');

      // Marcos: Rio concluído (com arte), Foz bloqueado.
      final rio = m.nodes.singleWhere((n) => n.id == 'd1-marco');
      expect(rio.state, NodeState.done);
      expect(rio.sub, 'Rio de Janeiro · concluído');
      expect(rio.art, 'assets/images/rio.png');
      final foz = m.nodes.singleWhere((n) => n.id == 'd2-marco');
      expect(foz.sub, 'Foz do Iguaçu · marco');
    });

    test('fronteira única entre Brasil e França, portão travado no meio', () {
      final m = TrilhaMapper.mapaCompleto(_trilha());
      expect(m.frontiers, hasLength(1));
      expect(m.frontiers.single.label, 'Fronteira · França');

      final portao = m.nodes.singleWhere((n) => n.type == NodeType.gate);
      expect(portao.label, 'França');
      expect(portao.state, NodeState.locked); // Brasil não concluído

      // Geometria: a faixa fica entre o marco do Foz e o portão; o portão,
      // entre a faixa e o primeiro nó de Paris (y é top-down).
      final foz = m.nodes.singleWhere((n) => n.id == 'd2-marco');
      final paris1 = m.nodes.singleWhere((n) => n.id == 'd3-n1');
      expect(m.frontiers.single.y, lessThan(foz.y));
      expect(m.frontiers.single.y, greaterThan(portao.y));
      expect(portao.y, greaterThan(paris1.y));
    });

    test('destinos futuros ficam todos bloqueados', () {
      final m = TrilhaMapper.mapaCompleto(_trilha());
      final futuros = m.nodes
          .where((n) => n.id.startsWith('d3-') || n.id.startsWith('d4-'));
      expect(futuros, hasLength(8));
      expect(futuros.every((n) => n.state == NodeState.locked), isTrue);
    });

    test('yAtual aponta o nó atual; sem atual, o topo do percorrido', () {
      final m = TrilhaMapper.mapaCompleto(_trilha());
      final atual = m.nodes.singleWhere((n) => n.state == NodeState.current);
      expect(TrilhaMapper.yAtual(m), atual.y);
    });
  });
}
