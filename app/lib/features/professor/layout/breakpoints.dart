import 'package:flutter/widgets.dart';

/// Régua de layout da superfície web do professor. Centralizada para que o shell
/// e as telas usem os mesmos limites — e o app **degrade para uma coluna** em
/// janela estreita sem quebrar. ("Professor mobile" está deferido até validar com
/// as escolas; aqui só garantimos que abrir num navegador estreito não trave.)
abstract final class ProfessorLayout {
  /// Abaixo disso, a navegação lateral vira um menu (drawer) e o conteúdo ocupa
  /// toda a largura.
  static const double railBreakpoint = 900;

  /// Largura máxima da coluna de conteúdo (legibilidade em telas largas).
  static const double contentMaxWidth = 1120;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= railBreakpoint;
}
