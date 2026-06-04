import '../../core/api_client.dart';
import '../../core/token_store.dart';
import 'models.dart';

/// Acesso a dados da identidade: fala com `/v1/acesso/turma` e `/v1/me`.
/// Persiste o token após o acesso para as chamadas autenticadas seguintes.
class IdentidadeRepository {
  IdentidadeRepository({required ApiClient api, required TokenStore tokens})
      // ignore: prefer_initializing_formals -- params públicos (api/tokens) ≠ campos privados
      : _api = api,
        // ignore: prefer_initializing_formals
        _tokens = tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  /// Entra por código de turma (acha-ou-cria o aluno) e guarda o token.
  Future<AcessoTurma> acessarPorTurma({
    required String codigoTurma,
    required String nome,
  }) async {
    final json = await _api.post(
      '/acesso/turma',
      auth: false,
      body: {'codigo_turma': codigoTurma, 'nome': nome},
    );
    final acesso = AcessoTurma.fromJson(json as Map<String, dynamic>);
    await _tokens.save(acesso.token);
    return acesso;
  }

  /// Perfil + progresso do aluno autenticado.
  Future<Me> me() async {
    final json = await _api.get('/me');
    return Me.fromJson(json as Map<String, dynamic>);
  }

  Future<void> sair() => _tokens.clear();
}
