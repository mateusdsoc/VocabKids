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
      turmaId: 1,
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
      turmaId: 2,
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

/// Estado de domínio de uma palavra para o aluno (`aluno_palavra.estado`,
/// §3.4 — máquina de estados sem regressão). [rank] ordena da mais avançada
/// para a mais nova na lista do detalhe.
enum EstadoPalavra {
  dominada(5, 'Dominada'),
  nivel4(4, 'Nível 4'),
  nivel3(3, 'Nível 3'),
  nivel2(2, 'Nível 2'),
  nivel1(1, 'Nível 1'),
  descoberta(0, 'Descoberta');

  const EstadoPalavra(this.rank, this.rotulo);
  final int rank;
  final String rotulo;

  bool get isDominada => this == EstadoPalavra.dominada;

  /// Tolerante: string desconhecida cai em [descoberta] (cliente resiliente).
  static EstadoPalavra parse(String s) => switch (s) {
        'dominada' => dominada,
        'nivel_4' => nivel4,
        'nivel_3' => nivel3,
        'nivel_2' => nivel2,
        'nivel_1' => nivel1,
        _ => descoberta,
      };
}

/// Origem da palavra na trilha do aluno (`aluno_palavra.origem`, §3.2/§3.5).
/// [pessoalRedacao] é o loop redação→vocabulário; [sinalTurma] casa com o
/// "sinal" do painel.
enum OrigemPalavra {
  pessoalRedacao('da redação'),
  sinalTurma('sinal da turma'),
  bancoBase('banco');

  const OrigemPalavra(this.rotulo);
  final String rotulo;

  static OrigemPalavra parse(String s) => switch (s) {
        'pessoal_redacao' => pessoalRedacao,
        'sinal_turma' => sinalTurma,
        _ => bancoBase,
      };
}

/// Situação de uma redação do aluno (subconjunto de `redacao.status`).
enum StatusRedacao {
  analisada('Analisada'),
  emAnalise('Em análise'),
  pendente('Pendente'),
  rascunho('Rascunho');

  const StatusRedacao(this.rotulo);
  final String rotulo;

  static StatusRedacao parse(String s) => switch (s) {
        'analisada' => analisada,
        'em_analise' => emAnalise,
        'rascunho' => rascunho,
        _ => pendente,
      };
}

/// Palavra no vocabulário do aluno (item da lista do detalhe).
class PalavraAluno {
  const PalavraAluno({
    required this.texto,
    required this.estado,
    required this.origem,
  });

  final String texto;
  final EstadoPalavra estado;
  final OrigemPalavra origem;
}

/// Redação do aluno (linha da lista do detalhe).
class RedacaoAluno {
  const RedacaoAluno({
    required this.id,
    required this.tema,
    required this.status,
    required this.enviadaEm,
  });

  final int id;
  final String tema;
  final StatusRedacao status;

  /// Data ISO (`yyyy-mm-dd`) ou `null` quando ainda não enviada.
  final String? enviadaEm;

  /// `dd/mm` para exibição; `null` se não enviada ou data malformada.
  String? get dataCurta {
    final iso = enviadaEm;
    if (iso == null) return null;
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : null;
  }
}

