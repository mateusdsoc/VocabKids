/// Modelos do diagnóstico, espelhando `diagnostico/schemas.py`
/// (`DiagnosticoOut`). Apenas desserialização — sem lógica.
///
/// O `estado` da escada é **opaco** para o app (cliente fino): o servidor o
/// devolve a cada passo e o app o reenvia verbatim — quem entende a escada
/// grosso→fino é o backend.
library;

class DiagnosticoQuestao {
  final int questaoId;
  final String enunciado;
  final List<String> opcoes; // embaralhadas; a correta nunca vem

  DiagnosticoQuestao({
    required this.questaoId,
    required this.enunciado,
    required this.opcoes,
  });

  factory DiagnosticoQuestao.fromJson(Map<String, dynamic> j) =>
      DiagnosticoQuestao(
        questaoId: j['questao_id'] as int,
        enunciado: j['enunciado'] as String,
        opcoes: (j['opcoes'] as List).cast<String>(),
      );
}

/// Resposta de `POST /v1/onboarding/diagnostico` (um passo da escada).
class DiagnosticoPasso {
  final bool concluido;
  final int perguntas; // já respondidas
  final int maxPerguntas; // teto da escada (pode terminar antes)
  final DiagnosticoQuestao? questao;
  final Map<String, dynamic>? estado; // opaco — reenviar no próximo passo
  final int? nivelDificuldadeAtual; // preenchido quando concluído

  DiagnosticoPasso({
    required this.concluido,
    required this.perguntas,
    required this.maxPerguntas,
    required this.questao,
    required this.estado,
    required this.nivelDificuldadeAtual,
  });

  factory DiagnosticoPasso.fromJson(Map<String, dynamic> j) => DiagnosticoPasso(
        concluido: j['concluido'] as bool,
        perguntas: j['perguntas'] as int,
        maxPerguntas: j['max_perguntas'] as int,
        questao: j['questao'] == null
            ? null
            : DiagnosticoQuestao.fromJson(j['questao'] as Map<String, dynamic>),
        estado: j['estado'] as Map<String, dynamic>?,
        nivelDificuldadeAtual: j['nivel_dificuldade_atual'] as int?,
      );
}
