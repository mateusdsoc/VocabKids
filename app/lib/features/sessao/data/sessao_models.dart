/// DTOs da sessão, espelhando `sessao/schemas.py` (SessaoOut, RespostaOut,
/// ResumoOut) e o `RecompensaOut` da trilha. Apenas desserialização — a
/// tradução para modelos de apresentação vive no `SessaoMapper`.
///
/// Cliente fino: nenhum slot carrega a resposta correta; ela só aparece em
/// [RespostaDto.respostaCorreta], **após** responder (feedback).
library;

/// Um slot da fila: card de descoberta ou questão (união discriminada por
/// `tipo`, como no backend).
sealed class SlotDto {
  const SlotDto();

  factory SlotDto.fromJson(Map<String, dynamic> j) => switch (j['tipo']) {
        'card' => CardSlotDto.fromJson(j),
        'questao' => QuestaoSlotDto.fromJson(j),
        _ => throw FormatException('slot de tipo desconhecido: ${j['tipo']}'),
      };
}

/// Conteúdo do card de descoberta (`CardPalavra`).
class CardPalavraDto {
  const CardPalavraDto({
    required this.id,
    required this.lema,
    required this.definicao,
    required this.exemploUso,
    required this.audioUrl,
    required this.sinonimos,
  });

  final int id;
  final String lema;
  final String definicao;
  final String exemploUso;
  final String? audioUrl;
  final List<String> sinonimos;

  factory CardPalavraDto.fromJson(Map<String, dynamic> j) => CardPalavraDto(
        id: j['id'] as int,
        lema: j['lema'] as String,
        definicao: j['definicao'] as String,
        exemploUso: j['exemplo_uso'] as String,
        audioUrl: j['audio_url'] as String?,
        sinonimos: (j['sinonimos'] as List).cast<String>(),
      );
}

class CardSlotDto extends SlotDto {
  const CardSlotDto({required this.palavra});

  final CardPalavraDto palavra;

  factory CardSlotDto.fromJson(Map<String, dynamic> j) => CardSlotDto(
        palavra: CardPalavraDto.fromJson(j['palavra'] as Map<String, dynamic>),
      );
}

class QuestaoSlotDto extends SlotDto {
  const QuestaoSlotDto({
    required this.questaoId,
    required this.palavraId,
    required this.lema,
    required this.nivel,
    required this.isRevisao,
    required this.enunciado,
    required this.opcoes,
  });

  final int questaoId;
  final int palavraId;
  final String lema;
  final int nivel; // 1..4 — guia o tipo de questão na apresentação
  final bool isRevisao;
  final String enunciado;
  final List<String> opcoes; // já embaralhadas server-side; sem a correta

  factory QuestaoSlotDto.fromJson(Map<String, dynamic> j) => QuestaoSlotDto(
        questaoId: j['questao_id'] as int,
        palavraId: j['palavra_id'] as int,
        lema: j['lema'] as String,
        nivel: j['nivel'] as int,
        isRevisao: j['is_revisao'] as bool,
        enunciado: j['enunciado'] as String,
        opcoes: (j['opcoes'] as List).cast<String>(),
      );
}

/// Resposta de `POST /v1/sessoes` — a fila inteira em lote.
class SessaoAbertaDto {
  const SessaoAbertaDto({required this.sessaoId, required this.slots});

  final int sessaoId;
  final List<SlotDto> slots;

  factory SessaoAbertaDto.fromJson(Map<String, dynamic> j) => SessaoAbertaDto(
        sessaoId: j['sessao_id'] as int,
        slots: (j['slots'] as List)
            .map((e) => SlotDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Colecionável concedido numa resposta (`RecompensaOut`).
class RecompensaDto {
  const RecompensaDto({
    required this.tipo,
    required this.referencia,
    required this.assetRef,
  });

  final String tipo; // cartao_postal | carimbo | selo
  final String referencia; // destino:{id} | pais:{id} | feito:{slug}
  final String? assetRef;

  factory RecompensaDto.fromJson(Map<String, dynamic> j) => RecompensaDto(
        tipo: j['tipo'] as String,
        referencia: j['referencia'] as String,
        assetRef: j['asset_ref'] as String?,
      );
}

/// Resposta de `POST /v1/sessoes/{id}/respostas` — correção server-side.
class RespostaDto {
  const RespostaDto({
    required this.correto,
    required this.respostaCorreta,
    required this.tentativas,
    required this.xpGanho,
    required this.comboAtual,
    required this.xpTotal,
    required this.estadoPalavra,
    required this.dominou,
    required this.recompensas,
    required this.fila,
  });

  final bool correto;
  final String respostaCorreta; // revelada só após responder; a UI de erro
  // não a exibe (a questão volta no fim da fila, produto 3.4)
  final int tentativas;
  final int xpGanho;
  final int comboAtual;
  final int xpTotal;
  final String estadoPalavra; // descoberta|nivel_2..4|dominada
  final bool dominou;
  final List<RecompensaDto> recompensas;

  /// Fila restante **já reordenada pelo servidor** (no erro, o retry foi para
  /// o fim). O app renderiza esta ordem, sem reimplementar a intercalação.
  final List<SlotDto> fila;

  factory RespostaDto.fromJson(Map<String, dynamic> j) => RespostaDto(
        correto: j['correto'] as bool,
        respostaCorreta: j['resposta_correta'] as String,
        tentativas: j['tentativas'] as int,
        xpGanho: j['xp_ganho'] as int,
        comboAtual: j['combo_atual'] as int,
        xpTotal: j['xp_total'] as int,
        estadoPalavra: j['estado_palavra'] as String,
        dominou: j['dominou'] as bool,
        recompensas: (j['recompensas'] as List? ?? const [])
            .map((e) => RecompensaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        fila: (j['fila'] as List? ?? const [])
            .map((e) => SlotDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Resposta de `POST /v1/sessoes/{id}/fim` (`ResumoOut`).
///
/// `nivelAnterior`/`nivelAtual` são o **nível de dificuldade** da adaptação
/// (invisível para o aluno) — não confundir com o "nível" de gamificação do
/// Resumo, que vem da trilha (nós concluídos).
class ResumoFimDto {
  const ResumoFimDto({
    required this.xpGanho,
    required this.xpTotal,
    required this.palavrasDominadas,
    required this.nivelAnterior,
    required this.nivelAtual,
    required this.nivelMudou,
    required this.sessoesTotal,
  });

  final int xpGanho;
  final int xpTotal;
  final int palavrasDominadas;
  final int nivelAnterior;
  final int nivelAtual;
  final bool nivelMudou;
  final int sessoesTotal;

  factory ResumoFimDto.fromJson(Map<String, dynamic> j) => ResumoFimDto(
        xpGanho: j['xp_ganho'] as int,
        xpTotal: j['xp_total'] as int,
        palavrasDominadas: j['palavras_dominadas'] as int,
        nivelAnterior: j['nivel_anterior'] as int,
        nivelAtual: j['nivel_atual'] as int,
        nivelMudou: j['nivel_mudou'] as bool,
        sessoesTotal: j['sessoes_total'] as int,
      );
}
