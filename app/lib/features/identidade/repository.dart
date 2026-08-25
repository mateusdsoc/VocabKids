import '../../core/api_client.dart';
import '../../core/token_store.dart';
import 'models.dart';

/// Acesso a dados da identidade B2C: conta do responsável, perfis de criança
/// e sessão (docs/plano_b2c.md Fase 1). Persiste o token corrente após cada
/// troca — a qualquer momento o `TokenStore` guarda **um** token, o da sessão
/// ativa (responsável em meio à seleção de perfil, ou criança já dentro do
/// jogo — nunca os dois ao mesmo tempo).
class IdentidadeRepository {
  IdentidadeRepository({required ApiClient api, required TokenStore tokens})
      // ignore: prefer_initializing_formals -- params públicos (api/tokens) ≠ campos privados
      : _api = api,
        // ignore: prefer_initializing_formals
        _tokens = tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  /// Cadastra a conta do responsável e guarda o token dela.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final json = await _api.post(
      '/conta',
      auth: false,
      body: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'aceite_termos': true,
        'consentimento_lgpd': true,
      },
    );
    await _tokens.save((json as Map<String, dynamic>)['token'] as String);
  }

  /// Login do responsável (e-mail/senha) e guarda o token dele.
  Future<void> login({required String email, required String senha}) async {
    final json = await _api.post(
      '/sessao',
      auth: false,
      body: {'email': email, 'senha': senha},
    );
    await _tokens.save((json as Map<String, dynamic>)['token'] as String);
  }

  /// Dados da conta do responsável + perfis (usado pelo paywall pra obter o
  /// `conta_id` — mesma convenção do RevenueCat `app_user_id`, ver
  /// `AssinaturaRepository.inicializar`).
  Future<Conta> conta() async {
    final json = await _api.get('/conta');
    return Conta.fromJson(json as Map<String, dynamic>);
  }

  /// Perfis de criança da conta (token do responsável precisa estar ativo).
  Future<List<PerfilCrianca>> listarPerfis() async {
    final json = await _api.get('/conta/perfis');
    return (json as List)
        .map((p) => PerfilCrianca.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Cria um novo perfil de criança na conta.
  Future<PerfilCrianca> criarPerfil({
    required String apelido,
    required int anoNascimento,
  }) async {
    final json = await _api.post(
      '/conta/perfis',
      body: {'apelido': apelido, 'ano_nascimento': anoNascimento},
    );
    return PerfilCrianca.fromJson(json as Map<String, dynamic>);
  }

  /// Troca o token do responsável pelo token de gameplay do perfil escolhido.
  Future<void> entrarComoCrianca(int perfilUsuarioId) async {
    final json = await _api.post('/perfis/$perfilUsuarioId/entrar');
    await _tokens.save((json as Map<String, dynamic>)['token'] as String);
  }

  /// Perfil + progresso do perfil de criança autenticado.
  Future<Me> me() async {
    final json = await _api.get('/me');
    return Me.fromJson(json as Map<String, dynamic>);
  }

  /// Exclui a conta do responsável e os dados de todos os perfis (R-ID-6).
  Future<void> excluirConta({required String senha}) async {
    await _api.delete('/conta', body: {'senha': senha});
    await _tokens.clear();
  }

  Future<void> sair() => _tokens.clear();
}
