import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipográfico da marca — quatro famílias com papéis fixos
/// (idêntico aos mockups):
///
/// - **Fredoka** → display/headings arredondados (números, cidades, títulos).
/// - **Nunito** → corpo, rótulos e textos de apoio.
/// - **Caveat** → manuscrito, exclusivo do selo "Passaporte".
/// - **Space Mono** → micro-rótulos em caixa alta (eyebrows).
///
/// Tudo passa por aqui para que peso/altura/família fiquem num só lugar.
/// As cores **não** são fixadas nos estilos: quem renderiza aplica o token de
/// [AppColors] adequado — assim o mesmo estilo serve claro e escuro.
abstract final class AppType {
  static TextStyle fredoka({
    required double size,
    FontWeight weight = FontWeight.w600,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle nunito({
    required double size,
    FontWeight weight = FontWeight.w700,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle caveat({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.caveat(fontSize: size, fontWeight: weight, color: color);

  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 1.4,
    Color? color,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// [TextTheme] base do app (Nunito como corpo, Fredoka nos títulos), aplicado
  /// no [ThemeData]. As telas usam majoritariamente os helpers acima para casar
  /// 1:1 com o mockup, mas isto garante um default coerente para widgets Material.
  static TextTheme textTheme(Color ink) {
    final body = GoogleFonts.nunitoTextTheme();
    final display = GoogleFonts.fredokaTextTheme();
    return body
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge,
          headlineMedium: display.headlineMedium,
          headlineSmall: display.headlineSmall,
          titleLarge: display.titleLarge,
        )
        .apply(bodyColor: ink, displayColor: ink);
  }
}
