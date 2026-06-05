import 'package:flutter/material.dart';

/// Conjunto de ícones do app, centralizado.
///
/// Os mockups usam ícones de linha desenhados à mão (SVG). Aqui mapeamos cada um
/// para o equivalente mais próximo do Material — num só lugar, para trocar a
/// fonte de ícones (ou plugar um set custom) sem caçar usos pela base.
abstract final class AppIcons {
  static const play = Icons.play_arrow_rounded;
  static const home = Icons.home_rounded;
  static const map = Icons.map_outlined;
  static const redacao = Icons.edit_outlined;
  static const eventos = Icons.emoji_events_outlined;
  static const passaporte = Icons.menu_book_rounded;
  static const pin = Icons.place;
  static const chevron = Icons.chevron_right_rounded;
  static const check = Icons.check_rounded;
  static const lock = Icons.lock_outline_rounded;
  static const meta = Icons.adjust; // alvo concêntrico = meta
  static const perfil = Icons.person_outline_rounded;
  static const praticar = Icons.play_circle_outline_rounded;
}
