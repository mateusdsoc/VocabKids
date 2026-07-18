/// Modelos da área de Redação (produto §4.6).
///
/// O professor **atribui** uma redação (tema + prazo); o aluno **envia** em
/// resposta (foto manuscrita → OCR, ou PDF). Aqui só o que a UI precisa — o
/// pipeline real (OCR → análise → atribuição de palavras) é da fatia C; por
/// isso o resultado fica num placeholder honesto, sem métricas inventadas.
///
/// Alimentado pelo backend real (`GET /v1/redacoes` — fatia 1): o item é a
/// **atribuição** sob a ótica do aluno; o envio dele (se houver) dá o status.
/// A tradução DTO→modelo vive no `RedacaoMapper`.
library;

/// Onde a redação está no ciclo do aluno.
enum RedacaoStatus {
  /// Atribuída pelo professor, ainda não enviada — é o "herói" da tela.
  aberta,

  /// Enviada; aguardando a análise (fatia C). Sem resultado ainda.
  emAnalise,

  /// Análise concluída — resultado disponível.
  analisada,
}

class Redacao {
  const Redacao({
    required this.atribuicaoId,
    required this.tema,
    required this.status,
    this.redacaoId,
    this.prazo,
    this.enviadaEm,
    this.paginas = 0,
  });

  /// Id da atribuição do professor — identidade do item e alvo do envio.
  final int atribuicaoId;

  /// Id do envio deste aluno; `null` enquanto aberta. É a chave da análise
  /// (`GET /redacoes/{id}/analise`, fatia 4).
  final int? redacaoId;

  final String tema;
  final RedacaoStatus status;

  /// Prazo de entrega; `null` = sem prazo definido pelo professor.
  final DateTime? prazo;

  /// Quando o aluno enviou (para o histórico); `null` se ainda aberta.
  final DateTime? enviadaEm;

  /// Quantas páginas o aluno enviou (manuscrita pode ter 1–2 folhas).
  final int paginas;

  bool get aberta => status == RedacaoStatus.aberta;

  Redacao copyWith({
    RedacaoStatus? status,
    int? redacaoId,
    DateTime? enviadaEm,
    int? paginas,
  }) =>
      Redacao(
        atribuicaoId: atribuicaoId,
        redacaoId: redacaoId ?? this.redacaoId,
        tema: tema,
        prazo: prazo,
        status: status ?? this.status,
        enviadaEm: enviadaEm ?? this.enviadaEm,
        paginas: paginas ?? this.paginas,
      );

  /// Amostra para `DEMO=true`: 1 redação aberta (caso comum) + histórico.
  /// Prazos são relativos a "agora" para a urgência fazer sentido em qualquer
  /// dia. Fora do demo, os dados vêm de `GET /v1/redacoes`.
  static List<Redacao> sample() {
    final hoje = DateTime.now();
    DateTime emDias(int d) => DateTime(hoje.year, hoje.month, hoje.day + d);
    return [
      Redacao(
        atribuicaoId: 1,
        tema: 'Minhas férias dos sonhos',
        status: RedacaoStatus.aberta,
        prazo: emDias(3),
      ),
      Redacao(
        atribuicaoId: 2,
        redacaoId: 102,
        tema: 'Um herói brasileiro',
        status: RedacaoStatus.analisada,
        prazo: emDias(-9),
        enviadaEm: emDias(-11),
        paginas: 2,
      ),
      Redacao(
        atribuicaoId: 3,
        redacaoId: 103,
        tema: 'Se eu pudesse mudar o mundo',
        status: RedacaoStatus.emAnalise,
        prazo: emDias(-2),
        enviadaEm: emDias(-1),
        paginas: 1,
      ),
    ];
  }
}
