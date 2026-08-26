/// DTOs da Redação, espelhando `backend/app/redacao/schemas.py`
/// (`RedacoesOut`, `EnviarRedacaoOut`, `AnaliseOut`). Apenas desserialização —
/// a tradução para modelos de apresentação vive no `RedacaoMapper`.
library;

/// Um item de `GET /v1/redacoes` — a **atribuição**, não a redação em si.
/// `status: null` = ainda não enviou (é a "aberta"); os demais valores
/// (`processando`/`erro_ingestao`/`erro_analise`/`revisao_humana`/`analisada`)
/// espelham o ciclo de vida da redação associada.
class RedacaoAtribuicaoDto {
  const RedacaoAtribuicaoDto({
    required this.id,
    required this.tema,
    required this.prazo,
    required this.origem,
    required this.redacaoId,
    required this.status,
  });

  final int id;
  final String tema;
  final DateTime? prazo;
  final String? origem;
  final int? redacaoId;
  final String? status;

  factory RedacaoAtribuicaoDto.fromJson(Map<String, dynamic> j) =>
      RedacaoAtribuicaoDto(
        id: j['id'] as int,
        tema: j['tema'] as String,
        prazo: j['prazo'] == null ? null : DateTime.parse(j['prazo'] as String),
        origem: j['origem'] as String?,
        redacaoId: j['redacao_id'] as int?,
        status: j['status'] as String?,
      );
}

class RedacoesDto {
  const RedacoesDto({required this.itens, required this.extrasRestantesNoMes});

  final List<RedacaoAtribuicaoDto> itens;
  final int extrasRestantesNoMes;

  factory RedacoesDto.fromJson(Map<String, dynamic> j) => RedacoesDto(
        itens: (j['itens'] as List)
            .map((e) => RedacaoAtribuicaoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        extrasRestantesNoMes: j['extras_restantes_no_mes'] as int,
      );
}

/// Resposta de `POST /v1/redacoes/{atribuicaoId}/enviar`. Síncrona: só volta
/// depois que triagem + análise (ou a rejeição) já terminaram no servidor.
class EnviarRedacaoOutDto {
  const EnviarRedacaoOutDto({required this.redacaoId, required this.status});

  final int redacaoId;
  final String status;

  factory EnviarRedacaoOutDto.fromJson(Map<String, dynamic> j) =>
      EnviarRedacaoOutDto(
        redacaoId: j['redacao_id'] as int,
        status: j['status'] as String,
      );
}

/// Um trecho do texto que a anotação se refere (offsets já resolvidos pelo
/// servidor sobre `texto_extraido`). Lista vazia na anotação = holística.
class AncoraDto {
  const AncoraDto({
    required this.inicio,
    required this.fim,
    required this.trecho,
    required this.ocorrencia,
  });

  final int inicio;
  final int fim;
  final String trecho;
  final int ocorrencia;

  factory AncoraDto.fromJson(Map<String, dynamic> j) => AncoraDto(
        inicio: j['inicio'] as int,
        fim: j['fim'] as int,
        trecho: j['trecho'] as String,
        ocorrencia: j['ocorrencia'] as int,
      );
}

class AnotacaoDto {
  const AnotacaoDto({
    required this.dimensao,
    required this.titulo,
    required this.comentario,
    required this.sugestoes,
    required this.ancoras,
  });

  final String dimensao;
  final String titulo;
  final String comentario;
  final List<String> sugestoes;
  final List<AncoraDto> ancoras;

  factory AnotacaoDto.fromJson(Map<String, dynamic> j) => AnotacaoDto(
        dimensao: j['dimensao'] as String,
        titulo: j['titulo'] as String,
        comentario: j['comentario'] as String,
        sugestoes: (j['sugestoes'] as List? ?? const []).cast<String>(),
        ancoras: (j['ancoras'] as List? ?? const [])
            .map((e) => AncoraDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AnaliseDto {
  const AnaliseDto({
    required this.versao,
    required this.dimensoes,
    required this.pontosFortes,
    required this.anotacoes,
  });

  final int versao;
  final List<String> dimensoes;
  final List<String> pontosFortes;
  final List<AnotacaoDto> anotacoes;

  factory AnaliseDto.fromJson(Map<String, dynamic> j) => AnaliseDto(
        versao: j['versao'] as int,
        dimensoes: (j['dimensoes'] as List).cast<String>(),
        pontosFortes: (j['pontos_fortes'] as List).cast<String>(),
        anotacoes: (j['anotacoes'] as List)
            .map((e) => AnotacaoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PalavraNovaDto {
  const PalavraNovaDto({required this.palavra, required this.gatilho});

  final String palavra;
  final String gatilho;

  factory PalavraNovaDto.fromJson(Map<String, dynamic> j) => PalavraNovaDto(
        palavra: j['palavra'] as String,
        gatilho: j['gatilho'] as String,
      );
}

/// Resposta de `GET /v1/redacoes/{redacaoId}/analise`. `analise` só vem
/// preenchida quando `status == 'analisada'`; `texto_extraido` vem vazio em
/// `revisao_humana` (o servidor nunca devolve texto sensível de volta).
class AnaliseOutDto {
  const AnaliseOutDto({
    required this.redacaoId,
    required this.status,
    required this.textoExtraido,
    required this.analise,
    required this.palavrasNovas,
  });

  final int redacaoId;
  final String status;
  final String textoExtraido;
  final AnaliseDto? analise;
  final List<PalavraNovaDto> palavrasNovas;

  factory AnaliseOutDto.fromJson(Map<String, dynamic> j) => AnaliseOutDto(
        redacaoId: j['redacao_id'] as int,
        status: j['status'] as String,
        textoExtraido: j['texto_extraido'] as String,
        analise: j['analise'] == null
            ? null
            : AnaliseDto.fromJson(j['analise'] as Map<String, dynamic>),
        palavrasNovas: (j['palavras_novas'] as List? ?? const [])
            .map((e) => PalavraNovaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
