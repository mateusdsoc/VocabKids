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

  // --- Sessão ---
  static const close = Icons.close_rounded;
  static const report = Icons.outlined_flag_rounded;
  static const speaker = Icons.volume_up_rounded;
  static const combo = Icons.auto_awesome; // faísca do combo
  static const quote = Icons.format_quote_rounded;
  static const novaPalavra = Icons.auto_stories_rounded;
  static const retry = Icons.refresh_rounded; // "rever": questão volta à fila
  static const wrong = Icons.close_rounded; // "X" da alternativa errada
  static const arrow = Icons.arrow_forward_rounded;

  // --- Resumo de sessão ---
  static const up = Icons.arrow_upward_rounded; // palavra subiu de nível
  static const star = Icons.star_rounded; // carimbo do colecionável

  // --- Identidade (Embarque / Passaporte) ---
  static const globe = Icons.public; // mundo no carimbo da marca
  static const flight = Icons.flight_takeoff_rounded; // embarcar
  static const ticket = Icons.confirmation_number_outlined; // código da turma
  static const signature = Icons.edit_outlined; // nome do viajante
  static const signout = Icons.logout_rounded;
  static const school = Icons.school_outlined;
  static const back = Icons.chevron_left_rounded;
  static const palavras = Icons.menu_book_outlined; // palavras dominadas

  // --- Perfil / Configurações ---
  static const ajustes = Icons.tune_rounded; // entrada de configurações
  static const temaSistema = Icons.brightness_auto_rounded;
  static const temaClaro = Icons.light_mode_rounded;
  static const temaEscuro = Icons.dark_mode_rounded;
  static const aparencia = Icons.palette_outlined;
  static const vibrar = Icons.vibration_rounded;
  static const sino = Icons.notifications_none_rounded;
  static const info = Icons.info_outline_rounded;
  static const privacidade = Icons.shield_outlined;

  // --- Redação ---
  static const camera = Icons.photo_camera_rounded;
  static const gallery = Icons.photo_library_outlined;
  static const pdf = Icons.picture_as_pdf_outlined;
  static const add = Icons.add_rounded;
  static const trash = Icons.delete_outline_rounded;
  static const sent = Icons.send_rounded;
  static const clock = Icons.schedule_rounded; // aguardando análise
}
