import 'data/professor_dtos.dart';
import 'professor_data.dart';

/// Traduz os DTOs do backend (`PainelDto`) para o modelo de apresentação
/// (`PainelData`) que os widgets consomem. Concentra aqui a tradução para que as
/// telas não conheçam o contrato do servidor (mesmo papel do `HomeMapper`).
abstract final class ProfessorMapper {
  static PainelData painel(PainelDto dto) => PainelData(
        turmaNome: dto.turmaNome,
        anoEscolar: dto.anoEscolar,
        alunosAtivos: dto.alunosAtivos,
        alunosTotal: dto.alunosTotal,
        palavrasDominadasSemana: dto.palavrasDominadasSemana,
        metaSemanal: dto.metaSemanal,
        sinalTurma: dto.sinalTurma,
        alunos: dto.alunos
            .map((a) => AlunoLinha(
                  id: a.id,
                  nome: a.nome,
                  palavrasSemana: a.palavrasSemana,
                  metaSemana: a.metaSemana,
                  palavrasDominadas: a.palavrasDominadas,
                ))
            .toList(),
      );

  static EscolaPainelData escola(EscolaPainelDto dto) => EscolaPainelData(
        escolaNome: dto.escolaNome,
        turmasTotal: dto.turmasTotal,
        alunosAtivos: dto.alunosAtivos,
        alunosTotal: dto.alunosTotal,
        palavrasDominadasSemana: dto.palavrasDominadasSemana,
        sinalEscola: dto.sinalEscola,
        turmas: dto.turmas
            .map((t) => TurmaLinha(
                  id: t.id,
                  nome: t.nome,
                  anoEscolar: t.anoEscolar,
                  alunosAtivos: t.alunosAtivos,
                  alunosTotal: t.alunosTotal,
                  palavrasDominadasSemana: t.palavrasDominadasSemana,
                  metaSemanal: t.metaSemanal,
                ))
            .toList(),
      );

  static List<TurmaRef> turmaRefs(List<TurmaResumoDto> dtos) => dtos
      .map((d) => TurmaRef(id: d.id, nome: d.nome, anoEscolar: d.anoEscolar))
      .toList();
}
