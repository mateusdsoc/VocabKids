import 'package:flutter/material.dart';

/// Tokens de cor da marca, portados fielmente dos dois mockups aprovados
/// (`design/Refino/Vocab - Telas Refinadas.html`):
///
/// - **Claro** = "Azul Brilhante" (areia + azul vivo).
/// - **Escuro** = "Capa do Passaporte" (navy + dourado champanhe).
///
/// O Material [ColorScheme] não cobre as semânticas próprias do app
/// (paper × bg, goal, accent, xp, line, track…), então elas vivem aqui como uma
/// [ThemeExtension]. Widgets leem via `context.colors`, nunca cores hardcoded —
/// é isso que faz a mesma árvore renderizar claro/escuro sem ramificação.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.paper,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.accentStrong,
    required this.xp,
    required this.ink,
    required this.muted,
    required this.goal,
    required this.onGoal,
    required this.warn,
    required this.accentInk,
    required this.track,
    required this.line,
    required this.ring,
    required this.homeIndicator,
    required this.avatarGradient,
  });

  /// Fundo da tela (canvas areia / navy).
  final Color bg;

  /// Superfície de cards (papel).
  final Color paper;

  /// Cor de ação primária (CTA, links, nó atual).
  final Color primary;

  /// Conteúdo sobre [primary].
  final Color onPrimary;

  /// Acento dourado (detalhes, ouro).
  final Color accent;

  /// Acento dourado em variante de maior contraste (texto).
  final Color accentStrong;

  /// Cor da barra de XP (azul no claro, dourado no escuro).
  final Color xp;

  /// Texto principal.
  final Color ink;

  /// Texto/ícones de baixa ênfase.
  final Color muted;

  /// Verde da meta semanal (idêntico nos dois temas, por decisão de marca).
  final Color goal;

  /// Conteúdo sobre [goal] (chip/ícone da meta).
  final Color onGoal;

  /// Atenção/erro **gentil** (âmbar terroso) — decisão de produto: o erro
  /// nunca é vermelho punitivo. Usado no feedback de resposta incorreta.
  final Color warn;

  /// Texto escuro sobre superfícies douradas (ex.: chip de combo).
  final Color accentInk;

  /// Trilho vazio de barras de progresso.
  final Color track;

  /// Borda hairline interna dos cards (`inset 0 0 0 1px`).
  final Color line;

  /// Anel decorativo ao redor do avatar.
  final Color ring;

  /// Indicador de "home" (barra inferior do aparelho) — relevante p/ overlays.
  final Color homeIndicator;

  /// Gradiente do avatar (top-left → bottom-right).
  final List<Color> avatarGradient;

  /// CLARO — Tela 01 · Azul Brilhante (areia + azul vivo).
  static const light = AppColors(
    bg: Color(0xFFFBF3E4),
    paper: Color(0xFFFFFDF8),
    primary: Color(0xFF1E7FD6),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFE0A82E),
    accentStrong: Color(0xFFB9851A),
    xp: Color(0xFF1E7FD6),
    ink: Color(0xFF33302B),
    muted: Color(0xFF9C8C7D),
    goal: Color(0xFF16A971),
    onGoal: Color(0xFFFFFFFF),
    warn: Color(0xFFC9821C), // âmbar terroso (erro gentil)
    accentInk: Color(0xFF6B4E0C),
    track: Color(0x29785A32), // rgba(120,90,50,.16)
    line: Color(0x29785A32),
    ring: Color(0x801E7FD6), // primary @ 50%
    homeIndicator: Color(0x47000000), // rgba(0,0,0,.28)
    avatarGradient: [Color(0xFF1E7FD6), Color(0xFF52AEF0)],
  );

  /// ESCURO — Tela 03 · Capa do Passaporte (navy + dourado champanhe).
  static const dark = AppColors(
    bg: Color(0xFF172A44),
    paper: Color(0xFF21385A),
    primary: Color(0xFF5FA9E0),
    onPrimary: Color(0xFF0E2235),
    accent: Color(0xFFD9C083),
    accentStrong: Color(0xFFD9C083),
    xp: Color(0xFFD9C083), // dourado discreto no escuro
    ink: Color(0xFFF2EAD9),
    muted: Color(0xFF9DB0C8),
    goal: Color(0xFF3FB97E),
    onGoal: Color(0xFFFFFFFF),
    warn: Color(0xFFE0A24E), // âmbar (erro gentil) no escuro
    accentInk: Color(0xFF23200F),
    track: Color(0x1FFFFFFF), // rgba(255,255,255,.12)
    line: Color(0x1AFFFFFF), // rgba(255,255,255,.10)
    ring: Color(0x8C5FA9E0), // primary @ 55%
    homeIndicator: Color(0x66FFFFFF), // rgba(255,255,255,.4)
    avatarGradient: [Color(0xFF5FA9E0), Color(0xFF3F86BD)],
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? paper,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? accentStrong,
    Color? xp,
    Color? ink,
    Color? muted,
    Color? goal,
    Color? onGoal,
    Color? warn,
    Color? accentInk,
    Color? track,
    Color? line,
    Color? ring,
    Color? homeIndicator,
    List<Color>? avatarGradient,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      paper: paper ?? this.paper,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      xp: xp ?? this.xp,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      goal: goal ?? this.goal,
      onGoal: onGoal ?? this.onGoal,
      warn: warn ?? this.warn,
      accentInk: accentInk ?? this.accentInk,
      track: track ?? this.track,
      line: line ?? this.line,
      ring: ring ?? this.ring,
      homeIndicator: homeIndicator ?? this.homeIndicator,
      avatarGradient: avatarGradient ?? this.avatarGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      xp: Color.lerp(xp, other.xp, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      goal: Color.lerp(goal, other.goal, t)!,
      onGoal: Color.lerp(onGoal, other.onGoal, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      track: Color.lerp(track, other.track, t)!,
      line: Color.lerp(line, other.line, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      homeIndicator: Color.lerp(homeIndicator, other.homeIndicator, t)!,
      avatarGradient: [
        Color.lerp(avatarGradient.first, other.avatarGradient.first, t)!,
        Color.lerp(avatarGradient.last, other.avatarGradient.last, t)!,
      ],
    );
  }
}

/// Açúcar para ler os tokens da marca: `context.colors.primary`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
