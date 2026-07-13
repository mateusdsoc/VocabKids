import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'config.dart';
import 'token_store.dart';

/// Cliente HTTP fino sobre a API `/v1`.
///
/// Responsabilidades: prefixo de versão, JSON, injeção do Bearer token e
/// tradução de qualquer falha para [ApiException] (formato único do backend).
/// Nenhuma regra de domínio vive aqui — só transporte.
class ApiClient {
  ApiClient({TokenStore? tokenStore, http.Client? httpClient})
      : _tokens = tokenStore ?? TokenStore(),
        _http = httpClient ?? http.Client();

  final TokenStore _tokens;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}/v1$path');

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokens.read();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    return _send(() async => _http.get(_uri(path), headers: await _headers(auth: auth)));
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    return _send(() async => _http.post(
          _uri(path),
          headers: await _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    return _send(() async => _http.put(
          _uri(path),
          headers: await _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  /// Executa a requisição e normaliza o resultado: decodifica JSON no sucesso,
  /// lança [ApiException] em erro de API ou de rede.
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request();
    } catch (e) {
      throw ApiException.network(e);
    }

    final dynamic decoded;
    try {
      decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      // Corpo não-JSON (ex.: HTML de um 502 de proxy) — vira erro de API
      // legível em vez de uma FormatException crua na UI.
      throw ApiException(
        statusCode: res.statusCode,
        code: 'resposta_invalida',
        message: 'Resposta inesperada do servidor (HTTP ${res.statusCode}).',
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    throw ApiException.fromBody(
      res.statusCode,
      decoded is Map<String, dynamic> ? decoded : null,
    );
  }
}
