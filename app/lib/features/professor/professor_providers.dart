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

  if (AppConfig.demo) return PainelData.sample(turmaId);
  final painel = await ref.watch(professorRepositoryProvider).painel(turmaId);
  return ProfessorMapper.painel(painel);
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
