import 'dart:ui' show clampDouble;

/// Estado de um nó da trilha na fita de progresso.
enum TrailNodeStatus { done, current, locked }

/// Um nó (destino/cidade) exibido na fita "Sua trilha".
class TrailNode {
  const TrailNode({
    required this.name,
    required this.status,
    this.imageAsset,
  });

  final String name;
  final TrailNodeStatus status;

  /// Asset da arte do destino, ou `null` → o widget desenha um placeholder.
  final String? imageAsset;
}

/// Meta semanal (palavras dominadas/semana — unidade do produto, 3.5).
class WeeklyGoal {
  const WeeklyGoal({required this.current, required this.target});
  final int current;
  final int target;

  double get fraction => target == 0 ? 0 : clampDouble(current / target, 0, 1);
  bool get completed => current >= target;
}

/// Card "Continuar" — a próxima lição a um toque.
class ContinueLesson {
  const ContinueLesson({
    required this.city,
    required this.country,
    required this.lessonIndex,
    required this.lessonTotal,
    this.imageAsset,
  });

  final String city;
  final String country;
  final int lessonIndex; // 1-based
  final int lessonTotal;
  final String? imageAsset;

  double get fraction =>
      lessonTotal == 0 ? 0 : clampDouble(lessonIndex / lessonTotal, 0, 1);
}

/// Modelo de apresentação único que a Home consome. Desacopla os widgets dos
/// contratos do backend: as telas só conhecem [HomeData], e o [HomeMapper]
/// concentra toda a tradução `/me` + `/trilha` → UI.
class HomeData {
  const HomeData({
    required this.studentName,
    required this.avatarInitial,
    required this.wordsMastered,
    required this.level,
    required this.xpCurrent,
    required this.xpTarget,
    required this.weeklyGoal,
    required this.lesson,
    required this.trail,
  });

  final String studentName;
  final String avatarInitial;
  final int wordsMastered;
  final int level;
  final int xpCurrent;
  final int xpTarget;
  final WeeklyGoal weeklyGoal;

  /// `null` quando a trilha foi concluída (sem próximo nó).
  final ContinueLesson? lesson;

  /// Até 3 nós (anterior · atual · próximo).
  final List<TrailNode> trail;

  double get xpFraction =>
      xpTarget == 0 ? 0 : clampDouble(xpCurrent / xpTarget, 0, 1);

  /// Dados de exemplo (espelham o mockup) — úteis para previews/testes de UI
  /// sem backend.
  factory HomeData.sample() => const HomeData(
        studentName: 'Ana',
        avatarInitial: 'A',
        wordsMastered: 23,
        level: 4,
        xpCurrent: 3120,
        xpTarget: 4500,
        weeklyGoal: WeeklyGoal(current: 6, target: 10),
        lesson: ContinueLesson(
          city: 'Rio de Janeiro',
          country: 'Brasil',
          lessonIndex: 3,
          lessonTotal: 6,
          imageAsset: 'assets/images/rio.png',
        ),
        trail: [
          TrailNode(
              name: 'Salvador',
              status: TrailNodeStatus.done,
              imageAsset: 'assets/images/rio.png'),
          TrailNode(
              name: 'Rio',
              status: TrailNodeStatus.current,
              imageAsset: 'assets/images/rio.png'),
          TrailNode(
              name: 'Paris',
              status: TrailNodeStatus.locked,
              imageAsset: 'assets/images/paris.png'),
        ],
      );
}
