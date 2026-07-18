import 'data/redacao_models.dart';
import 'models.dart';

/// Traduz os DTOs de `GET /v1/redacoes` para o modelo apresentável [Redacao].
/// Puro (sem I/O) — testável sem backend.
class RedacaoMapper {
  const RedacaoMapper._();

  static List<Redacao> listaDe(RedacoesDto dto) =>
      dto.itens.map(itemDe).toList();

  static Redacao itemDe(RedacaoItemDto d) {
    final envio = d.redacao;
    return Redacao(
      atribuicaoId: d.atribuicaoId,
      redacaoId: envio?.redacaoId,
      tema: d.tema,
      prazo: d.prazo,
      status: envio == null ? RedacaoStatus.aberta : _statusDe(envio.status),
      enviadaEm: envio?.enviadaEm,
      paginas: envio?.paginas ?? 0,
    );
  }

  /// Estado pós-envio: o que a área aplica localmente ao voltar do envio
  /// (espelho otimista do 201 — o provider recarrega do servidor em seguida).
  static Redacao aposEnvio(Redacao aberta, EnvioDto envio) => aberta.copyWith(
        status: _statusDe(envio.status),
        redacaoId: envio.redacaoId,
        enviadaEm: envio.enviadaEm,
        paginas: envio.paginas,
      );

  /// `erro_*` aparece como "em análise" por enquanto: o pipeline (fatia 2)
  /// ainda não roda, então o estado não ocorre; quando rodar, erro de ingestão
  /// ganha tratamento próprio ("não consegui ler sua foto — reenvie").
  static RedacaoStatus _statusDe(String status) => switch (status) {
        'analisada' => RedacaoStatus.analisada,
        _ => RedacaoStatus.emAnalise,
      };
}
