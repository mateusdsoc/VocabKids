/// DTOs do Passaporte, espelhando `trilha/schemas.py` (`PassaporteOut` /
/// `ItemPassaporteOut`). Apenas desserialização — a tradução para a coleção
/// apresentável vive no `PassaporteMapper`.
library;

class ItemPassaporteDto {
  const ItemPassaporteDto({
    required this.id,
    required this.tipo,
    required this.referencia,
    required this.assetRef,
    required this.conquistado,
    required this.ganhoEm,
    required this.revelado,
  });

  final int id; // id do colecionável — usado no POST /revelado
  final String tipo; // cartao_postal | carimbo | selo
  final String referencia; // destino:{id} | pais:{id} | feito:{chave}
  final String? assetRef;
  final bool conquistado;
  final DateTime? ganhoEm;

  /// Modo Conquista: conquistado e não revelado = pendente de reveal.
  final bool revelado;

  bool get pendenteDeReveal => conquistado && !revelado;

  factory ItemPassaporteDto.fromJson(Map<String, dynamic> j) =>
      ItemPassaporteDto(
        id: j['id'] as int,
        tipo: j['tipo'] as String,
        referencia: j['referencia'] as String,
        assetRef: j['asset_ref'] as String?,
        conquistado: j['conquistado'] as bool,
        ganhoEm: j['ganho_em'] == null
            ? null
            : DateTime.parse(j['ganho_em'] as String),
        revelado: j['revelado'] as bool,
      );
}

/// Resposta de `GET /v1/passaporte` — os 28 colecionáveis, ganhos ou não.
class PassaporteDto {
  const PassaporteDto({
    required this.total,
    required this.conquistados,
    required this.itens,
  });

  final int total;
  final int conquistados;
  final List<ItemPassaporteDto> itens;

  factory PassaporteDto.fromJson(Map<String, dynamic> j) => PassaporteDto(
        total: j['total'] as int,
        conquistados: j['conquistados'] as int,
        itens: (j['itens'] as List)
            .map((e) => ItemPassaporteDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
