import 'package:flutter/material.dart';

/// Paleta **decorativa** da Trilha (relevo/profundidade): valores que não cabem
/// nos tokens da marca ([AppColors]) — paredes de relevo, sombras de contato,
/// preenchimento "gravado" dos bloqueados, verdes do caminho, banhos de cor e
/// textura cartográfica.
///
/// Vem do design `Trilha (mapa)`: escuro = v5 (variação B · Capa do Passaporte),
/// claro = v4 (cor e textura). Os tokens-base (primary/accent/goal/ink/…) seguem
/// vindo de `context.colors`.
class TrilhaTones {
  const TrilhaTones({
    required this.primaryDeep,
    required this.contact,
    required this.contactStrong,
    required this.medalWall,
    required this.medalWallCur,
    required this.carveFill,
    required this.carveVeil,
    required this.engraveLight,
    required this.ghostInk,
    required this.gateFill,
    required this.gateWall,
    required this.gatePost,
    required this.frontierLine,
    required this.topo,
    required this.topo2,
    required this.pathGreen,
    required this.pathGreenDark,
    required this.pathGreenHi,
    required this.pathGroove,
    required this.pathGrooveDark,
    required this.pathGrooveHi,
    required this.washCool,
    required this.washWarm,
  });

  final Color primaryDeep;
  final Color contact;
  final Color contactStrong;
  final Color medalWall;
  final Color medalWallCur;
  final Color carveFill;
  final Color carveVeil;
  final Color engraveLight;
  final Color ghostInk;
  final Color gateFill;
  final Color gateWall;
  final Color gatePost;
  final Color frontierLine;
  final Color topo;
  final Color topo2;
  final Color pathGreen;
  final Color pathGreenDark;
  final Color pathGreenHi;
  final Color pathGroove;
  final Color pathGrooveDark;
  final Color pathGrooveHi;
  final Color washCool;
  final Color washWarm;

  static const dark = TrilhaTones(
    primaryDeep: Color(0xFF2F6F9E),
    contact: Color(0x80000000),
    contactStrong: Color(0x9E000000),
    medalWall: Color(0xFF13243C),
    medalWallCur: Color(0xFF0F1D31),
    carveFill: Color(0xFF1A2F4D),
    carveVeil: Color(0x8C000000),
    engraveLight: Color(0x1FFFFFFF),
    ghostInk: Color(0xFFB9CAE3),
    gateFill: Color(0xFF0F2138),
    gateWall: Color(0xFF0F1D31),
    gatePost: Color(0x14FFFFFF),
    frontierLine: Color(0x38FFFFFF),
    topo: Color(0x12FFFFFF),
    topo2: Color(0x2ED9C083),
    pathGreen: Color(0xFF3FB97E),
    pathGreenDark: Color(0xFF1E6B48),
    pathGreenHi: Color(0xFF9BE4C1),
    pathGroove: Color(0xFF1A3050),
    pathGrooveDark: Color(0xFF11233C),
    pathGrooveHi: Color(0x14FFFFFF),
    washCool: Color(0x335FA9E0),
    washWarm: Color(0x38D9C083),
  );

  static const light = TrilhaTones(
    primaryDeep: Color(0xFF145FA3),
    contact: Color(0x423C280F),
    contactStrong: Color(0x573C280F),
    medalWall: Color(0xFFCAA05A),
    medalWallCur: Color(0xFFCDB98F),
    carveFill: Color(0xFFE8DCC4),
    carveVeil: Color(0x665A401C),
    engraveLight: Color(0xB3FFFFFF),
    ghostInk: Color(0xFF7C6A4C),
    gateFill: Color(0xFF26415F),
    gateWall: Color(0xFFB79A6A),
    gatePost: Color(0x29FFFFFF),
    frontierLine: Color(0x52785A32),
    topo: Color(0x12785A32),
    topo2: Color(0x1C785A32),
    pathGreen: Color(0xFF16A971),
    pathGreenDark: Color(0xFF0C6E49),
    pathGreenHi: Color(0xFF7FE0B4),
    pathGroove: Color(0xFFDDD0B8),
    pathGrooveDark: Color(0xFFC9B896),
    pathGrooveHi: Color(0xB3FFFFFF),
    washCool: Color(0x241E7FD6),
    washWarm: Color(0x29E0962E),
  );

  static TrilhaTones of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
