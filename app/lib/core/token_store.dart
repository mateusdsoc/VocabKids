import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o token de sessão (JWT) no armazenamento seguro do dispositivo
/// (keychain no iOS/macOS, keystore no Android, WebCrypto na web).
///
/// O formato do token é opaco para o app (cliente fino): quem valida é o
/// backend. Só esta classe conhece onde o token vive — o resto do app fala
/// com ela via provider (`tokenStoreProvider`).
class TokenStore {
  static const _key = 'auth_token';
  static const _storage = FlutterSecureStorage();

  Future<String?> read() async {
    await _limparLegado();
    return _storage.read(key: _key);
  }

  Future<void> save(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);

  /// O token já morou em SharedPreferences (era o `prov_*` da fatia A, hoje
  /// inválido no backend). Remove o resíduo — não migra: o formato antigo não
  /// passa na validação do JWT, então o app pediria novo acesso de todo jeito.
  Future<void> _limparLegado() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_key)) await prefs.remove(_key);
  }
}
