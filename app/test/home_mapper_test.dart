import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/home/data/trilha_models.dart';
import 'package:vocabkids/features/home/home_data.dart';
import 'package:vocabkids/features/home/home_mapper.dart';
import 'package:vocabkids/features/identidade/models.dart';

/// Fixtures espelhando os contratos de `/v1/me` e `/v1/trilha`.
Me _me() => Me.fromJson({
      'usuario_id': 1,
      'nome': 'Ana',
      'papel': 'aluno',
      'escola': null,
      'turma': null,
      'progresso': {
        'xp_total': 3120,
        'no_atual_id': 12,
        'palavras_dominadas': 23,
        'nivel_dificuldade_atual': 2,
      },
    });

Trilha _trilha() => Trilha.fromJson({
      'xp_total': 3120,
      'no_atual': {
        'destino_id': 12,
        'destino_nome': 'Rio de Janeiro',
        'pais_nome': 'Brasil',
        'no_ordem': 3,
        'xp_inicio': 0,
        'xp_limiar': 4500,
      },
      'paises': [
        {
          'id': 1,
          'nome': 'Brasil',
          'ordem': 1,
          'concluido': false,
          'destinos': [
            {
              'id': 11,
              'nome': 'Salvador',
              'ordem': 1,
              'nos_total': 4,
              'nos_concluidos': 4,
              'concluido': true,
              'atual': false,
            },
            {
              'id': 12,
              'nome': 'Rio de Janeiro',
              'ordem': 2,
              'nos_total': 6,
              'nos_concluidos': 2,
              'concluido': false,
              'atual': true,
            },
          ],
        },
        {
          'id': 2,
          'nome': 'França',
          'ordem': 2,
          'concluido': false,
          'destinos': [
            {
              'id': 21,
              'nome': 'Paris',
              'ordem': 1,
              'nos_total': 6,
              'nos_concluidos': 0,
              'concluido': false,
              'atual': false,
            },
          ],
        },
      ],
    });

void main() {
  group('HomeMapper.from', () {
    final data = HomeMapper.from(me: _me(), trilha: _trilha());

    test('mapeia perfil e progresso de /me', () {
      expect(data.studentName, 'Ana');
      expect(data.avatarInitial, 'A');
      expect(data.wordsMastered, 23);
    });

    test('barra de XP usa o teto do nó atual', () {
      expect(data.xpCurrent, 3120);
      expect(data.xpTarget, 4500);
      expect(data.xpFraction, closeTo(0.693, 0.001));
    });

    test('nível = nós concluídos + 1', () {
      expect(data.level, 7); // 4 (Salvador) + 2 (Rio) + 0 (Paris) + 1
    });

    test('lição vem do destino atual', () {
      expect(data.lesson, isNotNull);
      expect(data.lesson!.city, 'Rio de Janeiro');
      expect(data.lesson!.country, 'Brasil');
      expect(data.lesson!.lessonIndex, 3);
      expect(data.lesson!.lessonTotal, 6);
      expect(data.lesson!.imageAsset, 'assets/images/rio.webp');
    });

    test('fita = anterior · atual · próximo, com status correto', () {
      expect(data.trail.map((n) => n.name).toList(),
          ['Salvador', 'Rio de Janeiro', 'Paris']);
      expect(data.trail.map((n) => n.status).toList(), [
        TrailNodeStatus.done,
        TrailNodeStatus.current,
        TrailNodeStatus.locked,
      ]);
    });

    test('resolve arte só para destinos com asset', () {
      expect(HomeMapper.assetParaCidade('Rio de Janeiro'),
          'assets/images/rio.webp');
      expect(HomeMapper.assetParaCidade('Paris'), 'assets/images/paris.webp');
      expect(HomeMapper.assetParaCidade('Foz do Iguaçu — Cataratas'),
          'assets/images/foz_iguacu.webp');
      expect(HomeMapper.assetParaCidade('Amazônia — Encontro das Águas'),
          'assets/images/amazonia.webp');
      expect(HomeMapper.assetParaCidade('Fernando de Noronha'),
          'assets/images/noronha.webp');
      expect(HomeMapper.assetParaCidade('Lençóis Maranhenses'),
          'assets/images/lencois.webp');
      // França (nomes exatos do seed_trilha.py). "Mont Blanc" e
      // "Mont-Saint-Michel" não podem colidir.
      expect(HomeMapper.assetParaCidade('Mont-Saint-Michel'),
          'assets/images/mont_saint_michel.webp');
      expect(HomeMapper.assetParaCidade('Provença — campos de lavanda'),
          'assets/images/provenca.webp');
      expect(HomeMapper.assetParaCidade('Vale do Loire — Château de Chambord'),
          'assets/images/loire.webp');
      expect(HomeMapper.assetParaCidade('Costa Azul — Nice/Riviera'),
          'assets/images/costa_azul.webp');
      expect(HomeMapper.assetParaCidade('Alpes — Mont Blanc'),
          'assets/images/mont_blanc.webp');
      // Versalhes ainda não tem arte → placeholder.
      expect(HomeMapper.assetParaCidade('Versalhes — palácio e jardins'),
          isNull);
    });
  });
}
