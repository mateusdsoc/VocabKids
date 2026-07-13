import '../../../core/api_client.dart';
import 'passaporte_models.dart';

/// Acesso a dados do Passaporte. Cliente fino — a fila de reveals pendentes é
/// derivada do servidor (`conquistado && !revelado`); o app só espelha.
class PassaporteRepository {
  PassaporteRepository(this._api);

  final ApiClient _api;

  /// `GET /v1/passaporte` — a coleção completa (até 28), com pendentes.
  Future<PassaporteDto> carregar() async {
    final json = await _api.get('/passaporte');
    return PassaporteDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/passaporte/{id}/revelado` — o Modo Conquista tocou este item.
  /// Idempotente no servidor: repetir num retry de rede não tem efeito.
  Future<void> marcarRevelado(int colecionavelId) async {
    await _api.post('/passaporte/$colecionavelId/revelado');
  }
}
