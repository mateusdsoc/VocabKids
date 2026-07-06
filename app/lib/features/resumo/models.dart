/// Modelos de apresentação do Resumo de sessão (produto 3.7).
///
/// Hoje alimentados por um exemplo ([sampleSummary]); a estrutura espelha o que
/// `POST /v1/sessoes/{id}/fim` devolve (resumo + adaptação), para que o wiring
/// com o backend troque só a fonte, não os widgets.
library;

import 'dart:ui' show clampDouble;

import '../passaporte/models.dart';

/// Como uma palavra trabalhada na sessão evoluiu.
enum WordChange { dominated, levelUp }

/// Progresso de uma palavra ao fim da sessão (o que importa no resumo — não há
/// % de acerto nem tempo, por decisão de produto).
class WordProgress {
  const WordProgress({
    required this.word,
    required this.change,
    this.fromLevel,
    this.toLevel,
  });

  final String word;
  final WordChange change;

  /// Níveis de/para quando [change] é [WordChange.levelUp].
  final int? fromLevel;
  final int? toLevel;
}

/// Teaser do colecionável recém-desbloqueado (Modo Conquista do Passaporte).
class SummaryAchievement {
  const SummaryAchievement({
    required this.kicker,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.conquista,
  });

  final String kicker;
  final String title;
  final String subtitle;

  /// Arte do cartão-postal; `null` → o widget desenha um placeholder.
  final String? imageAsset;

  /// Item para abrir o **Modo Conquista** do Passaporte (reveal). `null` →
  /// o teaser fica sem ação (estado de transição enquanto não há wiring).
  final Conquista? conquista;
}

/// Resumo completo de uma sessão concluída.
class SessionSummary {
  const SessionSummary({
    required this.city,
    required this.lesson,
    required this.xpGained,
    required this.level,
    required this.xpFrom,
    required this.xpTo,
    required this.xpTarget,
    required this.words,
    this.combo,
    this.achievement,
    this.noCompletado = false,
  });

  final String city;
  final int lesson;

  /// XP ganho na sessão (número-herói).
  final int xpGained;

  /// Combo de acertos em sequência; `null` esconde o chip.
  final int? combo;

  final int level;

  /// XP antes/depois da sessão e alvo do nível (para a barra com ganho).
  final int xpFrom;
  final int xpTo;
  final int xpTarget;

  /// Palavras trabalhadas (dominadas / subiram de nível).
  final List<WordProgress> words;

  /// Item novo no Passaporte; `null` → resumo padrão (sem conquista).
  final SummaryAchievement? achievement;

  /// A sessão cruzou o teto de XP do nó da trilha ("completar nó", 3.7) —
  /// gatilho real da animação de chegada ao aterrissar na Trilha.
  final bool noCompletado;

  // Clampadas: quando um nó da trilha é cruzado no meio da sessão, o XP passa
  // do teto capturado na abertura — a barra satura em cheia, sem estourar.
  double get baseFraction =>
      xpTarget == 0 ? 0 : clampDouble(xpFrom / xpTarget, 0, 1);
  double get gainFraction =>
      xpTarget == 0 ? 0 : clampDouble(xpTo / xpTarget, 0, 1);

  /// Exemplo que espelha os frames do design (Rio · Lição 3).
  static const SessionSummary sample = SessionSummary(
    city: 'Rio de Janeiro',
    lesson: 3,
    xpGained: 480,
    combo: 5,
    level: 4,
    xpFrom: 3120,
    xpTo: 3600,
    xpTarget: 4500,
    words: [
      WordProgress(word: 'vasto', change: WordChange.dominated),
      WordProgress(
          word: 'relevante',
          change: WordChange.levelUp,
          fromLevel: 2,
          toLevel: 3),
      WordProgress(
          word: 'âmbito', change: WordChange.levelUp, fromLevel: 1, toLevel: 2),
    ],
  );

  /// Mesmo exemplo, com o teaser do cartão-postal do Rio (frame 2/4).
  /// `noCompletado`: a demo sempre celebra a chegada na Trilha (design).
  static const SessionSummary sampleWithAchievement = SessionSummary(
    city: 'Rio de Janeiro',
    lesson: 3,
    xpGained: 480,
    combo: 5,
    level: 4,
    xpFrom: 3120,
    xpTo: 3600,
    xpTarget: 4500,
    noCompletado: true,
    words: [
      WordProgress(word: 'vasto', change: WordChange.dominated),
      WordProgress(
          word: 'relevante',
          change: WordChange.levelUp,
          fromLevel: 2,
          toLevel: 3),
    ],
    achievement: SummaryAchievement(
      kicker: 'Novo no Passaporte!',
      title: 'Cartão-postal do Rio',
      subtitle: 'Você desbloqueou um carimbo de viagem.',
      imageAsset: 'assets/images/rio.png',
      conquista: Conquista.sampleRio,
    ),
  );
}
