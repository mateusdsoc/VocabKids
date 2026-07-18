import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/redacao/data/redacao_models.dart';
import 'package:vocabkids/features/redacao/models.dart';
import 'package:vocabkids/features/redacao/redacao_mapper.dart';

void main() {
  group('RedacaoMapper', () {
    test('atribuição sem envio vira item aberto', () {
      final dto = RedacoesDto.fromJson({
        'itens': [
          {
            'atribuicao_id': 7,
            'tema': 'Minhas férias',
            'prazo': '2026-08-01',
            'redacao': null,
          },
        ],
      });
      final itens = RedacaoMapper.listaDe(dto);
      expect(itens, hasLength(1));
      final r = itens.single;
      expect(r.atribuicaoId, 7);
      expect(r.redacaoId, isNull);
      expect(r.status, RedacaoStatus.aberta);
      expect(r.aberta, isTrue);
      expect(r.prazo, DateTime(2026, 8, 1));
      expect(r.paginas, 0);
    });

    test('envio pendente vira "em análise" com páginas e data', () {
      final item = RedacaoMapper.itemDe(RedacaoItemDto.fromJson({
        'atribuicao_id': 7,
        'tema': 'Minhas férias',
        'prazo': null,
        'redacao': {
          'redacao_id': 41,
          'status': 'enviada',
          'enviada_em': '2026-07-18T14:00:00Z',
          'paginas': 2,
        },
      }));
      expect(item.status, RedacaoStatus.emAnalise);
      expect(item.redacaoId, 41);
      expect(item.paginas, 2);
      expect(item.enviadaEm, DateTime.utc(2026, 7, 18, 14));
      expect(item.prazo, isNull);
    });

    test('status do servidor mapeia para o ciclo da tela', () {
      RedacaoStatus statusDe(String s) => RedacaoMapper.itemDe(
            RedacaoItemDto.fromJson({
              'atribuicao_id': 1,
              'tema': 't',
              'prazo': null,
              'redacao': {
                'redacao_id': 1,
                'status': s,
                'enviada_em': '2026-07-18T14:00:00Z',
                'paginas': 1,
              },
            }),
          ).status;

      expect(statusDe('analisada'), RedacaoStatus.analisada);
      expect(statusDe('processando'), RedacaoStatus.emAnalise);
      // erro_* só ocorre com o pipeline rodando (fatia 2); até lá, "em análise".
      expect(statusDe('erro_ingestao'), RedacaoStatus.emAnalise);
    });

    test('aposEnvio espelha o 201 sobre o item aberto', () {
      const aberta = Redacao(
        atribuicaoId: 7,
        tema: 'Minhas férias',
        status: RedacaoStatus.aberta,
      );
      final envio = EnvioDto.fromJson({
        'redacao_id': 41,
        'status': 'enviada',
        'enviada_em': '2026-07-18T14:00:00Z',
        'paginas': 3,
      });
      final depois = RedacaoMapper.aposEnvio(aberta, envio);
      expect(depois.atribuicaoId, 7);
      expect(depois.redacaoId, 41);
      expect(depois.status, RedacaoStatus.emAnalise);
      expect(depois.paginas, 3);
      expect(depois.tema, aberta.tema);
    });
  });
}