/// Dados do **Detalhe do aluno** (drill-down do painel — telas §8.2). Só
/// leitura. Counters + uma lista limitada de palavras notáveis e as redações
/// do aluno; o `ProfessorMapper` traduz `GET /v1/professor/alunos/{id}` → isto.
class AlunoDetalhe {
  const AlunoDetalhe({
    required this.id,
    required this.nome,
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
  final String turmaNome;
  final int anoEscolar;
  final int palavrasSemana;
  final int metaSemana;
  final int palavrasDominadas;
  final int palavrasEmProgresso;
  final List<PalavraAluno> palavras;
  final List<RedacaoAluno> redacoes;

  double get metaFraction =>
      metaSemana == 0 ? 0 : clampDouble(palavrasSemana / metaSemana, 0, 1);
  bool get metaCumprida => palavrasSemana >= metaSemana;

  /// Palavras que faltam para bater a meta da semana (0 se já cumprida).
  int get faltamMeta =>
      metaCumprida ? 0 : metaSemana - palavrasSemana;

  /// Amostra por aluno (espelha o mock do backend). Reusa os campos-base dos
  /// painéis (`PainelData._amostras`) — fonte única, sem duplicar nome/números.
  /// Cai no primeiro aluno se o id não existir.
  factory AlunoDetalhe.sample(int alunoId) {
    for (final painel in PainelData._amostras.values) {
      for (final a in painel.alunos) {
        if (a.id == alunoId) return _montar(painel, a);
      }
    }
    final primeiro = PainelData._amostras[1]!;
    return _montar(primeiro, primeiro.alunos.first);
  }

  static AlunoDetalhe _montar(PainelData painel, AlunoLinha a) {
    final extra = _detalhes[a.id];
    final palavras = extra?.palavras ?? const [];
    return AlunoDetalhe(
      id: a.id,
      nome: a.nome,
      turmaNome: painel.turmaNome,
      anoEscolar: painel.anoEscolar,
      palavrasSemana: a.palavrasSemana,
      metaSemana: a.metaSemana,
      palavrasDominadas: a.palavrasDominadas,
      palavrasEmProgresso: extra?.emProgresso ??
          palavras.where((p) => !p.estado.isDominada).length,
      palavras: palavras,
      redacoes: extra?.redacoes ?? const [],
    );
  }

  /// Só o **extra** por aluno (espelha `_ALUNOS_DETALHE` do backend); base vem
  /// dos painéis acima.
  static final Map<int, _DetalheExtra> _detalhes = {
    1: _DetalheExtra(emProgresso: 7, palavras: [
      PalavraAluno(texto: 'perspicaz', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'resiliente', estado: EstadoPalavra.dominada, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'meticuloso', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'efêmero', estado: EstadoPalavra.nivel3, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'âmbar', estado: EstadoPalavra.nivel2, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'conciso', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.bancoBase),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Um herói brasileiro', status: StatusRedacao.analisada, enviadaEm: '2026-06-09'),
      RedacaoAluno(id: 2, tema: 'Minhas férias dos sonhos', status: StatusRedacao.emAnalise, enviadaEm: '2026-06-14'),
    ]),
    2: _DetalheExtra(emProgresso: 5, palavras: [
      PalavraAluno(texto: 'meticuloso', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'próspero', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'perspicaz', estado: EstadoPalavra.nivel3, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'vasto', estado: EstadoPalavra.nivel2, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'sutil', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.bancoBase),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Um herói brasileiro', status: StatusRedacao.analisada, enviadaEm: '2026-06-08'),
    ]),
    3: _DetalheExtra(emProgresso: 6, palavras: [
      PalavraAluno(texto: 'nítido', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'eloquente', estado: EstadoPalavra.dominada, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'efêmero', estado: EstadoPalavra.nivel2, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'perspicaz', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.sinalTurma),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Um herói brasileiro', status: StatusRedacao.emAnalise, enviadaEm: '2026-06-13'),
    ]),
    4: _DetalheExtra(emProgresso: 4, palavras: [
      PalavraAluno(texto: 'próspero', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'efêmero', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'perspicaz', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'conciso', estado: EstadoPalavra.descoberta, origem: OrigemPalavra.bancoBase),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Um herói brasileiro', status: StatusRedacao.pendente, enviadaEm: null),
    ]),
    5: _DetalheExtra(emProgresso: 8, palavras: [
      PalavraAluno(texto: 'audacioso', estado: EstadoPalavra.dominada, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'perspicaz', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'meticuloso', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'lúcido', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'efêmero', estado: EstadoPalavra.nivel4, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'sagaz', estado: EstadoPalavra.nivel2, origem: OrigemPalavra.pessoalRedacao),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Um herói brasileiro', status: StatusRedacao.analisada, enviadaEm: '2026-06-07'),
      RedacaoAluno(id: 2, tema: 'Minhas férias dos sonhos', status: StatusRedacao.analisada, enviadaEm: '2026-06-13'),
    ]),
    6: _DetalheExtra(emProgresso: 3, palavras: [
      PalavraAluno(texto: 'vasto', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'perspicaz', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'meticuloso', estado: EstadoPalavra.descoberta, origem: OrigemPalavra.sinalTurma),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Um herói brasileiro', status: StatusRedacao.pendente, enviadaEm: null),
    ]),
    7: _DetalheExtra(emProgresso: 9, palavras: [
      PalavraAluno(texto: 'pertinente', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'eloquente', estado: EstadoPalavra.dominada, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'conciso', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'ínterim', estado: EstadoPalavra.nivel3, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'sagaz', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.bancoBase),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Tecnologia na escola', status: StatusRedacao.analisada, enviadaEm: '2026-06-11'),
    ]),
    8: _DetalheExtra(emProgresso: 6, palavras: [
      PalavraAluno(texto: 'conciso', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'próspero', estado: EstadoPalavra.nivel2, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'pertinente', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.sinalTurma),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Tecnologia na escola', status: StatusRedacao.emAnalise, enviadaEm: '2026-06-12'),
    ]),
    9: _DetalheExtra(emProgresso: 5, palavras: [
      PalavraAluno(texto: 'vasto', estado: EstadoPalavra.dominada, origem: OrigemPalavra.bancoBase),
      PalavraAluno(texto: 'ínterim', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'pertinente', estado: EstadoPalavra.descoberta, origem: OrigemPalavra.sinalTurma),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Tecnologia na escola', status: StatusRedacao.pendente, enviadaEm: null),
    ]),
    10: _DetalheExtra(emProgresso: 7, palavras: [
      PalavraAluno(texto: 'pertinente', estado: EstadoPalavra.dominada, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'nítido', estado: EstadoPalavra.dominada, origem: OrigemPalavra.pessoalRedacao),
      PalavraAluno(texto: 'conciso', estado: EstadoPalavra.nivel3, origem: OrigemPalavra.sinalTurma),
      PalavraAluno(texto: 'sutil', estado: EstadoPalavra.nivel1, origem: OrigemPalavra.bancoBase),
    ], redacoes: [
      RedacaoAluno(id: 1, tema: 'Tecnologia na escola', status: StatusRedacao.analisada, enviadaEm: '2026-06-10'),
    ]),
  };
}

/// Bloco "extra" por aluno (campos que não vêm do painel). Privado — só serve
/// para montar [AlunoDetalhe.sample].
class _DetalheExtra {
  const _DetalheExtra({
    required this.emProgresso,
    required this.palavras,
    required this.redacoes,
  });

  final int emProgresso;
  final List<PalavraAluno> palavras;
  final List<RedacaoAluno> redacoes;
}

/// Redação atribuída a uma turma (§4.6) — retorno de
/// `POST /v1/professor/turmas/{id}/redacoes`. O professor atribui tema + prazo;
/// o aluno envia depois.
class RedacaoAtribuicao {
  const RedacaoAtribuicao({
    required this.id,
    required this.turmaId,
    required this.tema,
    required this.prazo,
  });

  final int id;
  final int turmaId;
  final String tema;

  /// Data ISO (`yyyy-mm-dd`) ou `null` (sem prazo).
  final String? prazo;

  /// `dd/mm` para exibição; `null` se sem prazo ou data malformada.
  String? get prazoCurto {
    final iso = prazo;
    if (iso == null) return null;
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : null;
  }
}
