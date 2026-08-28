import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/api_providers.dart';
import 'models.dart';
import 'repository.dart';

// Providers de infra agora vivem em `core/api_providers.dart`. Re-exportados
// aqui para não quebrar quem já os importava da identidade.
export '../../core/api_providers.dart' show tokenStoreProvider, apiClientProvider;

final identidadeRepositoryProvider = Provider<IdentidadeRepository>(
  (ref) => IdentidadeRepository(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
  ),
);

/// Estado de sessão do app (B2C, docs/plano_b2c.md Fase 1):
///
/// - [Deslogado]: sem token válido — mostra a Entrada.
/// - [AguardandoPerfil]: token de responsável ativo, ainda sem escolher (ou
///   sem ter) um perfil de criança — mostra o seletor (ou "criar 1º perfil").
/// - [Autenticado]: token de gameplay ativo — mostra a Home (ou o
///   Onboarding, se o perfil acabou de ser criado nesta sessão).
sealed class SessaoState {
  const SessaoState();
}

final class Deslogado extends SessaoState {
  const Deslogado();
}

final class AguardandoPerfil extends SessaoState {
  const AguardandoPerfil(this.perfis);
  final List<PerfilCrianca> perfis;
}

final class Autenticado extends SessaoState {
  const Autenticado(this.me);
  final Me me;
}

/// Atalho para quem só quer o [Me] quando há um perfil de criança logado
/// (a maioria das telas de gameplay) — `null` em qualquer outro estado.
extension SessaoStateMe on SessaoState {
  Me? get meOuNull => switch (this) {
        Autenticado(me: final me) => me,
        _ => null,
      };
}

/// Controla a sessão do app. `AsyncValue<SessaoState>`: carregando (checando
/// token), erro, ou um dos três estados acima. Cliente fino: o estado é
/// sempre derivado do que o servidor responde, nunca guardado só no app.
class AuthController extends AsyncNotifier<SessaoState> {
  IdentidadeRepository get _repo => ref.read(identidadeRepositoryProvider);

  @override
  Future<SessaoState> build() async {
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null) return const Deslogado();
    return _resolverToken();
  }

  /// Tenta `/me` (token de criança); se o token for de responsável (403),
  /// cai para a lista de perfis; se o token for inválido (401), desloga.
  Future<SessaoState> _resolverToken() async {
    try {
      return Autenticado(await _repo.me());
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        try {
          return AguardandoPerfil(await _repo.listarPerfis());
        } on ApiException {
          await _repo.sair();
          return const Deslogado();
        }
      }
      await _repo.sair();
      return const Deslogado();
    }
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required bool aceiteTermos,
    required bool consentimentoLgpd,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.cadastrar(
        nome: nome,
        email: email,
        senha: senha,
        aceiteTermos: aceiteTermos,
        consentimentoLgpd: consentimentoLgpd,
      );
      return const AguardandoPerfil([]);
    });
  }

  Future<void> login({required String email, required String senha}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.login(email: email, senha: senha);
      final perfis = await _repo.listarPerfis();
      // Conveniência: com um único filho, pula direto o seletor.
      if (perfis.length == 1) {
        await _repo.entrarComoCrianca(perfis.first.usuarioId);
        return Autenticado(await _repo.me());
      }
      return AguardandoPerfil(perfis);
    });
  }

  /// Cria o perfil e já entra nele — é a criança recém-criada quem vai jogar,
  /// então marca o onboarding pendente (ver [OnboardingPendente]).
  Future<void> criarPerfilEEntrar({
    required String apelido,
    required int anoNascimento,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final perfil = await _repo.criarPerfil(
        apelido: apelido,
        anoNascimento: anoNascimento,
      );
      await _repo.entrarComoCrianca(perfil.usuarioId);
      final me = await _repo.me();
      ref.read(onboardingPendenteProvider.notifier).marcar();
      return Autenticado(me);
    });
  }

  Future<void> entrarComoCrianca(int perfilUsuarioId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.entrarComoCrianca(perfilUsuarioId);
      return Autenticado(await _repo.me());
    });
  }

  Future<void> sair() async {
    await _repo.sair();
    state = const AsyncValue.data(Deslogado());
  }

  /// Exclui a conta do responsável (R-ID-6, Área do Responsável). Lança
  /// [ApiException] em falha (ex.: senha errada) — a tela mantém a sessão
  /// atual pra tentar de novo.
  Future<void> excluirConta({required String senha}) async {
    await _repo.excluirConta(senha: senha);
    state = const AsyncValue.data(Deslogado());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, SessaoState>(AuthController.new);

/// Onboarding pendente **nesta sessão de app**: `true` logo após criar um
/// perfil novo; o fim do onboarding (ou o "Pular") desliga. Não persiste de
/// propósito: o `/me` não expõe "fez o diagnóstico", e a filosofia é
/// "diagnóstico leve + adaptação forte" — quem fechar o app no meio começa no
/// nível padrão e a adaptação corrige.
class OnboardingPendente extends Notifier<bool> {
  @override
  bool build() => false;

  void marcar() => state = true;

  void concluir() => state = false;
}

final onboardingPendenteProvider =
    NotifierProvider<OnboardingPendente, bool>(OnboardingPendente.new);
