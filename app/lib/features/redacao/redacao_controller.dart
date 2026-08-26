import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_providers.dart';
import '../../core/config.dart';
import 'data/redacao_models.dart';
import 'data/redacao_repository.dart';
import 'models.dart';
import 'redacao_mapper.dart';

final redacaoRepositoryProvider = Provider<RedacaoRepository>(
  (ref) => RedacaoRepository(ref.watch(apiClientProvider)),
);

/// `GET /v1/redacoes` já traduzido para apresentação.
class RedacaoListaEstado {
  const RedacaoListaEstado({
    required this.itens,
    required this.extrasRestantesNoMes,
  });

  final List<Redacao> itens;
  final int extrasRestantesNoMes;
}

/// `autoDispose`: a tela é destino de navegação e o `GET` tem efeito colateral
/// no servidor (garante a atribuição atual) — sempre busca de novo ao entrar,
/// nunca serve uma lista velha.
final redacaoListaProvider =
    FutureProvider.autoDispose<RedacaoListaEstado>((ref) async {
  if (AppConfig.demo) {
    return RedacaoListaEstado(itens: Redacao.sample(), extrasRestantesNoMes: 2);
  }
  final dto = await ref.watch(redacaoRepositoryProvider).listar();
  return RedacaoListaEstado(
    itens: dto.itens.map(RedacaoMapper.redacaoDe).toList(),
    extrasRestantesNoMes: dto.extrasRestantesNoMes,
  );
});

/// `GET /v1/redacoes/{redacaoId}/analise`. Família por id: cada redação
/// enviada tem sua própria análise, buscada só quando a tela é aberta.
final analiseProvider =
    FutureProvider.autoDispose.family<AnaliseOutDto, int>((ref, redacaoId) {
  if (AppConfig.demo) return Future.value(_sampleAnalise(redacaoId));
  return ref.watch(redacaoRepositoryProvider).analise(redacaoId);
});

/// Amostra alinhada a [Redacao.sample]: `102` (analisada) e `103`
/// (erro_ingestao) — os dois desfechos enviados da amostra.
AnaliseOutDto _sampleAnalise(int redacaoId) {
  if (redacaoId == 103) {
    return const AnaliseOutDto(
      redacaoId: 103,
      status: 'erro_ingestao',
      textoExtraido: 'Se eu pudesse mudar o mundo eu ia tentar ajudar.',
      analise: null,
      palavrasNovas: [],
    );
  }
  const texto =
      'O Rio de Janeiro é uma cidade maravilhosa cheia de historia. '
      'Um dos maiores herois brasileiros pra mim é o Zumbi dos Palmares, '
      'que lutou muito pela liberdade de muitas pessoas.';
  return AnaliseOutDto(
    redacaoId: redacaoId,
    status: 'analisada',
    textoExtraido: texto,
    analise: AnaliseDto(
      versao: 1,
      dimensoes: const ['vocabulario', 'ortografia', 'adequacao_ao_tema'],
      pontosFortes: const [
        'Você escolheu um herói real e explicou por que ele importa.',
        'O texto tem começo, meio e fim — dá pra acompanhar a ideia.',
      ],
      anotacoes: [
        AnotacaoDto(
          dimensao: 'ortografia',
          titulo: 'Acento em "história"',
          comentario: '"historia" leva acento: "história".',
          sugestoes: const ['história'],
          ancoras: [
            AncoraDto(
              inicio: texto.indexOf('historia'),
              fim: texto.indexOf('historia') + 'historia'.length,
              trecho: 'historia',
              ocorrencia: 1,
            ),
          ],
        ),
        AnotacaoDto(
          dimensao: 'ortografia',
          titulo: 'Plural de "herói"',
          comentario: 'O plural de "herói" é "heróis", com acento.',
          sugestoes: const ['heróis'],
          ancoras: [
            AncoraDto(
              inicio: texto.indexOf('herois'),
              fim: texto.indexOf('herois') + 'herois'.length,
              trecho: 'herois',
              ocorrencia: 1,
            ),
          ],
        ),
        AnotacaoDto(
          dimensao: 'vocabulario',
          titulo: 'Repetição de "muito"',
          comentario:
              '"muito" aparece duas vezes perto — dá pra variar com "bastante" '
              'ou "tanto".',
          sugestoes: const ['bastante', 'tanto'],
          ancoras: const [],
        ),
      ],
    ),
    palavrasNovas: const [],
  );
}
