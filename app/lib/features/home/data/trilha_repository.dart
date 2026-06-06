import '../../../core/api_client.dart';
import 'trilha_models.dart';

/// Acesso a dados da trilha: lê `GET /v1/trilha` (mapa, nó atual, "você está
/// aqui"). Cliente fino — não calcula progresso, só desserializa.
class TrilhaRepository {
  TrilhaRepository(this._api);

  final ApiClient _api;

  Future<Trilha> carregar() async {
    final json = await _api.get('/trilha');
    return Trilha.fromJson(json as Map<String, dynamic>);
  }
}
