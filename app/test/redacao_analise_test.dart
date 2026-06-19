import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/redacao/analise.dart';

/// Garante o que pode quebrar em silêncio na correção: as âncoras precisam cair
/// no trecho certo do texto (offsets em code points) e o `fromJson` precisa
/// espelhar o contrato do backend (`AnaliseOut`).
void main() {
  group('AnaliseRedacao.demo', () {
    test('só a redação 2 está analisada no mock', () {
      expect(AnaliseRedacao.demo(2), isNotNull);
      expect(AnaliseRedacao.demo(1), isNull);
      expect(AnaliseRedacao.demo(99), isNull);
    });

    test('cada âncora recorta exatamente o trecho que marcou', () {
      final a = AnaliseRedacao.demo(2)!;
      expect(a.analisada, isTrue);
      // "muito" aparece 3x, "heroi"/"tambem"/"legal"/"mas" 1x.
      final esperado = {
        'an_1': ['muito', 'muito', 'muito'],
        'an_2': ['heroi'],
        'an_3': ['legal'],
        'an_4': ['mas'],
        'an_5': ['tambem'],
      };
      for (final anot in a.anotacoes) {
        final trechos = esperado[anot.id];
        if (trechos == null) continue; // holística (an_6) não tem âncora
        expect(anot.ancoras.length, trechos.length, reason: anot.id);
        for (var i = 0; i < trechos.length; i++) {
          final anc = anot.ancoras[i];
          expect(a.textoExtraido.substring(anc.inicio, anc.fim), trechos[i],
              reason: '${anot.id}[$i]');
        }
      }
    });

    test('as 3 ocorrências de "muito" têm offsets distintos e crescentes', () {
      final an1 = AnaliseRedacao.demo(2)!.anotacoes.firstWhere((a) => a.id == 'an_1');
      final inicios = [for (final anc in an1.ancoras) anc.inicio];
      expect(inicios, equals([...inicios]..sort()));
      expect(inicios.toSet().length, 3); // sem repetição
    });

    test('an_6 (coesão) é holística — sem grifo, vira nota', () {
      final a = AnaliseRedacao.demo(2)!;
      final an6 = a.anotacoes.firstWhere((x) => x.id == 'an_6');
      expect(an6.holistica, isTrue);
      expect(a.holisticas, contains(an6));
      expect(a.ancoradas, isNot(contains(an6)));
    });

    test('palavras novas fecham o loop (gatilho → palavra)', () {
      final a = AnaliseRedacao.demo(2)!;
      expect(a.palavrasNovas.length, 2);
      final muito = a.palavrasNovas.firstWhere((p) => p.gatilho == 'muito');
      expect(muito.palavra, 'bastante');
      expect(muito.anotacaoId, 'an_1');
    });
  });

  group('AnaliseRedacao.fromJson', () {
    test('espelha o contrato AnaliseOut do backend', () {
      final json = {
        'mock': true,
        'redacao_id': 2,
        'status': 'analisada',
        'texto_extraido': 'Meu heroi.',
        'analise': {
          'versao': 1,
          'dimensoes': ['vocabulario', 'acentuacao'],
          'pontos_fortes': ['Bom começo'],
          'anotacoes': [
            {
              'id': 'an_2',
              'dimensao': 'acentuacao',
              'subtipo': null,
              'titulo': 'Faltou um acento',
              'comentario': '“Heroi” leva acento.',
              'sugestoes': ['herói'],
              'ancoras': [
                {'inicio': 4, 'fim': 9, 'trecho': 'heroi', 'ocorrencia': 1}
              ],
            }
          ],
        },
        'palavras_novas': [
          {'palavra': 'bastante', 'gatilho': 'muito', 'anotacao_id': 'an_1'}
        ],
      };
      final a = AnaliseRedacao.fromJson(json);
      expect(a.analisada, isTrue);
      expect(a.dimensoes, [Dimensao.vocabulario, Dimensao.acentuacao]);
      expect(a.pontosFortes, ['Bom começo']);
      expect(a.anotacoes.single.dimensao, Dimensao.acentuacao);
      expect(a.anotacoes.single.ancoras.single.inicio, 4);
      expect(a.marcasDe(Dimensao.acentuacao), 1);
      expect(a.palavrasNovas.single.palavra, 'bastante');
    });

    test('status não-analisado vira correção vazia, sem quebrar', () {
      final a = AnaliseRedacao.fromJson({
        'status': 'em_analise',
        'texto_extraido': '',
        'analise': null,
        'palavras_novas': [],
      });
      expect(a.analisada, isFalse);
      expect(a.anotacoes, isEmpty);
      expect(a.pontosFortes, isEmpty);
    });

    test('Dimensao.fromId desconhecida cai em vocabulario (não lança)', () {
      expect(Dimensao.fromId('xpto'), Dimensao.vocabulario);
    });
  });
}
