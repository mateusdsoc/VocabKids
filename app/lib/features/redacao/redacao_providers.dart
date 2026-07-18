import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_providers.dart';
import '../../core/config.dart';
import 'data/redacao_repository.dart';
import 'models.dart';
import 'redacao_mapper.dart';

final redacaoRepositoryProvider = Provider<RedacaoRepository>(
  (ref) => RedacaoRepository(ref.watch(apiClientProvider)),
);

/// Atribuições + envios do aluno (`GET /v1/redacoes`).
///
/// `autoDispose`: recarrega fresco a cada abertura da área (o professor pode
/// ter atribuído uma redação nova; a análise pode ter saído). Em `DEMO`, a
/// amostra estática.
final redacoesProvider = FutureProvider.autoDispose<List<Redacao>>((ref) async {
  if (AppConfig.demo) return Redacao.sample();
  final dto = await ref.watch(redacaoRepositoryProvider).carregar();
  return RedacaoMapper.listaDe(dto);
});
