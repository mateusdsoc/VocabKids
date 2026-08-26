/// DTOs da Área do Responsável, espelhando `backend/app/responsavel/schemas.py`.
/// Apenas desserialização — sem lógica.
library;

class PinStatusDto {
  const PinStatusDto({required this.definido});
  final bool definido;

  factory PinStatusDto.fromJson(Map<String, dynamic> j) =>
      PinStatusDto(definido: j['definido'] as bool);
}

class MetaSemanalDto {
  const MetaSemanalDto({required this.atual, required this.alvo});
  final int atual;
  final int alvo;

  factory MetaSemanalDto.fromJson(Map<String, dynamic> j) =>
      MetaSemanalDto(atual: j['atual'] as int, alvo: j['alvo'] as int);
}

class PalavraAprendidaDto {
  const PalavraAprendidaDto({required this.palavra, required this.definicao});
  final String palavra;
  final String definicao;

  factory PalavraAprendidaDto.fromJson(Map<String, dynamic> j) =>
      PalavraAprendidaDto(
        palavra: j['palavra'] as String,
        definicao: j['definicao'] as String,
      );
}

/// Evolução por dimensão de uma redação já analisada (R-RD-6): cada dimensão
/// da rubrica classificada em 4 níveis nomeados — nunca nota numérica
/// (R-RS-2).
class NivelDimensaoDto {
  const NivelDimensaoDto({
    required this.redacaoId,
    required this.analisadaEm,
    required this.niveis,
  });

  final int redacaoId;
  final DateTime? analisadaEm;

  /// dimensão → 'começando' | 'avançando' | 'consolidando' | 'dominando'.
  final Map<String, String> niveis;

  factory NivelDimensaoDto.fromJson(Map<String, dynamic> j) => NivelDimensaoDto(
        redacaoId: j['redacao_id'] as int,
        analisadaEm: j['analisada_em'] == null
            ? null
            : DateTime.parse(j['analisada_em'] as String),
        niveis: (j['niveis'] as Map).cast<String, String>(),
      );
}

/// Resposta de `GET /v1/responsavel/perfis/{id}/resumo`.
class ResumoSemanalDto {
  const ResumoSemanalDto({
    required this.perfilUsuarioId,
    required this.apelido,
    required this.palavrasDominadas,
    required this.minutosNaSemana,
    required this.sessoesNaSemana,
    required this.aprendeuEssaSemana,
    required this.evolucaoRedacao,
  });

  final int perfilUsuarioId;
  final String apelido;
  final MetaSemanalDto palavrasDominadas;
  final int minutosNaSemana;
  final int sessoesNaSemana;
  final List<PalavraAprendidaDto> aprendeuEssaSemana;
  final List<NivelDimensaoDto> evolucaoRedacao;

  factory ResumoSemanalDto.fromJson(Map<String, dynamic> j) => ResumoSemanalDto(
        perfilUsuarioId: j['perfil_usuario_id'] as int,
        apelido: j['apelido'] as String,
        palavrasDominadas:
            MetaSemanalDto.fromJson(j['palavras_dominadas'] as Map<String, dynamic>),
        minutosNaSemana: j['minutos_na_semana'] as int,
        sessoesNaSemana: j['sessoes_na_semana'] as int,
        aprendeuEssaSemana: (j['aprendeu_essa_semana'] as List)
            .map((e) => PalavraAprendidaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        evolucaoRedacao: (j['evolucao_redacao'] as List)
            .map((e) => NivelDimensaoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
