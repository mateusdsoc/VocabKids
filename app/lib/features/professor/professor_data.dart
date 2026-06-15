import 'dart:ui' show clampDouble;

/// Referência leve a uma turma (para o seletor de turma no escopo professor).
class TurmaRef {
  const TurmaRef({required this.id, required this.nome, required this.anoEscolar});
  final int id;
  final String nome;
  final int anoEscolar;

  static const List<TurmaRef> sampleList = [
    TurmaRef(id: 1, nome: '7º Ano A', anoEscolar: 7),
    TurmaRef(id: 2, nome: '8º Ano C', anoEscolar: 8),
  ];
}

/// Linha de aluno no painel da turma (visão resumida; o detalhe é outra tela).
class AlunoLinha {
  const AlunoLinha({
    required this.id,
    required this.nome,
    required this.palavrasSemana,
    required this.metaSemana,
    required this.palavrasDominadas,
  });

  final int id;
  final String nome;

  /// Palavras dominadas nesta semana (unidade da meta — produto §3.5).
  final int palavrasSemana;

  /// Meta semanal vigente da turma (palavras/aluno).
  final int metaSemana;

  /// Acumulado de palavras dominadas (todo o histórico).
  final int palavrasDominadas;

  double get metaFraction =>
      metaSemana == 0 ? 0 : clampDouble(palavrasSemana / metaSemana, 0, 1);
  bool get metaCumprida => palavrasSemana >= metaSemana;
}

/// Dados do **Painel da turma** (produto §07 / telas §8.2). Modelo de
/// apresentação único — desacopla os widgets do contrato do backend; o
/// `ProfessorMapper` traduz `GET /v1/professor/turmas/{id}/painel` → isto.
class PainelData {
  const PainelData({
    required this.turmaNome,
    required this.anoEscolar,
    required this.alunosAtivos,
    required this.alunosTotal,
    required this.palavrasDominadasSemana,
    required this.metaSemanal,
    required this.sinalTurma,
    required this.alunos,
  });

  final String turmaNome;
  final int anoEscolar;
  final int alunosAtivos;
  final int alunosTotal;
  final int palavrasDominadasSemana;

  /// Meta semanal (palavras dominadas/semana por aluno — produto §3.5).
  final int metaSemanal;

  /// Palavras que a turma mais repete/evita; entram na trilha de todos (§3.5).
  final List<String> sinalTurma;

  final List<AlunoLinha> alunos;

  /// Dados de exemplo por turma (espelham o mock do backend) — para
  /// `AppConfig.demo`, previews e testes. Cai na turma 1 se o id não existir.
  factory PainelData.sample([int turmaId = 1]) =>
      _amostras[turmaId] ?? _amostras[1]!;

  static const Map<int, PainelData> _amostras = {
    1: PainelData(
      turmaNome: '7º Ano A',
      anoEscolar: 7,
      alunosAtivos: 23,
      alunosTotal: 26,
      palavrasDominadasSemana: 184,
      metaSemanal: 5,
      sinalTurma: ['efêmero', 'perspicaz', 'meticuloso'],
      alunos: [
        AlunoLinha(id: 1, nome: 'Ana Beatriz', palavrasSemana: 6, metaSemana: 5, palavrasDominadas: 142),
        AlunoLinha(id: 2, nome: 'Bruno Carvalho', palavrasSemana: 5, metaSemana: 5, palavrasDominadas: 98),
        AlunoLinha(id: 3, nome: 'Carla Dias', palavrasSemana: 3, metaSemana: 5, palavrasDominadas: 110),
        AlunoLinha(id: 4, nome: 'Diego Fernandes', palavrasSemana: 1, metaSemana: 5, palavrasDominadas: 64),
        AlunoLinha(id: 5, nome: 'Elisa Gomes', palavrasSemana: 5, metaSemana: 5, palavrasDominadas: 173),
        AlunoLinha(id: 6, nome: 'Felipe Henrique', palavrasSemana: 0, metaSemana: 5, palavrasDominadas: 41),
      ],
    ),
    2: PainelData(
      turmaNome: '8º Ano C',
      anoEscolar: 8,
      alunosAtivos: 19,
      alunosTotal: 22,
      palavrasDominadasSemana: 151,
      metaSemanal: 6,
      sinalTurma: ['ínterim', 'conciso', 'pertinente'],
      alunos: [
        AlunoLinha(id: 7, nome: 'Gabriela Lima', palavrasSemana: 7, metaSemana: 6, palavrasDominadas: 188),
        AlunoLinha(id: 8, nome: 'Heitor Moraes', palavrasSemana: 4, metaSemana: 6, palavrasDominadas: 132),
        AlunoLinha(id: 9, nome: 'Isabela Nunes', palavrasSemana: 2, metaSemana: 6, palavrasDominadas: 95),
        AlunoLinha(id: 10, nome: 'João Pedro', palavrasSemana: 6, metaSemana: 6, palavrasDominadas: 147),
      ],
    ),
  };
}

/// Linha de turma no painel da **escola** (escopo coordenador).
class TurmaLinha {
  const TurmaLinha({
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

  double get ativosFraction =>
      alunosTotal == 0 ? 0 : clampDouble(alunosAtivos / alunosTotal, 0, 1);
}

/// Dados do **Painel da escola** (escopo coordenador, §3.11 — só leitura).
/// As linhas são turmas, não alunos.
class EscolaPainelData {
  const EscolaPainelData({
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
  final List<TurmaLinha> turmas;

  factory EscolaPainelData.sample() => const EscolaPainelData(
        escolaNome: 'Colégio Horizonte',
        turmasTotal: 2,
        alunosAtivos: 42,
        alunosTotal: 48,
        palavrasDominadasSemana: 335,
        sinalEscola: ['efêmero', 'pertinente', 'conciso'],
        turmas: [
          TurmaLinha(id: 1, nome: '7º Ano A', anoEscolar: 7, alunosAtivos: 23, alunosTotal: 26, palavrasDominadasSemana: 184, metaSemanal: 5),
          TurmaLinha(id: 2, nome: '8º Ano C', anoEscolar: 8, alunosAtivos: 19, alunosTotal: 22, palavrasDominadasSemana: 151, metaSemanal: 6),
        ],
      );
}
