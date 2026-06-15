/// DTOs do domínio professor — espelham os schemas Pydantic do backend
/// (`backend/app/professor/routes.py`). Apenas desserialização (cliente fino);
/// a tradução para o modelo de apresentação fica no `ProfessorMapper`.
library;

class TurmaResumoDto {
  TurmaResumoDto({
    required this.id,
    required this.nome,
    required this.anoEscolar,
    required this.alunosAtivos,
    required this.metaSemanal,
  });

  final int id;
  final String nome;
  final int anoEscolar;
  final int alunosAtivos;
  final int metaSemanal;

  factory TurmaResumoDto.fromJson(Map<String, dynamic> j) => TurmaResumoDto(
        id: j['id'] as int,
        nome: j['nome'] as String,
        anoEscolar: j['ano_escolar'] as int,
        alunosAtivos: j['alunos_ativos'] as int,
        metaSemanal: j['meta_semanal'] as int,
      );
}

class AlunoPainelDto {
  AlunoPainelDto({
    required this.id,
    required this.nome,
    required this.palavrasSemana,
    required this.metaSemana,
    required this.palavrasDominadas,
  });

  final int id;
  final String nome;
  final int palavrasSemana;
  final int metaSemana;
  final int palavrasDominadas;

  factory AlunoPainelDto.fromJson(Map<String, dynamic> j) => AlunoPainelDto(
        id: j['id'] as int,
        nome: j['nome'] as String,
        palavrasSemana: j['palavras_semana'] as int,
        metaSemana: j['meta_semana'] as int,
        palavrasDominadas: j['palavras_dominadas'] as int,
      );
}

class PainelDto {
  PainelDto({
    required this.turmaId,
    required this.turmaNome,
    required this.anoEscolar,
    required this.alunosAtivos,
    required this.alunosTotal,
    required this.palavrasDominadasSemana,
    required this.metaSemanal,
    required this.sinalTurma,
    required this.alunos,
  });

  final int turmaId;
  final String turmaNome;
  final int anoEscolar;
  final int alunosAtivos;
  final int alunosTotal;
  final int palavrasDominadasSemana;
  final int metaSemanal;
  final List<String> sinalTurma;
  final List<AlunoPainelDto> alunos;

  factory PainelDto.fromJson(Map<String, dynamic> j) => PainelDto(
        turmaId: j['turma_id'] as int,
        turmaNome: j['turma_nome'] as String,
        anoEscolar: j['ano_escolar'] as int,
        alunosAtivos: j['alunos_ativos'] as int,
        alunosTotal: j['alunos_total'] as int,
        palavrasDominadasSemana: j['palavras_dominadas_semana'] as int,
        metaSemanal: j['meta_semanal'] as int,
        sinalTurma: (j['sinal_turma'] as List).cast<String>(),
        alunos: (j['alunos'] as List)
            .map((e) => AlunoPainelDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TurmaLinhaDto {
  TurmaLinhaDto({
    required this.id,
    required this.nome,
    required this.anoEscolar,
    required this.alunosAtivos,
    required this.alunosTotal,
    required this.palavrasDominadasSemana,
    required this.metaSemanal,
  });

  final int id;
  final String nome;
  final int anoEscolar;
  final int alunosAtivos;
  final int alunosTotal;
  final int palavrasDominadasSemana;
  final int metaSemanal;

  factory TurmaLinhaDto.fromJson(Map<String, dynamic> j) => TurmaLinhaDto(
        id: j['id'] as int,
        nome: j['nome'] as String,
        anoEscolar: j['ano_escolar'] as int,
        alunosAtivos: j['alunos_ativos'] as int,
        alunosTotal: j['alunos_total'] as int,
        palavrasDominadasSemana: j['palavras_dominadas_semana'] as int,
        metaSemanal: j['meta_semanal'] as int,
      );
}

class EscolaPainelDto {
  EscolaPainelDto({
    required this.escolaNome,
    required this.turmasTotal,
    required this.alunosAtivos,
    required this.alunosTotal,
    required this.palavrasDominadasSemana,
    required this.sinalEscola,
    required this.turmas,
  });

  final String escolaNome;
  final int turmasTotal;
  final int alunosAtivos;
  final int alunosTotal;
  final int palavrasDominadasSemana;
  final List<String> sinalEscola;
  final List<TurmaLinhaDto> turmas;

  factory EscolaPainelDto.fromJson(Map<String, dynamic> j) => EscolaPainelDto(
        escolaNome: j['escola_nome'] as String,
        turmasTotal: j['turmas_total'] as int,
        alunosAtivos: j['alunos_ativos'] as int,
        alunosTotal: j['alunos_total'] as int,
        palavrasDominadasSemana: j['palavras_dominadas_semana'] as int,
        sinalEscola: (j['sinal_escola'] as List).cast<String>(),
        turmas: (j['turmas'] as List)
            .map((e) => TurmaLinhaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
