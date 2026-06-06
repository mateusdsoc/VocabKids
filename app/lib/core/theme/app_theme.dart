import 'package:flutter/material.dart';

import '../platform/adaptive.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Monta os [ThemeData] claro e escuro a partir dos tokens de [AppColors].
///
/// A estratégia é "tokens primeiro": cada tema injeta seu [AppColors] como
/// [ThemeExtension] e deriva o [ColorScheme]/[TextTheme] dele. Trocar de tema
/// (ou animar a transição) não exige nenhuma ramificação nas telas.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.ink,
      surface: c.paper,
      onSurface: c.ink,
      error: const Color(0xFFD2553F),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      // Sem onda de ripple no iOS — toque "à iOS" sem perder o realce.
      splashFactory: adaptiveSplashFactory,
      textTheme: AppType.textTheme(c.ink),
      extensions: [c],
    );
  }
}
