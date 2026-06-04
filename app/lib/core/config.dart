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
}
