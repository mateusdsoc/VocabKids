/// Modelos da identidade, espelhando os contratos Pydantic do backend
/// (`identidade/schemas.py`). Apenas desserialização — sem lógica.
///
/// B2C (docs/plano_b2c.md Fase 1): conta do responsável + perfis de criança
/// no lugar de turma/escola.
library;

/// Perfil de uma criança dentro da conta do responsável.
class PerfilCrianca {
  final int usuarioId;
  final String apelido;
  final String faixaEtaria;
  final int? anoEscolar;

  PerfilCrianca({
    required this.usuarioId,
    required this.apelido,
    required this.faixaEtaria,
    required this.anoEscolar,
  });

  factory PerfilCrianca.fromJson(Map<String, dynamic> j) => PerfilCrianca(
        usuarioId: j['usuario_id'] as int,
        apelido: j['apelido'] as String,
        faixaEtaria: j['faixa_etaria'] as String,
        anoEscolar: j['ano_escolar'] as int?,
      );
}

/// Resposta de `GET /v1/conta`.
class Conta {
  final int contaId;
  final String nomeResponsavel;
  final String email;
  final List<PerfilCrianca> perfis;

  Conta({
    required this.contaId,
    required this.nomeResponsavel,
    required this.email,
    required this.perfis,
  });

  factory Conta.fromJson(Map<String, dynamic> j) => Conta(
        contaId: j['conta_id'] as int,
        nomeResponsavel: j['nome_responsavel'] as String,
        email: j['email'] as String,
        perfis: (j['perfis'] as List)
            .map((p) => PerfilCrianca.fromJson(p as Map<String, dynamic>))
            .toList(),
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
/// segunda-feira sobre o alvo da faixa etária.
class MetaSemanal {
  final int atual;
  final int alvo;

  MetaSemanal({required this.atual, required this.alvo});

  factory MetaSemanal.fromJson(Map<String, dynamic> j) =>
      MetaSemanal(atual: j['atual'] as int, alvo: j['alvo'] as int);
}

/// Resposta de `GET /v1/me` — perfil da criança autenticada + progresso.
class Me {
  final int usuarioId;
  final String nome;
  final String papel;
  final PerfilCrianca? perfil;
  final Progresso progresso;
  final MetaSemanal? metaSemanal;

  Me({
    required this.usuarioId,
    required this.nome,
    required this.papel,
    required this.perfil,
    required this.progresso,
    required this.metaSemanal,
  });

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        usuarioId: j['usuario_id'] as int,
        nome: j['nome'] as String,
        papel: j['papel'] as String,
        perfil: j['perfil'] == null
            ? null
            : PerfilCrianca.fromJson(j['perfil'] as Map<String, dynamic>),
        progresso: Progresso.fromJson(j['progresso'] as Map<String, dynamic>),
        metaSemanal: j['meta_semanal'] == null
            ? null
            : MetaSemanal.fromJson(j['meta_semanal'] as Map<String, dynamic>),
      );
}
