import '../../../core/api_client.dart';
import 'redacao_models.dart';

/// Acesso a dados da redação server-side. Cliente fino — o backend faz a
/// triagem de risco e a análise pedagógica; o app só chama e desserializa.
class RedacaoRepository {
  RedacaoRepository(this._api);

  final ApiClient _api;

  /// `GET /v1/redacoes` — efeito colateral no servidor: garante a atribuição
  /// atual (best-effort), então esta chamada nunca deve ser cacheada por
  /// muito tempo.
  Future<RedacoesDto> listar() async {
    final json = await _api.get('/redacoes');
    return RedacoesDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/redacoes/{atribuicaoId}/enviar` — síncrona: só retorna após
  /// triagem de risco + análise (chamada ao Claude) terminarem no servidor.
  Future<EnviarRedacaoOutDto> enviar({
    required int atribuicaoId,
    required String formato,
    required String textoExtraido,
  }) async {
    final json = await _api.post(
      '/redacoes/$atribuicaoId/enviar',
      body: {'formato': formato, 'texto_extraido': textoExtraido},
    );
    return EnviarRedacaoOutDto.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /v1/redacoes/{redacaoId}/analise`.
  Future<AnaliseOutDto> analise(int redacaoId) async {
    final json = await _api.get('/redacoes/$redacaoId/analise');
    return AnaliseOutDto.fromJson(json as Map<String, dynamic>);
  }
}
