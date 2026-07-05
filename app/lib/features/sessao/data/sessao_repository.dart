import '../../../core/api_client.dart';
import 'sessao_models.dart';

/// Acesso a dados da sessão server-side. Cliente fino — não corrige, não
/// pontua, não reordena: só chama a API e desserializa.
class SessaoRepository {
  SessaoRepository(this._api);

  final ApiClient _api;

  /// `POST /v1/sessoes` — monta e abre a sessão (fila em lote).
  /// O servidor encerra sozinho uma sessão anterior abandonada.
  Future<SessaoAbertaDto> abrir() async {
    final json = await _api.post('/sessoes');
    return SessaoAbertaDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/sessoes/{id}/respostas` — correção server-side; devolve
  /// XP/combo/estado e a fila restante já reordenada.
  Future<RespostaDto> responder({
    required int sessaoId,
    required int questaoId,
    required String opcao,
  }) async {
    final json = await _api.post(
      '/sessoes/$sessaoId/respostas',
      body: {'questao_id': questaoId, 'opcao': opcao},
    );
    return RespostaDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/sessoes/{id}/fim` — fecha a sessão (resumo + adaptação).
  Future<ResumoFimDto> finalizar(int sessaoId) async {
    final json = await _api.post('/sessoes/$sessaoId/fim');
    return ResumoFimDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/questoes/{id}/report` — motivo predefinido (mock na fatia A;
  /// o pipeline de QA entra na fatia C sem mudar o contrato).
  Future<void> reportar({required int questaoId, required String motivo}) async {
    await _api.post('/questoes/$questaoId/report', body: {'motivo': motivo});
  }
}
