import 'dart:math' as math;

import 'package:characters/characters.dart';

import '../identidade/models.dart';
import 'data/trilha_models.dart';
import 'home_data.dart';

/// Traduz os contratos do servidor (`/me` + `/trilha`) no [HomeData] que a UI
/// consome. É o único ponto que conhece os dois lados — trocar/estender um
/// campo do backend mexe só aqui, não nos widgets.
///
/// Princípio cliente-fino: rende a verdade do servidor e **deriva** apenas o
/// que é puramente de apresentação. Campos ainda não expostos pela API estão
/// marcados com `TODO(backend)`.
abstract final class HomeMapper {
  /// Fallback da meta quando o `/me` vier sem `meta_semanal` (aluno sem turma
  /// — não acontece no fluxo normal). Zero sobre o default do produto.
  static const _metaSemanalFallback = WeeklyGoal(current: 0, target: 5);

  static HomeData from({required Me me, required Trilha trilha}) {
    final destinos = trilha.destinosEmOrdem;
    final atualIdx = _indiceAtual(destinos);

    return HomeData(
      studentName: me.nome,
      avatarInitial: _inicial(me.nome),
      wordsMastered: me.progresso.palavrasDominadas,
      level: _nivel(destinos),
      // O rótulo do mockup ("3.120 / 4.500 XP") é xp acumulado sobre o teto do
      // nó atual; a barra reflete a mesma fração.
      xpCurrent: trilha.xpTotal,
      xpTarget: trilha.noAtual?.xpLimiar ?? math.max(trilha.xpTotal, 1),
      weeklyGoal: me.metaSemanal == null
          ? _metaSemanalFallback
          : WeeklyGoal(
              current: me.metaSemanal!.atual,
              target: me.metaSemanal!.alvo,
            ),
      lesson: _licao(trilha, destinos, atualIdx),
      trail: _fita(destinos, atualIdx),
    );
  }

  static String _inicial(String nome) {
    final t = nome.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  /// Nível de gamificação = nós já concluídos + 1 (o nó atual é o seu nível).
  static int _nivel(List<TrilhaDestino> destinos) {
    final concluidos =
        destinos.fold<int>(0, (sum, d) => sum + d.nosConcluidos);
    return concluidos + 1;
  }

  /// Índice do destino atual: o marcado como `atual`; senão o primeiro não
  /// concluído; senão o último (trilha inteira concluída).
  static int _indiceAtual(List<TrilhaDestino> destinos) {
    if (destinos.isEmpty) return -1;
    final atual = destinos.indexWhere((d) => d.atual);
    if (atual != -1) return atual;
    final pendente = destinos.indexWhere((d) => !d.concluido);
    return pendente != -1 ? pendente : destinos.length - 1;
  }

  static ContinueLesson? _licao(
    Trilha trilha,
    List<TrilhaDestino> destinos,
    int atualIdx,
  ) {
    final no = trilha.noAtual;
    if (no == null || atualIdx < 0) return null;
    final destino = destinos[atualIdx];
    return ContinueLesson(
      city: no.destinoNome,
      country: no.paisNome,
      lessonIndex: math.min(destino.nosConcluidos + 1, destino.nosTotal),
      lessonTotal: destino.nosTotal,
      imageAsset: assetParaCidade(no.destinoNome),
    );
  }

  /// Até 3 nós centrados no atual: anterior · atual · próximo.
  static List<TrailNode> _fita(List<TrilhaDestino> destinos, int atualIdx) {
    if (destinos.isEmpty || atualIdx < 0) return const [];
    final janela = <TrailNode>[];
    for (var i = atualIdx - 1; i <= atualIdx + 1; i++) {
      if (i < 0 || i >= destinos.length) continue;
      janela.add(_no(destinos[i]));
    }
    return janela;
  }

  static TrailNode _no(TrilhaDestino d) => TrailNode(
        name: d.nome,
        status: d.atual
            ? TrailNodeStatus.current
            : d.concluido
                ? TrailNodeStatus.done
                : TrailNodeStatus.locked,
        imageAsset: assetParaCidade(d.nome),
      );

  /// Resolve a arte de um destino pelos assets empacotados. O Brasil tem os
  /// 5 destinos ilustrados; os demais caem no placeholder do widget (`null`).
  // TODO(backend): servir asset_ref por destino na /v1/trilha.
  static String? assetParaCidade(String nome) {
    final n = _normalizar(nome);
    if (n.contains('rio')) return 'assets/images/rio.webp';
    if (n.contains('iguacu') || n.contains('foz')) {
      return 'assets/images/foz_iguacu.webp';
    }
    if (n.contains('amazonia')) return 'assets/images/amazonia.webp';
    if (n.contains('noronha')) return 'assets/images/noronha.webp';
    if (n.contains('lencois')) return 'assets/images/lencois.webp';
    if (n.contains('paris')) return 'assets/images/paris.webp';
    return null;
  }

  static String _normalizar(String s) {
    const acentos = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const limpos = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = s.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.characters) {
      final i = acentos.indexOf(ch);
      buffer.write(i == -1 ? ch : limpos[i]);
    }
    return buffer.toString();
  }
}
