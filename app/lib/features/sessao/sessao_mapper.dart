import 'dart:math' as math;

import '../home/data/trilha_models.dart';
import '../home/home_mapper.dart' show HomeMapper;
import '../passaporte/models.dart';
import '../resumo/models.dart';
import 'data/sessao_models.dart';
import 'models.dart';

/// Traduz os contratos da sessão (`/v1/sessoes`, `/respostas`, `/fim`) nos
/// modelos de apresentação que os widgets consomem. Único ponto que conhece os
/// dois lados — trocar um campo do backend mexe aqui, não nas telas.
///
/// Cliente fino: nada aqui corrige, pontua ou reordena; só **apresenta** fatos
/// que o servidor devolveu.
abstract final class SessaoMapper {
  /// Ordem fixa das letras das alternativas.
  static const _letras = ['A', 'B', 'C', 'D', 'E', 'F'];

  /// Nível "de exibição" de cada estado de palavra (o rótulo `Nv N` do Resumo).
  static const _nivelDoEstado = {
    'descoberta': 1,
    'nivel_1': 1,
    'nivel_2': 2,
    'nivel_3': 3,
    'nivel_4': 4,
    'dominada': 5,
  };

  static int nivelDoEstado(String estado) => _nivelDoEstado[estado] ?? 1;

  // ───────────────────────── fila → passos ─────────────────────────

  static List<SessionStep> stepsDe(List<SlotDto> slots) =>
      slots.map(stepDe).toList();

  static SessionStep stepDe(SlotDto slot) => switch (slot) {
        CardSlotDto(:final palavra) => DiscoveryStep(discoveryDe(palavra)),
        QuestaoSlotDto() => QuestionStep(questaoDe(slot)),
      };

  static SessionDiscovery discoveryDe(CardPalavraDto p) => SessionDiscovery(
        word: p.lema,
        definition: p.definicao,
        example: p.exemploUso,
        exampleHighlight: p.lema,
      );

  /// Slot de questão → [SessionQuestion]. O `nivel` (1..4) guia a condução
  /// visual (produto 3.2): N1 significado, N2 sinônimo, N3 completar (lacuna),
  /// N4 julgar uso (frases com a palavra em negrito).
  static SessionQuestion questaoDe(QuestaoSlotDto q) {
    final kind = switch (q.nivel) {
      1 => QuestionKind.significado,
      2 => QuestionKind.sinonimo,
      3 => QuestionKind.completar,
      _ => QuestionKind.julgarUso,
    };
    // O painel destaca o token fixo '_____'; o banco escreve a lacuna com 3+
    // underscores — normaliza aqui (apresentação, não conteúdo).
    final temLacuna = RegExp('_{3,}').hasMatch(q.enunciado);
    final stem =
        temLacuna ? q.enunciado.replaceAll(RegExp('_{3,}'), '_____') : q.enunciado;

    return SessionQuestion(
      kind: kind,
      stem: stem,
      questaoId: q.questaoId,
      palavraId: q.palavraId,
      word: q.lema,
      // Sublinha a palavra no enunciado só quando ela aparece de fato.
      highlightWord:
          !temLacuna && q.enunciado.toLowerCase().contains(q.lema.toLowerCase())
              ? q.lema
              : null,
      blank: temLacuna,
      options: [
        for (var i = 0; i < q.opcoes.length; i++)
          QuestionOption(
            key: i < _letras.length ? _letras[i] : '${i + 1}',
            text: q.opcoes[i],
            // Nas frases do julgar uso, a palavra vai em negrito.
            boldWord: kind == QuestionKind.julgarUso ? q.lema : null,
          ),
      ],
    );
  }

  // ─────────────────────── recompensas → conquistas ───────────────────────

