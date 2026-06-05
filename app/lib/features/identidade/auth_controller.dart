import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/token_store.dart';
import 'models.dart';
import 'repository.dart';

// --- Providers de infraestrutura (substituíveis em teste) ---

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);

final identidadeRepositoryProvider = Provider<IdentidadeRepository>(
  (ref) => IdentidadeRepository(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
  ),
);

/// Estado de autenticação do app.
///
/// `AsyncValue<Me?>`: carregando (checando token), erro, ou um dado —
/// `null` = deslogado, `Me` = aluno autenticado. Cliente fino: o `Me` é a
/// verdade do servidor, não estado derivado no app.
class AuthController extends AsyncNotifier<Me?> {
  IdentidadeRepository get _repo => ref.read(identidadeRepositoryProvider);

  @override
  Future<Me?> build() async {
    // Na abertura, tenta restaurar a sessão a partir do token guardado.
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null) return null;
    try {
      return await _repo.me();
    } on ApiException {
      // Token inválido/expirado: limpa e segue deslogado, sem travar a abertura.
      await _repo.sair();
      return null;
    }
  }

  /// Entra por código de turma e carrega o perfil.
  Future<void> entrar({required String codigoTurma, required String nome}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.acessarPorTurma(codigoTurma: codigoTurma, nome: nome);
      return _repo.me();
    });
  }

  Future<void> sair() async {
    await _repo.sair();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Me?>(AuthController.new);
