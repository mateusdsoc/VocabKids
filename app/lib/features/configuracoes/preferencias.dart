import 'package:flutter/material.dart' show ThemeMode;

/// Preferência de aparência escolhida pelo usuário (vira [ThemeMode]).
enum TemaPref {
  sistema,
  claro,
  escuro;

  ThemeMode get themeMode => switch (this) {
        TemaPref.sistema => ThemeMode.system,
        TemaPref.claro => ThemeMode.light,
        TemaPref.escuro => ThemeMode.dark,
      };

  static TemaPref fromName(String? name) =>
      TemaPref.values.where((t) => t.name == name).firstOrNull ??
      TemaPref.sistema;
}

/// Preferências locais do app — puramente do dispositivo (não vêm do servidor):
/// aparência, som/tato e lembretes de prática. Imutável; o controller troca a
/// instância inteira a cada ajuste e persiste em `SharedPreferences`.
class Preferencias {
  const Preferencias({
    this.tema = TemaPref.sistema,
    this.som = true,
    this.vibracao = true,
    this.lembretes = false,
  });

  /// Aparência (claro/escuro/sistema).
  final TemaPref tema;

  /// Efeitos sonoros da sessão.
  final bool som;

  /// Retorno tátil (haptics) em toques e acertos.
  final bool vibracao;

  /// Lembrete diário de prática (notificação local — plumbing futuro).
  final bool lembretes;

  Preferencias copyWith({
    TemaPref? tema,
    bool? som,
    bool? vibracao,
    bool? lembretes,
  }) =>
      Preferencias(
        tema: tema ?? this.tema,
        som: som ?? this.som,
        vibracao: vibracao ?? this.vibracao,
        lembretes: lembretes ?? this.lembretes,
      );
}
