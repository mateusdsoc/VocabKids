/// Modelos da área de Redação (produto §4.6).
///
/// O professor **atribui** uma redação (tema + prazo); o aluno **envia** em
/// resposta (foto manuscrita → OCR, ou PDF). Aqui só o que a UI precisa — o
/// pipeline real (OCR → análise → atribuição de palavras) é da fatia C; por
/// isso o resultado fica num placeholder honesto, sem métricas inventadas.
///
/// Espelha `backend/app/redacao/routes.py` (`GET /redacoes`, hoje mockado):
/// `tema`, `prazo`, `status`.
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
    required this.id,
    required this.tema,
    required this.status,
    this.prazo,
    this.enviadaEm,
    this.paginas = 0,
  });

  final int id;
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
    DateTime? enviadaEm,
    int? paginas,
  }) =>
      Redacao(
        id: id,
        tema: tema,
        prazo: prazo,
        status: status ?? this.status,
        enviadaEm: enviadaEm ?? this.enviadaEm,
        paginas: paginas ?? this.paginas,
      );

  /// Amostra para o apresentável: 1 redação aberta (caso comum) + histórico.
  /// Prazos são relativos a "agora" para a urgência fazer sentido em qualquer
  /// dia. Trocar por `GET /redacoes` quando ligar no backend.
  static List<Redacao> sample() {
    final hoje = DateTime.now();
    DateTime emDias(int d) => DateTime(hoje.year, hoje.month, hoje.day + d);
    return [
      Redacao(
        id: 1,
        tema: 'Minhas férias dos sonhos',
        status: RedacaoStatus.aberta,
        prazo: emDias(3),
      ),
      Redacao(
        id: 2,
        tema: 'Um herói brasileiro',
        status: RedacaoStatus.analisada,
        prazo: emDias(-9),
        enviadaEm: emDias(-11),
        paginas: 2,
      ),
      Redacao(
        id: 3,
        tema: 'Se eu pudesse mudar o mundo',
        status: RedacaoStatus.emAnalise,
        prazo: emDias(-2),
        enviadaEm: emDias(-1),
        paginas: 1,
      ),
    ];
  }
}
