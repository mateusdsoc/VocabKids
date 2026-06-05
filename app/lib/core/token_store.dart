import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o token de acesso provisório da fatia A (`prov_<usuario_id>`).
///
/// Provisório de propósito: sem assinatura/expiração (ver backend
/// `identidade/auth.py`). Quando a auth real entrar (janela Out–Jan), só esta
/// classe muda — o resto do app fala com ela, não com o formato do token.
class TokenStore {
  static const _key = 'auth_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
