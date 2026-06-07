import 'package:flutter/material.dart' show ThemeMode;

/// Configuração de ambiente do app.
///
/// A base da API vem de `--dart-define=API_BASE_URL=...` (interface estável,
/// provider variável — seção 12 do produto). O default aponta para o backend
/// local; emulador Android usa 10.0.2.2 para alcançar o host.
class AppConfig {
  /// URL base da API, **sem** o sufixo `/v1` (que é adicionado pelo cliente).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Modo demo: `--dart-define=DEMO=true` pula o auth e carrega dados sample
  /// em todas as telas — útil para validar o design sem backend.
  static const bool demo = bool.fromEnvironment('DEMO');

  /// Tema forçado: `--dart-define=THEME=dark` ou `=light`.
  /// Sem o flag, segue o sistema (`ThemeMode.system`).
  static const String _theme = String.fromEnvironment('THEME');
  static ThemeMode get themeMode => switch (_theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
}
