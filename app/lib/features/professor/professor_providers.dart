import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_providers.dart';
import '../../core/config.dart';
import 'data/professor_repository.dart';
import 'professor_data.dart';
import 'professor_mapper.dart';

/// Escopo do painel (produto §3.11): professor vê/configura a própria turma;
/// coordenador vê a escola inteira, só leitura. Mesmas telas, via toggle.
enum ProfessorScope { turma, escola }

class ProfessorScopeNotifier extends Notifier<ProfessorScope> {
  @override
  ProfessorScope build() => ProfessorScope.turma;
  void set(ProfessorScope scope) => state = scope;
}

final professorScopeProvider =
    NotifierProvider<ProfessorScopeNotifier, ProfessorScope>(
        ProfessorScopeNotifier.new);

/// Turma selecionada no escopo professor; `null` = usar a primeira.
class TurmaSelecionadaNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? turmaId) => state = turmaId;
}

final turmaSelecionadaProvider =
    NotifierProvider<TurmaSelecionadaNotifier, int?>(
        TurmaSelecionadaNotifier.new);

/// Repositório do professor, reusando o [apiClientProvider] do `core/` (mesmo
/// token/transporte do aluno; sem importar `features/identidade/`).
final professorRepositoryProvider = Provider<ProfessorRepository>(
  (ref) => ProfessorRepository(ref.watch(apiClientProvider)),
);

/// Turmas do professor (para o seletor de turma).
final turmasProvider = FutureProvider.autoDispose<List<TurmaRef>>((ref) async {
  if (AppConfig.demo) return TurmaRef.sampleList;
  final dtos = await ref.watch(professorRepositoryProvider).turmas();
  return ProfessorMapper.turmaRefs(dtos);
});

/// Painel da turma selecionada (escopo professor). Reage à seleção de turma.
final painelTurmaProvider = FutureProvider.autoDispose<PainelData>((ref) async {
  final turmas = await ref.watch(turmasProvider.future);
  if (turmas.isEmpty) {
    throw StateError('Professor sem turmas vinculadas.');
  }
  final turmaId = ref.watch(turmaSelecionadaProvider) ?? turmas.first.id;

  final painel = AppConfig.demo
      ? PainelData.sample(turmaId)
      : ProfessorMapper.painel(
          await ref.watch(professorRepositoryProvider).painel(turmaId));

  // Reflexão otimista da meta recém-configurada (fase 5). Na fatia A o mock não
  // persiste; na fatia C o valor já vem do servidor e o override fica redundante.
  final meta = ref.watch(metaOverridesProvider)[turmaId];
  return meta == null ? painel : painel.comMeta(meta);
});

/// Painel agregado da escola (escopo coordenador, só leitura).
final painelEscolaProvider =
    FutureProvider.autoDispose<EscolaPainelData>((ref) async {
  if (AppConfig.demo) return EscolaPainelData.sample();
  final escola = await ref.watch(professorRepositoryProvider).escola();
  return ProfessorMapper.escola(escola);
});

/// Detalhe de um aluno (drill-down do painel). `family` pelo id — cada aluno
/// tem o próprio cache; `autoDispose` libera ao fechar a tela.
final alunoDetalheProvider =
    FutureProvider.autoDispose.family<AlunoDetalhe, int>((ref, alunoId) async {
  if (AppConfig.demo) return AlunoDetalhe.sample(alunoId);
  final dto = await ref.watch(professorRepositoryProvider).aluno(alunoId);
  return ProfessorMapper.alunoDetalhe(dto);
});

/// Ação de **atribuir redação** (§4.6). `AsyncValue<RedacaoAtribuicao?>`:
/// `null` = nada enviado ainda; `loading` durante o POST; `data`/`error` no fim
/// (mesmo padrão do `AuthController`). A decisão DEMO vive aqui, não no widget.
class AtribuirRedacaoController extends AsyncNotifier<RedacaoAtribuicao?> {
  @override
  Future<RedacaoAtribuicao?> build() async => null;

  /// Atribui e devolve a redação criada (ou `null` em erro — o estado guarda o
  /// erro). [prazo] nulo = sem prazo.
  Future<RedacaoAtribuicao?> atribuir({
    required int turmaId,
    required String tema,
    required DateTime? prazo,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final temaLimpo = tema.trim();
      final prazoIso = prazo == null ? null : _isoDate(prazo);
      if (AppConfig.demo) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        return RedacaoAtribuicao(
            id: 0, turmaId: turmaId, tema: temaLimpo, prazo: prazoIso);
      }
      final dto = await ref.read(professorRepositoryProvider).atribuirRedacao(
            turmaId: turmaId,
            tema: temaLimpo,
            prazo: prazoIso,
          );
      return ProfessorMapper.redacaoAtribuicao(dto);
    });
    return state.value;
  }
}

final atribuirRedacaoProvider =
    AsyncNotifierProvider<AtribuirRedacaoController, RedacaoAtribuicao?>(
        AtribuirRedacaoController.new);

/// Metas configuradas nesta sessão (turmaId → meta), para o painel refletir
/// **otimisticamente** o que o professor acabou de definir (§3.5). Estado de UI;
/// a verdade persistida vira do servidor na fatia C.
class MetaOverridesNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const {};
  void definir(int turmaId, int meta) => state = {...state, turmaId: meta};
}

final metaOverridesProvider =
    NotifierProvider<MetaOverridesNotifier, Map<int, int>>(
        MetaOverridesNotifier.new);

/// Ação de **configurar a meta semanal** (§3.5; só professor). `AsyncValue<int?>`
/// (`null` = nada enviado). No sucesso, registra o override para o painel
/// refletir na hora. DEMO simula sem backend.
class MetaController extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async => null;

  /// Define a meta e devolve o valor confirmado (ou `null` em erro).
  Future<int?> atualizar({required int turmaId, required int metaSemanal}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (AppConfig.demo) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return metaSemanal;
      }
      return ref
          .read(professorRepositoryProvider)
          .atualizarMeta(turmaId: turmaId, metaSemanal: metaSemanal);
    });
    final ok = state.value;
    if (ok != null) ref.read(metaOverridesProvider.notifier).definir(turmaId, ok);
    return ok;
  }
}

final metaProvider =
    AsyncNotifierProvider<MetaController, int?>(MetaController.new);

/// `DateTime` → `yyyy-mm-dd` (data local, sem hora — é um prazo).
String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
