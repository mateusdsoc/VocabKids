import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_providers.dart';
import '../../core/config.dart';
import 'analise.dart';

/// Acesso a dados da Redação. Cliente fino: lê `GET /v1/redacoes/{id}/analise`
/// e desserializa — nenhuma regra de correção vive no app.
class RedacaoRepository {
  RedacaoRepository(this._api);

  final ApiClient _api;

  Future<AnaliseRedacao> analise(int redacaoId) async {
    final json = await _api.get('/redacoes/$redacaoId/analise');
    return AnaliseRedacao.fromJson(json as Map<String, dynamic>);
  }
}

final redacaoRepositoryProvider = Provider<RedacaoRepository>(
  (ref) => RedacaoRepository(ref.watch(apiClientProvider)),
);

/// Correção de uma redação. Em demo serve a amostra do apresentável (sem
/// backend); ligado, busca a rota real (mesmo contrato). `autoDispose` porque a
/// tela de resultado é destino de navegação.
final analiseRedacaoProvider =
    FutureProvider.autoDispose.family<AnaliseRedacao?, int>((ref, redacaoId) async {
  if (AppConfig.demo) return AnaliseRedacao.demo(redacaoId);
  return ref.watch(redacaoRepositoryProvider).analise(redacaoId);
});
