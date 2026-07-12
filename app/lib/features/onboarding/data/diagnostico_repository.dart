import '../../../core/api_client.dart';
import 'diagnostico_models.dart';

/// Acesso a dados do diagnóstico: `POST /v1/onboarding/diagnostico`.
/// Cliente fino — não corrige nem entende a escada, só transporta o passo.
class DiagnosticoRepository {
  DiagnosticoRepository(this._api);

  final ApiClient _api;

  /// Sem [estado], inicia o diagnóstico; com ele, responde a questão atual.
  Future<DiagnosticoPasso> passo({
    Map<String, dynamic>? estado,
    int? questaoId,
    String? opcao,
  }) async {
    final json = await _api.post('/onboarding/diagnostico', body: {
      'estado': estado,
      'questao_id': questaoId,
      'opcao': opcao,
    });
    return DiagnosticoPasso.fromJson(json as Map<String, dynamic>);
  }
}
