/// Modelos de apresentação da área de Redação (produto §4.6). Espelha o ciclo
/// real do backend (`backend/app/redacao/schemas.py`, `docs/plano_b2c.md`
/// §07): o responsável/servidor **atribui** um tema a cada 15 dias (ou sob
/// demanda, R-RD-4); o aluno **envia** em resposta (hoje só texto digitado —
/// manuscrita depende de OCR on-device ainda não integrado ao app).
library;

/// Onde a redação está no ciclo do aluno — espelha o `status` de
/// `RedacaoAtribuicaoOut`/`AnaliseOut` (`null` no backend = [aberta]).
enum RedacaoStatus {
  /// Atribuída, ainda não enviada — é o "herói" da tela.
  aberta,

  /// Enviada; a análise (chamada ao Claude) está rodando no servidor. Como o
  /// envio é síncrono, isto só aparece se o app for fechado no meio ou numa
  /// nova consulta antes do processamento terminar.
  processando,

  /// Texto mais curto que o mínimo da rubrica da faixa etária — o servidor
  /// não chegou a analisar.
  erroIngestao,

  /// A chamada de análise falhou no servidor; sem detalhe de motivo exposto.
  erroAnalise,

  /// R-RD-7: a triagem de risco encontrou um sinal (violência doméstica,
  /// autolesão, abuso). Nenhuma análise é gravada ou mostrada — a tela deve
  /// ser acolhedora, nunca tratar como erro técnico.
  revisaoHumana,

  /// Análise concluída — resultado disponível.
  analisada,
}

RedacaoStatus redacaoStatusDe(String? status) => switch (status) {
      null => RedacaoStatus.aberta,
      'processando' => RedacaoStatus.processando,
      'erro_ingestao' => RedacaoStatus.erroIngestao,
      'erro_analise' => RedacaoStatus.erroAnalise,
      'revisao_humana' => RedacaoStatus.revisaoHumana,
      'analisada' => RedacaoStatus.analisada,
      _ => RedacaoStatus.processando,
    };

class Redacao {
  const Redacao({
    required this.atribuicaoId,
    required this.tema,
    required this.status,
    this.prazo,
    this.redacaoId,
  });

  /// Id da **atribuição** (`GET /redacoes`) — é o que `POST .../enviar` espera.
  final int atribuicaoId;
  final String tema;
  final RedacaoStatus status;

  /// Prazo de entrega; `null` = sem prazo (hoje sempre o caso — a rubrica não
  /// define prazo, ver `design/notas-implementacao.md` § "Fase 4").
  final DateTime? prazo;

  /// Id da **redação** enviada; `null` enquanto [aberta]. É o que
  /// `GET .../analise` espera.
  final int? redacaoId;

  bool get aberta => status == RedacaoStatus.aberta;

  /// Amostra para `AppConfig.demo`: 1 aberta (caso comum) + histórico com os
  /// principais desfechos possíveis.
  static List<Redacao> sample() => const [
        Redacao(
          atribuicaoId: 1,
          tema: 'Minhas férias dos sonhos',
          status: RedacaoStatus.aberta,
        ),
        Redacao(
          atribuicaoId: 2,
          tema: 'Um herói brasileiro',
          status: RedacaoStatus.analisada,
          redacaoId: 102,
        ),
        Redacao(
          atribuicaoId: 3,
          tema: 'Se eu pudesse mudar o mundo',
          status: RedacaoStatus.erroIngestao,
          redacaoId: 103,
        ),
      ];
}
