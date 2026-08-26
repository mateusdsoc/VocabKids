import '../../../core/api_client.dart';
import 'responsavel_models.dart';

/// Acesso a dados da Área do Responsável (`backend/app/responsavel/`).
/// Cliente fino: o backend valida o PIN contra o hash e calcula o resumo; o
/// app só chama e desserializa.
class ResponsavelRepository {
  ResponsavelRepository(this._api);

  final ApiClient _api;

  /// `GET /v1/conta/pin` — se o PIN já foi definido alguma vez.
  Future<PinStatusDto> pinStatus() async {
    final json = await _api.get('/conta/pin');
    return PinStatusDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/conta/pin` — define ou troca o PIN (R-RS-1). Não exige o PIN
  /// antigo: quem já chega aqui tem o token do responsável (login completo).
  Future<void> definirPin(String pin) async {
    await _api.post('/conta/pin', body: {'pin': pin});
  }

  /// `POST /v1/conta/pin/verificar` — portão antes de qualquer dado (R-RS-1).
  /// Lança [ApiException] com `code: 'pin_invalido'` (401) se errado.
  Future<void> verificarPin(String pin) async {
    await _api.post('/conta/pin/verificar', body: {'pin': pin});
  }

  /// `GET /v1/responsavel/perfis/{id}/resumo`.
  Future<ResumoSemanalDto> resumoSemanal(int perfilUsuarioId) async {
    final json = await _api.get('/responsavel/perfis/$perfilUsuarioId/resumo');
    return ResumoSemanalDto.fromJson(json as Map<String, dynamic>);
  }
}
