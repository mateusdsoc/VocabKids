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
}
