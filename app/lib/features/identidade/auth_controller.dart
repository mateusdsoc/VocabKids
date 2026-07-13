import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/api_providers.dart';
import 'models.dart';
import 'repository.dart';

// Providers de infra agora vivem em `core/api_providers.dart` (compartilhados com
// a superfície do professor). Re-exportados aqui para não quebrar quem já os
// importava da identidade.
export '../../core/api_providers.dart' show tokenStoreProvider, apiClientProvider;

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

  /// Entra por código de turma e carrega o perfil. Aluno criado agora
  /// (`novo` do acesso) marca o onboarding como pendente — o gate o mostra
  /// antes da Home.
  Future<void> entrar({required String codigoTurma, required String nome}) async {
    state = const AsyncValue.loading();
    var novo = false;
    state = await AsyncValue.guard(() async {
      final acesso =
          await _repo.acessarPorTurma(codigoTurma: codigoTurma, nome: nome);
      novo = acesso.novo;
      return _repo.me();
    });
    if (novo && state.hasValue) {
      ref.read(onboardingPendenteProvider.notifier).marcar();
    }
  }

  Future<void> sair() async {
    await _repo.sair();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Me?>(AuthController.new);

/// Onboarding pendente **nesta sessão de app**: `true` logo após criar a
/// conta (`novo` do `/acesso/turma`); o fim do onboarding (ou o "Pular")
/// desliga. Não persiste de propósito: o `/me` não expõe "fez o diagnóstico",
/// e a filosofia é "diagnóstico leve + adaptação forte" — quem fechar o app
/// no meio começa no nível padrão e a adaptação corrige.
class OnboardingPendente extends Notifier<bool> {
  @override
  bool build() => false;

  void marcar() => state = true;

  void concluir() => state = false;
}

final onboardingPendenteProvider =
    NotifierProvider<OnboardingPendente, bool>(OnboardingPendente.new);
