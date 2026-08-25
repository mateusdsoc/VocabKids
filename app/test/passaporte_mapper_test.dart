import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/home/data/trilha_models.dart';
import 'package:vocabkids/features/identidade/models.dart';
import 'package:vocabkids/features/passaporte/data/passaporte_models.dart';
import 'package:vocabkids/features/passaporte/models.dart';
import 'package:vocabkids/features/passaporte/passaporte_mapper.dart';

/// Fixtures espelhando `/v1/me`, `/v1/trilha` e `/v1/passaporte`.
Me _me() => Me.fromJson({
      'usuario_id': 1,
      'nome': 'Ana',
      'papel': 'aluno',
      'perfil': {
        'usuario_id': 1,
        'apelido': 'Ana',
        'faixa_etaria': '9-10',
        'ano_escolar': 5,
      },
      'progresso': {
        'xp_total': 19000,
        'no_atual_id': 5,
        'palavras_dominadas': 12,
        'nivel_dificuldade_atual': 2,
      },
    });

Trilha _trilha() => Trilha.fromJson({
      'xp_total': 19000,
      'no_atual': {
        'destino_id': 2,
        'destino_nome': 'Salvador',
        'pais_nome': 'Brasil',
        'no_ordem': 1,
        'xp_inicio': 18000,
        'xp_limiar': 22500,
      },
      'paises': [
        {
          'id': 1,
          'nome': 'Brasil',
          'ordem': 1,
          'concluido': false,
          'destinos': [
            {
              'id': 1,
              'nome': 'Rio de Janeiro',
              'ordem': 1,
              'nos_total': 4,
              'nos_concluidos': 4,
              'concluido': true,
              'atual': false,
            },
            {
              'id': 2,
              'nome': 'Salvador',
              'ordem': 2,
              'nos_total': 4,
              'nos_concluidos': 0,
              'concluido': false,
              'atual': true,
            },
          ],
        },
      ],
    });

Map<String, dynamic> _item(
  int id,
  String tipo,
  String referencia, {
  bool conquistado = false,
  bool revelado = false,
  String? ganhoEm,
}) =>
    {
      'id': id,
      'tipo': tipo,
      'referencia': referencia,
      'asset_ref': null,
      'conquistado': conquistado,
      'ganho_em': ganhoEm ?? (conquistado ? '2026-07-01T12:00:00Z' : null),
      'revelado': revelado,
    };

PassaporteDto _dto(List<Map<String, dynamic>> itens) => PassaporteDto.fromJson({
      'total': itens.length,
      'conquistados': itens.where((i) => i['conquistado'] as bool).length,
      'itens': itens,
    });

void main() {
  group('PassaporteMapper.carregadoDe', () {
    test('monta capa, países e selos a partir de /me + /trilha + itens', () {
      final carregado = PassaporteMapper.carregadoDe(
        me: _me(),
        trilha: _trilha(),
        dto: _dto([
          _item(1, 'cartao_postal', 'destino:1',
              conquistado: true, revelado: true),
          _item(2, 'cartao_postal', 'destino:2'),
          _item(10, 'carimbo', 'pais:1'),
          _item(20, 'selo', 'feito:combo_10',
              conquistado: true, revelado: true),
          _item(21, 'selo', 'feito:dominadas_25'),
        ]),
      );
      final p = carregado.passaporte;

      expect(p.capa.nome, 'Ana');
      expect(p.capa.nivel, 5); // 4 nós concluídos + 1
      expect(p.capa.paisAtual, 'Brasil');

      final brasil = p.paises.single;
      expect(brasil.pais, Pais.brasil);
      expect(brasil.carimbo, isFalse);
      expect(brasil.destinos.first.cidade, 'Rio de Janeiro');
      expect(brasil.destinos.first.conquistado, isTrue);
      expect(brasil.destinos.last.conquistado, isFalse);

      // Selos na ordem do catálogo do cliente (combo antes de dominadas_25).
      expect([for (final s in p.selos) s.titulo], ['Combo de 10', '25 palavras']);
      expect(p.selos.first.conquistado, isTrue);

      expect(carregado.pendentes, isEmpty); // tudo já revelado
    });

    test('pendentes: ganhos não revelados viram conquistas em ordem de ganho',
        () {
      final carregado = PassaporteMapper.carregadoDe(
        me: _me(),
        trilha: _trilha(),
        dto: _dto([
          _item(1, 'cartao_postal', 'destino:1',
              conquistado: true, ganhoEm: '2026-07-02T10:00:00Z'),
          _item(10, 'carimbo', 'pais:1',
              conquistado: true, ganhoEm: '2026-07-02T10:00:01Z'),
          _item(20, 'selo', 'feito:combo_10',
              conquistado: true, ganhoEm: '2026-07-01T09:00:00Z'),
          _item(21, 'selo', 'feito:dominadas_25'),
        ]),
      );

      final pendentes = carregado.pendentes;
      expect(pendentes.length, 3);

      // Mais antigo primeiro: o selo veio de uma sessão anterior.
      final selo = pendentes[0] as ConquistaSelo;
      expect(selo.colecionavelId, 20);
      expect(selo.todos[selo.novoIndex].titulo, 'Combo de 10');

      final postal = pendentes[1] as ConquistaPostal;
      expect(postal.colecionavelId, 1);
      expect(postal.destino.cidade, 'Rio de Janeiro');

      final carimbo = pendentes[2] as ConquistaCarimbo;
      expect(carimbo.colecionavelId, 10);
      expect(carimbo.pais, Pais.brasil);
    });
  });
}
