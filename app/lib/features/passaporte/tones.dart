import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models.dart';

/// Tinta decorativa por país — dá variedade aos postais/carimbos sem fugir da
/// paleta. Brasil (verde-mata), França (azul-índigo), Japão (rosa-carmim).
/// Decorativa, como `trilha_tones`: levemente diferente por tema para manter
/// contraste sobre areia (claro) e navy (escuro).
@immutable
class PaisTone {
  const PaisTone({required this.ink, required this.soft, required this.scene});

  /// Cor "tinta" do carimbo e detalhes.
  final Color ink;

  /// Versão suave para fundos/banhos (translúcida).
  final Color soft;

  /// Par de cores do degradê da "cena" do postal (topo → base).
  final List<Color> scene;
}

PaisTone paisTone(BuildContext context, Pais pais) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (pais) {
    case Pais.brasil:
      return dark
          ? const PaisTone(
              ink: Color(0xFF6FC79A),
              soft: Color(0x266FC79A),
              scene: [Color(0xFF2E8B6A), Color(0xFF1C5E4A)],
            )
          : const PaisTone(
              ink: Color(0xFF1E8A5E),
              soft: Color(0x221E8A5E),
              scene: [Color(0xFF4FB985), Color(0xFF2E8B6A)],
            );
    case Pais.franca:
      return dark
          ? const PaisTone(
              ink: Color(0xFF8AB4E8),
              soft: Color(0x268AB4E8),
              scene: [Color(0xFF4F7FD0), Color(0xFF324F86)],
            )
          : const PaisTone(
              ink: Color(0xFF3B66B5),
              soft: Color(0x223B66B5),
              scene: [Color(0xFF6E97DC), Color(0xFF4F7FD0)],
            );
    case Pais.japao:
      return dark
          ? const PaisTone(
              ink: Color(0xFFE090A0),
              soft: Color(0x26E090A0),
              scene: [Color(0xFFC8607A), Color(0xFF8E4459)],
            )
          : const PaisTone(
              ink: Color(0xFFC0506A),
              soft: Color(0x22C0506A),
              scene: [Color(0xFFD9748C), Color(0xFFC0506A)],
            );
  }
}

/// Helper: cor sobre a qual o texto da cena (branco) sempre fica legível.
extension AppColorsSceneX on AppColors {
  Color get sceneInk => Colors.white;
}
