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

class AlunoPalavraDto {
  AlunoPalavraDto({
    required this.texto,
    required this.estado,
    required this.origem,
  });

  final String texto;
  final String estado; // descoberta | nivel_1..4 | dominada
  final String origem; // pessoal_redacao | sinal_turma | banco_base

  factory AlunoPalavraDto.fromJson(Map<String, dynamic> j) => AlunoPalavraDto(
        texto: j['texto'] as String,
        estado: j['estado'] as String,
        origem: j['origem'] as String,
      );
}

class AlunoRedacaoDto {
  AlunoRedacaoDto({
    required this.id,
    required this.tema,
    required this.status,
    required this.enviadaEm,
  });

  final int id;
  final String tema;
  final String status; // pendente | em_analise | analisada | rascunho
  final String? enviadaEm;

  factory AlunoRedacaoDto.fromJson(Map<String, dynamic> j) => AlunoRedacaoDto(
        id: j['id'] as int,
        tema: j['tema'] as String,
        status: j['status'] as String,
        enviadaEm: j['enviada_em'] as String?,
      );
}

class AlunoDetalheDto {
  AlunoDetalheDto({
    required this.id,
    required this.nome,
    required this.turmaId,
    required this.turmaNome,
    required this.anoEscolar,
    required this.palavrasSemana,
    required this.metaSemana,
    required this.palavrasDominadas,
    required this.palavrasEmProgresso,
    required this.palavras,
    required this.redacoes,
  });

  final int id;
  final String nome;
  final int turmaId;
  final String turmaNome;
  final int anoEscolar;
  final int palavrasSemana;
  final int metaSemana;
  final int palavrasDominadas;
  final int palavrasEmProgresso;
  final List<AlunoPalavraDto> palavras;
  final List<AlunoRedacaoDto> redacoes;

  factory AlunoDetalheDto.fromJson(Map<String, dynamic> j) => AlunoDetalheDto(
        id: j['id'] as int,
        nome: j['nome'] as String,
        turmaId: j['turma_id'] as int,
        turmaNome: j['turma_nome'] as String,
        anoEscolar: j['ano_escolar'] as int,
        palavrasSemana: j['palavras_semana'] as int,
        metaSemana: j['meta_semana'] as int,
        palavrasDominadas: j['palavras_dominadas'] as int,
        palavrasEmProgresso: j['palavras_em_progresso'] as int,
        palavras: (j['palavras'] as List)
            .map((e) => AlunoPalavraDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        redacoes: (j['redacoes'] as List)
            .map((e) => AlunoRedacaoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Resposta de POST /professor/turmas/{id}/redacoes (espelha `redacao_atribuicao`).
class RedacaoAtribuicaoDto {
  RedacaoAtribuicaoDto({
    required this.id,
    required this.turmaId,
    required this.tema,
    required this.prazo,
  });

  final int id;
  final int turmaId;
  final String tema;
  final String? prazo;

  factory RedacaoAtribuicaoDto.fromJson(Map<String, dynamic> j) =>
      RedacaoAtribuicaoDto(
        id: j['id'] as int,
        turmaId: j['turma_id'] as int,
        tema: j['tema'] as String,
        prazo: j['prazo'] as String?,
      );
}
