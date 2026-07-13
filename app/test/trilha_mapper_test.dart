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

  group('TrilhaMapper.janela', () {
    test('janela do destino atual: âncora + 4 nós + prévia, CTA no nó atual',
        () {
      final j = TrilhaMapper.janela(_trilha(), 1); // Foz (2/4)

      // Cabeçalho: nível = nós concluídos (4+2) + 1; XP do contrato.
      expect(j.level, 7);
      expect(j.xpCurrent, 27000);
      expect(j.xpTarget, 31500);
      expect(j.country.name, 'Brasil');
      expect(j.country.tagline, 'país atual');
      expect(j.country.destinationsDone, 1); // só o Rio
      expect(j.country.destinationsTotal, 2);

      // Estrutura (de cima para baixo): portão França (Foz é o último do
      // Brasil) → marco → nós 3..1 → âncora (Rio concluído).
      expect(j.nodes, hasLength(6));
      expect(j.nodes.first.type, NodeType.gate);
      expect(j.nodes.first.label, 'França');
      expect(j.nodes.first.state, NodeState.locked);
      expect(j.frontierLabel, 'Fronteira · França');

      final marco = j.nodes[1];
      expect(marco.type, NodeType.medal);
      expect(marco.state, NodeState.locked);
      expect(marco.sub, 'Foz do Iguaçu · marco');

      // Nós 3 (atual, com CTA), 2 e 1 (concluídos).
      expect(j.nodes[2].state, NodeState.current);
      expect(j.nodes[2].cta, isTrue);
      expect(j.nodes[2].label, 'Foz do Iguaçu');
      expect(j.nodes[3].state, NodeState.done);
      expect(j.nodes[4].state, NodeState.done);

      final ancora = j.nodes.last;
      expect(ancora.type, NodeType.medal);
      expect(ancora.state, NodeState.done);
      expect(ancora.sub, 'Rio de Janeiro · concluído');
      expect(ancora.art, 'assets/images/rio.png');
    });

    test('primeira janela: âncora é a bandeira de início', () {
      final j = TrilhaMapper.janela(_trilha(), 0); // Rio
      expect(j.nodes.last.type, NodeType.start);
      expect(j.nodes.last.label, 'Início');
      // Rio concluído: sem nó atual na janela; prévia aponta o Foz atual.
      expect(j.nodes.every((n) => n.state != NodeState.current), isTrue);
      final previa = j.nodes.first;
      expect(previa.type, NodeType.medal);
      expect(previa.sub, 'Foz do Iguaçu · atual');
      expect(previa.next, isTrue);
      expect(j.frontierLabel, isNull); // sem troca de país nesta janela
    });

    test('janela futura: tudo bloqueado, âncora referencia o destino atual',
        () {
      final j = TrilhaMapper.janela(_trilha(), 2); // Paris
      expect(j.country.name, 'França');
      expect(j.country.tagline, 'em breve');
      expect(
          j.nodes
              .where((n) => n.type == NodeType.comum)
              .every((n) => n.state == NodeState.locked),
          isTrue);
      expect(j.nodes.last.sub, 'Foz do Iguaçu · atual');
    });

    test('última janela da trilha: sem topo nem fronteira', () {
      final j = TrilhaMapper.janela(_trilha(), 3); // Lyon
      expect(j.frontierLabel, isNull);
      // âncora + 4 nós, sem prévia/portão.
      expect(j.nodes, hasLength(5));
      expect(j.nodes.first.type, NodeType.medal); // marco do próprio Lyon
    });
  });
}
