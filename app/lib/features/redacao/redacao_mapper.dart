import 'data/redacao_models.dart';
import 'models.dart';

/// Traduz os contratos da redação (`/v1/redacoes`, `.../enviar`,
/// `.../analise`) nos modelos de apresentação. Único ponto que conhece os
/// dois lados — trocar um campo do backend mexe aqui, não nas telas.
abstract final class RedacaoMapper {
  static Redacao redacaoDe(RedacaoAtribuicaoDto dto) => Redacao(
        atribuicaoId: dto.id,
        tema: dto.tema,
        status: redacaoStatusDe(dto.status),
        prazo: dto.prazo,
        redacaoId: dto.redacaoId,
      );
}
