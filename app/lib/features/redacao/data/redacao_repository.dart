import 'dart:typed_data';

import '../../../core/api_client.dart';
import 'redacao_models.dart';

/// Acesso a dados da Redação. Cliente fino — status e páginas são do servidor;
/// o app só espelha.
class RedacaoRepository {
  RedacaoRepository(this._api);

  final ApiClient _api;

  /// `GET /v1/redacoes` — atribuições da turma com o envio do aluno.
  Future<RedacoesDto> carregar() async {
    final json = await _api.get('/redacoes');
    return RedacoesDto.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /v1/redacoes/{atribuicao}/envio` — fotos das folhas (ou um PDF),
  /// multipart. Reenviar antes da análise substitui o envio anterior.
  Future<EnvioDto> enviar(
    int atribuicaoId,
    List<({String nome, Uint8List bytes})> paginas,
  ) async {
    final json = await _api.postMultipart(
      '/redacoes/$atribuicaoId/envio',
      campo: 'arquivos',
      arquivos: paginas,
    );
    return EnvioDto.fromJson(json as Map<String, dynamic>);
  }
}
