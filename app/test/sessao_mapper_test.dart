import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/home/data/trilha_models.dart';
import 'package:vocabkids/features/passaporte/models.dart';
import 'package:vocabkids/features/resumo/models.dart';
import 'package:vocabkids/features/sessao/data/sessao_models.dart';
import 'package:vocabkids/features/sessao/models.dart';
import 'package:vocabkids/features/sessao/sessao_mapper.dart';

/// Fixtures espelhando os contratos de `/v1/sessoes` (SessaoOut/RespostaOut)
/// e `/v1/trilha`.
SlotDto _card() => SlotDto.fromJson({
      'tipo': 'card',
      'palavra': {
        'id': 7,
        'lema': 'enorme',
        'definicao': 'de tamanho muito grande',
        'exemplo_uso': 'Vimos um navio enorme chegar ao porto.',
        'audio_url': null,
        'sinonimos': ['imenso', 'gigantesco'],
        'palavra_gatilho': null,
      },
    });

SlotDto _questao({int nivel = 1, String enunciado = 'O que «enorme» quer dizer?'}) =>
    SlotDto.fromJson({
      'tipo': 'questao',
      'questao_id': 42,
      'palavra_id': 7,
      'lema': 'enorme',
      'nivel': nivel,
      'is_revisao': false,
      'enunciado': enunciado,
      'opcoes': ['Muito grande', 'Muito rápido', 'Muito antigo', 'Muito barato'],
    });

Trilha _trilha() => Trilha.fromJson({
      'xp_total': 3600,
      'no_atual': {
        'destino_id': 12,
        'destino_nome': 'Rio de Janeiro',
        'pais_nome': 'Brasil',
        'no_ordem': 3,
        'xp_inicio': 3000,
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
      ],
    });

void main() {
  group('SessaoMapper.stepDe', () {
    test('card vira DiscoveryStep com a palavra destacada no exemplo', () {
      final step = SessaoMapper.stepDe(_card());
      expect(step, isA<DiscoveryStep>());
      final card = (step as DiscoveryStep).card;
      expect(card.word, 'enorme');
      expect(card.exampleHighlight, 'enorme');
      // Definição capitalizada na apresentação (banco vem em minúscula).
      expect(card.definition, 'De tamanho muito grande');
      // Classe gramatical ainda não existe no banco base → linha oculta.
      expect(card.partOfSpeech, isNull);
    });

    test('questão N1 vira significado com letras A–D e a palavra sublinhada', () {
      final step = SessaoMapper.stepDe(_questao());
      final q = (step as QuestionStep).question;
      expect(q.kind, QuestionKind.significado);
      expect(q.questaoId, 42);
      expect(q.palavraId, 7);
      expect(q.word, 'enorme');
      expect(q.highlightWord, 'enorme');
      // Marcadores «» saem do enunciado (destaque vira cor, não caractere).
      expect(q.stem, 'O que enorme quer dizer?');
      expect(q.stem, isNot(anyOf(contains('«'), contains('»'))));
      expect([for (final o in q.options) o.key], ['A', 'B', 'C', 'D']);
      // Cliente fino: nenhuma opção carrega a correta.
      expect(q.options.any((o) => o.correct), isFalse);
    });

    test('N3 vira completar e normaliza a lacuna para o token do painel', () {
      final step = SessaoMapper.stepDe(_questao(
          nivel: 3, enunciado: 'Complete: «O elefante é um animal ___.»'));
      final q = (step as QuestionStep).question;
      expect(q.kind, QuestionKind.completar);
      expect(q.blank, isTrue);
      expect(q.stem, contains('_____'));
      expect(q.highlightWord, isNull);
    });

    test('N4 vira julgar uso com a palavra em negrito nas frases', () {
      final step = SessaoMapper.stepDe(
          _questao(nivel: 4, enunciado: 'Em qual frase «enorme» faz sentido?'));
      final q = (step as QuestionStep).question;
      expect(q.kind, QuestionKind.julgarUso);
      expect(q.options.first.boldWord, 'enorme');
    });
  });

  group('SessaoMapper.conquistaDe', () {
    test('cartao_postal resolve cidade e país pelo snapshot da trilha', () {
      const recompensa = RecompensaDto(
          tipo: 'cartao_postal',
          colecionavelId: 5,
          referencia: 'destino:12',
          assetRef: null);
      final conquista = SessaoMapper.conquistaDe(recompensa, _trilha());
      expect(conquista, isA<ConquistaPostal>());
      final postal = conquista as ConquistaPostal;
      expect(postal.destino.cidade, 'Rio de Janeiro');
      expect(postal.pais, Pais.brasil);
      expect(postal.colecionavelId, 5); // persiste o reveal por este id
    });

    test('carimbo resolve o país; selo fica para a fila do Passaporte', () {
      const carimbo = RecompensaDto(
          tipo: 'carimbo', colecionavelId: 9, referencia: 'pais:1', assetRef: null);
      final conquista = SessaoMapper.conquistaDe(carimbo, _trilha());
      expect(conquista, isA<ConquistaCarimbo>());
      expect((conquista as ConquistaCarimbo).pais, Pais.brasil);

      const selo = RecompensaDto(
          tipo: 'selo',
          colecionavelId: 21,
          referencia: 'feito:combo_10',
          assetRef: null);
      expect(SessaoMapper.conquistaDe(selo, _trilha()), isNull);
    });
  });

  group('SessaoMapper.summaryDe', () {
    test('monta o Resumo com números do servidor e contexto do nó jogado', () {
      final summary = SessaoMapper.summaryDe(
        fim: const ResumoFimDto(
          xpGanho: 480,
          xpTotal: 3600,
          palavrasDominadas: 24,
          nivelAnterior: 2,
          nivelAtual: 2,
          nivelMudou: false,
          sessoesTotal: 9,
        ),
        trilha: _trilha(),
        combo: 5,
        palavras: const [
          WordProgress(word: 'enorme', change: WordChange.dominated),
        ],
        recompensas: const [
          RecompensaDto(
              tipo: 'cartao_postal',
              colecionavelId: 5,
              referencia: 'destino:12',
              assetRef: null),
        ],
      );

      expect(summary.city, 'Rio de Janeiro');
      expect(summary.lesson, 3); // 2 nós concluídos no destino → lição 3
      expect(summary.xpGained, 480);
      expect(summary.xpFrom, 3120); // xp_total - xp_ganho, pelo servidor
      expect(summary.xpTo, 3600);
      expect(summary.xpTarget, 4500);
      expect(summary.combo, 5);
      expect(summary.level, 7); // 6 nós concluídos na trilha + 1
      expect(summary.words.single.word, 'enorme');
      expect(summary.achievement, isNotNull);
      expect(summary.achievement!.conquista, isA<ConquistaPostal>());
    });

    test('sem combo e sem recompensas: chip oculto e sem teaser', () {
      final summary = SessaoMapper.summaryDe(
        fim: const ResumoFimDto(
          xpGanho: 100,
          xpTotal: 3700,
          palavrasDominadas: 24,
          nivelAnterior: 2,
          nivelAtual: 3,
          nivelMudou: true,
          sessoesTotal: 10,
        ),
        trilha: _trilha(),
        combo: 0,
        palavras: const [],
        recompensas: const [],
      );
      expect(summary.combo, isNull);
      expect(summary.achievement, isNull);
    });
  });
}
