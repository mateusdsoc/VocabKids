import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart' show ThemeMode;

/// Configuração de ambiente do app.
///
/// A base da API vem de `--dart-define=API_BASE_URL=...` (interface estável,
/// provider variável — seção 12 do produto). O default aponta para o backend
/// local na máquina do dev.
class AppConfig {
  /// URL base da API, **sem** o sufixo `/v1` (que é adicionado pelo cliente).
  ///
  /// Default por plataforma: o emulador Android só alcança o host da máquina
  /// via o alias `10.0.2.2`; simulador iOS, desktop e web falam `localhost`
  /// direto.
  static const String _apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) return _apiBaseUrlDefine;
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return android ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
  }

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
