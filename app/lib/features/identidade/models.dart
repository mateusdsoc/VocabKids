/// Modelos da identidade, espelhando os contratos Pydantic do backend
/// (`identidade/schemas.py`). Apenas desserialização — sem lógica.
library;

class Turma {
  final int id;
  final String nome;
  final int anoEscolar;

  Turma({required this.id, required this.nome, required this.anoEscolar});

  factory Turma.fromJson(Map<String, dynamic> j) => Turma(
        id: j['id'] as int,
        nome: j['nome'] as String,
        anoEscolar: j['ano_escolar'] as int,
      );
}

class Escola {
  final int id;
  final String nome;

  Escola({required this.id, required this.nome});

  factory Escola.fromJson(Map<String, dynamic> j) =>
      Escola(id: j['id'] as int, nome: j['nome'] as String);
}

/// Resposta de `POST /v1/acesso/turma`.
class AcessoTurma {
  final String token;
  final int usuarioId;
  final String nome;
  final Turma turma;
  final bool novo;

  AcessoTurma({
    required this.token,
    required this.usuarioId,
    required this.nome,
    required this.turma,
    required this.novo,
  });

  factory AcessoTurma.fromJson(Map<String, dynamic> j) => AcessoTurma(
        token: j['token'] as String,
        usuarioId: j['usuario_id'] as int,
        nome: j['nome'] as String,
        turma: Turma.fromJson(j['turma'] as Map<String, dynamic>),
        novo: j['novo'] as bool,
      );
}

/// Progresso do aluno (parte de `GET /v1/me`).
class Progresso {
  final int xpTotal;
  final int? noAtualId;
  final int palavrasDominadas;
  final int nivelDificuldadeAtual;

  Progresso({
    required this.xpTotal,
    required this.noAtualId,
    required this.palavrasDominadas,
    required this.nivelDificuldadeAtual,
  });

  factory Progresso.fromJson(Map<String, dynamic> j) => Progresso(
        xpTotal: j['xp_total'] as int,
        noAtualId: j['no_atual_id'] as int?,
        palavrasDominadas: j['palavras_dominadas'] as int,
        nivelDificuldadeAtual: j['nivel_dificuldade_atual'] as int,
      );
}

/// Meta da semana (parte de `GET /v1/me`, §3.5): palavras dominadas desde
/// segunda-feira sobre o alvo da turma — mesmo corte do painel do professor.
class MetaSemanal {
  final int atual;
  final int alvo;

  MetaSemanal({required this.atual, required this.alvo});

  factory MetaSemanal.fromJson(Map<String, dynamic> j) =>
      MetaSemanal(atual: j['atual'] as int, alvo: j['alvo'] as int);
}

/// Resposta de `GET /v1/me` — perfil + progresso do aluno autenticado.
class Me {
  final int usuarioId;
  final String nome;
  final String papel;
  final Escola? escola;
  final Turma? turma;
  final Progresso progresso;
  final MetaSemanal? metaSemanal; // nula sem turma

  Me({
    required this.usuarioId,
    required this.nome,
    required this.papel,
    required this.escola,
    required this.turma,
    required this.progresso,
    required this.metaSemanal,
  });

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        usuarioId: j['usuario_id'] as int,
        nome: j['nome'] as String,
        papel: j['papel'] as String,
        escola: j['escola'] == null
            ? null
            : Escola.fromJson(j['escola'] as Map<String, dynamic>),
        turma: j['turma'] == null
            ? null
            : Turma.fromJson(j['turma'] as Map<String, dynamic>),
        progresso: Progresso.fromJson(j['progresso'] as Map<String, dynamic>),
        metaSemanal: j['meta_semanal'] == null
            ? null
            : MetaSemanal.fromJson(j['meta_semanal'] as Map<String, dynamic>),
      );
}
