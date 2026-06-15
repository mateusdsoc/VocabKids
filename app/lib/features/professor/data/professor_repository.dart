import '../../../core/api_client.dart';
import 'professor_dtos.dart';

/// Acesso a dados da superfície do professor (`GET /v1/professor/...`).
/// Cliente fino — só desserializa; nenhuma regra de domínio aqui.
class ProfessorRepository {
  ProfessorRepository(this._api);

  final ApiClient _api;

  Future<List<TurmaResumoDto>> turmas() async {
    final json = await _api.get('/professor/turmas');
    final list = (json as Map<String, dynamic>)['turmas'] as List;
    return list
        .map((e) => TurmaResumoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PainelDto> painel(int turmaId) async {
    final json = await _api.get('/professor/turmas/$turmaId/painel');
    return PainelDto.fromJson(json as Map<String, dynamic>);
  }

  Future<EscolaPainelDto> escola() async {
    final json = await _api.get('/professor/escola');
    return EscolaPainelDto.fromJson(json as Map<String, dynamic>);
  }

  Future<AlunoDetalheDto> aluno(int alunoId) async {
    final json = await _api.get('/professor/alunos/$alunoId');
    return AlunoDetalheDto.fromJson(json as Map<String, dynamic>);
  }

  /// Atribui uma redação (tema + prazo) à turma (§4.6). O aluno envia depois.
  Future<RedacaoAtribuicaoDto> atribuirRedacao({
    required int turmaId,
    required String tema,
    required String? prazo,
  }) async {
    final json = await _api.post(
      '/professor/turmas/$turmaId/redacoes',
      body: {'tema': tema, 'prazo': prazo},
    );
    return RedacaoAtribuicaoDto.fromJson(json as Map<String, dynamic>);
  }

  /// Configura a meta semanal da turma (§3.5). Devolve a meta confirmada.
  Future<int> atualizarMeta({
    required int turmaId,
    required int metaSemanal,
  }) async {
    final json = await _api.put(
      '/professor/turmas/$turmaId/meta',
      body: {'meta_semanal': metaSemanal},
    );
    return (json as Map<String, dynamic>)['meta_semanal'] as int;
  }
}
