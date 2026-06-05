/// Erro vindo da API no formato único do backend (errors.py / Bloco 3, decisão #5):
///
///     { "error": { "code": <snake_case>, "message": <legível>, "details": {} } }
///
/// O app ramifica pelo [code]; [message] é legível e pode ir direto à UI.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  /// Constrói a partir do corpo `{ "error": {...} }`. Se o corpo não bater com
  /// o formato esperado, cai num erro genérico carregando o status.
  factory ApiException.fromBody(int statusCode, Map<String, dynamic>? body) {
    final err = body?['error'];
    if (err is Map) {
      return ApiException(
        statusCode: statusCode,
        code: (err['code'] ?? 'erro').toString(),
        message: (err['message'] ?? 'Erro inesperado.').toString(),
        details: (err['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
    }
    return ApiException(
      statusCode: statusCode,
      code: 'erro',
      message: 'Erro inesperado (HTTP $statusCode).',
    );
  }

  /// Falha de rede/conexão (não chegou a haver resposta da API).
  factory ApiException.network(Object cause) => ApiException(
        statusCode: 0,
        code: 'sem_conexao',
        message: 'Não foi possível conectar ao servidor.',
        details: {'cause': cause.toString()},
      );

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