  /// Recompensa de uma resposta → conquista revelável no Modo Conquista,
  /// resolvendo cidade/país pelo snapshot da trilha. `null` quando não dá
  /// para resolver ou o tipo não tem reveal aqui — o selo precisa do grid da
  /// coleção, então entra pendente via `GET /v1/passaporte` (PassaporteMapper).
  static Conquista? conquistaDe(RecompensaDto r, Trilha trilha) {
    final alvoId = int.tryParse(r.referencia.split(':').elementAtOrNull(1) ?? '');
    if (alvoId == null) return null;
    switch (r.tipo) {
      case 'cartao_postal':
        for (final pais in trilha.paises) {
          for (final destino in pais.destinos) {
            if (destino.id == alvoId) {
              final paisEnum = paisDe(pais.nome);
              if (paisEnum == null) return null;
              return ConquistaPostal(
                colecionavelId: r.colecionavelId,
                destino: Destino(cidade: destino.nome, conquistado: true),
                pais: paisEnum,
              );
            }
          }
        }
        return null;
      case 'carimbo':
        for (final pais in trilha.paises) {
          if (pais.id == alvoId) {
            final paisEnum = paisDe(pais.nome);
            if (paisEnum == null) return null;
            return ConquistaCarimbo(
                colecionavelId: r.colecionavelId, pais: paisEnum);
          }
        }
        return null;
      default:
        return null;
    }
  }

  // ───────────────────────────── resumo ─────────────────────────────

  /// Monta o [SessionSummary] do Resumo: números do servidor (`/fim`),
  /// contexto do nó da trilha capturado na abertura, progresso por palavra
  /// acumulado das respostas e o teaser do primeiro cartão-postal ganho.
  static SessionSummary summaryDe({
    required ResumoFimDto fim,
    required Trilha trilha,
    required int combo,
    required List<WordProgress> palavras,
    required List<RecompensaDto> recompensas,
  }) {
    final destinos = trilha.destinosEmOrdem;
    final no = trilha.noAtual;
    final destinoAtual = destinos.where((d) => d.atual).firstOrNull ??
        destinos.where((d) => !d.concluido).firstOrNull;

    SummaryAchievement? achievement;
    final postal =
        recompensas.where((r) => r.tipo == 'cartao_postal').firstOrNull;
    if (postal != null) {
      final conquista = conquistaDe(postal, trilha);
      final cidade =
          conquista is ConquistaPostal ? conquista.destino.cidade : null;
      achievement = SummaryAchievement(
        kicker: 'Novo no Passaporte!',
        title: cidade != null ? 'Cartão-postal de $cidade' : 'Cartão-postal novo',
        subtitle: 'Você desbloqueou um carimbo de viagem.',
        imageAsset: cidade != null ? HomeMapper.assetParaCidade(cidade) : null,
        conquista: conquista,
      );
    }

    // Nível de gamificação = nós concluídos + 1 (mesma regra da Home). O
    // `nivel_atual` do /fim é o nível de dificuldade da adaptação — invisível
    // para o aluno, de propósito (produto 3.5).
    final nivel =
        destinos.fold<int>(0, (sum, d) => sum + d.nosConcluidos) + 1;

    return SessionSummary(
      city: no?.destinoNome ?? destinos.lastOrNull?.nome ?? '',
      lesson: destinoAtual == null
          ? 1
          : math.min(destinoAtual.nosConcluidos + 1, destinoAtual.nosTotal),
      xpGained: fim.xpGanho,
      combo: combo > 0 ? combo : null,
      level: nivel,
      // xp antes/depois pelo próprio servidor; o teto é o do nó na abertura.
      xpFrom: fim.xpTotal - fim.xpGanho,
      xpTo: fim.xpTotal,
      xpTarget: no?.xpLimiar ?? fim.xpTotal,
      words: palavras,
      achievement: achievement,
      // O nó capturado na abertura foi fechado se o XP final cruzou seu teto.
      noCompletado: no != null && fim.xpTotal >= no.xpLimiar,
    );
  }
}
