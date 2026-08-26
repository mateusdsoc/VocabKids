import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_providers.dart';
import '../../core/config.dart';
import '../identidade/auth_controller.dart' show identidadeRepositoryProvider;
import '../identidade/models.dart';
import 'data/responsavel_models.dart';
import 'data/responsavel_repository.dart';

final responsavelRepositoryProvider = Provider<ResponsavelRepository>(
  (ref) => ResponsavelRepository(ref.watch(apiClientProvider)),
);

/// `GET /v1/conta/pin` — se já existe PIN definido (decide entre "criar PIN"
/// e "digite o PIN" no portão). `autoDispose`: relido a cada vez que o portão
/// abre, nunca cacheado entre sessões da Área do Responsável.
final pinStatusProvider = FutureProvider.autoDispose<PinStatusDto>((ref) {
  if (AppConfig.demo) return Future.value(const PinStatusDto(definido: true));
  return ref.watch(responsavelRepositoryProvider).pinStatus();
});

/// Conta do responsável (nome, e-mail, perfis) — mesma fonte que o paywall
/// usa para o `conta_id`, reaproveitada aqui para listar os filhos.
final contaProvider = FutureProvider.autoDispose<Conta>((ref) {
  if (AppConfig.demo) return Future.value(_contaDemo);
  return ref.watch(identidadeRepositoryProvider).conta();
});

/// `GET /v1/responsavel/perfis/{id}/resumo`. Família por perfil: cada filho
/// tem seu próprio resumo, buscado só quando a tela é aberta.
final resumoSemanalProvider =
    FutureProvider.autoDispose.family<ResumoSemanalDto, int>((ref, perfilUsuarioId) {
  if (AppConfig.demo) return Future.value(_resumoDemo(perfilUsuarioId));
  return ref.watch(responsavelRepositoryProvider).resumoSemanal(perfilUsuarioId);
});

final _contaDemo = Conta(
  contaId: 1,
  nomeResponsavel: 'Responsável Demo',
  email: 'demo@vocabkids.app',
  perfis: [
    PerfilCrianca(usuarioId: 1, apelido: 'Manu', faixaEtaria: '9-10', anoEscolar: 5),
  ],
);

ResumoSemanalDto _resumoDemo(int perfilUsuarioId) => ResumoSemanalDto(
      perfilUsuarioId: perfilUsuarioId,
      apelido: 'Manu',
      palavrasDominadas: const MetaSemanalDto(atual: 6, alvo: 10),
      minutosNaSemana: 42,
      sessoesNaSemana: 5,
      aprendeuEssaSemana: const [
        PalavraAprendidaDto(palavra: 'enorme', definicao: 'muito grande'),
        PalavraAprendidaDto(palavra: 'veloz', definicao: 'muito rápido'),
        PalavraAprendidaDto(palavra: 'belo', definicao: 'bonito, agradável de ver'),
        PalavraAprendidaDto(
            palavra: 'relevante', definicao: 'importante, que faz diferença'),
        PalavraAprendidaDto(palavra: 'sereno', definicao: 'calmo, tranquilo'),
      ],
      evolucaoRedacao: [
        NivelDimensaoDto(
          redacaoId: 102,
          analisadaEm: DateTime.now().subtract(const Duration(days: 2)),
          niveis: const {
            'vocabulario': 'avançando',
            'ortografia': 'consolidando',
            'adequacao_ao_tema': 'dominando',
          },
        ),
      ],
    );
