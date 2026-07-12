import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../identidade/auth_controller.dart' show apiClientProvider;
import 'data/diagnostico_models.dart';
import 'data/diagnostico_repository.dart';

final diagnosticoRepositoryProvider = Provider<DiagnosticoRepository>(
  (ref) => DiagnosticoRepository(ref.watch(apiClientProvider)),
);

/// Diálogo do diagnóstico com o servidor (escada grosso→fino, Bloco 2a).
///
/// O `build` abre o diagnóstico (POST sem estado) e cada [responder] devolve
/// o passo seguinte — o app reenvia o `estado` opaco e mostra a questão que
/// vier; correção e nível são do servidor. `autoDispose`: voltar ao passo do
/// onboarding recomeça a etapa, como no fluxo demo.
class DiagnosticoController extends AsyncNotifier<DiagnosticoPasso> {
  DiagnosticoRepository get _repo => ref.read(diagnosticoRepositoryProvider);

  @override
  Future<DiagnosticoPasso> build() => _repo.passo();

  /// Responde a questão atual com o **texto** da opção escolhida.
  Future<void> responder(String opcao) async {
    final atual = state.value;
    final questao = atual?.questao;
    if (atual == null || questao == null) return;
    state = await AsyncValue.guard(
      () => _repo.passo(
        estado: atual.estado,
        questaoId: questao.questaoId,
        opcao: opcao,
      ),
    );
  }
}

final diagnosticoControllerProvider =
    AsyncNotifierProvider.autoDispose<DiagnosticoController, DiagnosticoPasso>(
        DiagnosticoController.new);
