/// DTOs da Redação, espelhando `redacao/schemas.py` (`RedacoesAlunoOut` /
/// `RedacaoAlunoOut` / `EnvioOut`). Apenas desserialização — a tradução para o
/// modelo apresentável vive no `RedacaoMapper`.
library;

/// O envio deste aluno para uma atribuição (`EnvioOut`).
class EnvioDto {
  const EnvioDto({
    required this.redacaoId,
    required this.status,
    required this.enviadaEm,
    required this.paginas,
  });

  final int redacaoId;

  /// enviada | processando | analisada | erro_ingestao | erro_analise.
  final String status;
  final DateTime enviadaEm;
  final int paginas;

  factory EnvioDto.fromJson(Map<String, dynamic> j) => EnvioDto(
        redacaoId: j['redacao_id'] as int,
        status: j['status'] as String,
        enviadaEm: DateTime.parse(j['enviada_em'] as String),
        paginas: j['paginas'] as int,
      );
}

/// Uma atribuição da turma sob a ótica do aluno (`RedacaoAlunoOut`).
class RedacaoItemDto {
  const RedacaoItemDto({
    required this.atribuicaoId,
    required this.tema,
    required this.prazo,
    required this.redacao,
  });

  final int atribuicaoId;
  final String tema;
  final DateTime? prazo;

  /// `null` = o aluno ainda não enviou (a tela mostra como "aberta").
  final EnvioDto? redacao;

  factory RedacaoItemDto.fromJson(Map<String, dynamic> j) => RedacaoItemDto(
        atribuicaoId: j['atribuicao_id'] as int,
        tema: j['tema'] as String,
        prazo:
            j['prazo'] == null ? null : DateTime.parse(j['prazo'] as String),
        redacao: j['redacao'] == null
            ? null
            : EnvioDto.fromJson(j['redacao'] as Map<String, dynamic>),
      );
}

/// Resposta de `GET /v1/redacoes`.
class RedacoesDto {
  const RedacoesDto({required this.itens});

  final List<RedacaoItemDto> itens;

  factory RedacoesDto.fromJson(Map<String, dynamic> j) => RedacoesDto(
        itens: (j['itens'] as List)
            .map((e) => RedacaoItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
