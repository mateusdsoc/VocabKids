import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';
import 'preferencias.dart';

/// Fonte de verdade das [Preferencias] locais, persistidas em
/// `SharedPreferences`. Cliente fino do dispositivo: a UI observa e dispara
/// mutações; cada mutação troca o estado **e** grava no disco.
///
/// `AsyncNotifier` porque a leitura inicial do disco é assíncrona; enquanto
/// carrega, o app cai no default sensato ([AppConfig.themeMode]).
class PreferenciasController extends AsyncNotifier<Preferencias> {
  static const _kTema = 'pref_tema';
  static const _kSom = 'pref_som';
  static const _kVibracao = 'pref_vibracao';
  static const _kLembretes = 'pref_lembretes';

  @override
  Future<Preferencias> build() async {
    final prefs = await SharedPreferences.getInstance();
    return Preferencias(
      // Sem valor salvo, herda o default de compilação (--dart-define=THEME).
      tema: prefs.containsKey(_kTema)
          ? TemaPref.fromName(prefs.getString(_kTema))
          : _temaDoConfig(),
      som: prefs.getBool(_kSom) ?? true,
      vibracao: prefs.getBool(_kVibracao) ?? true,
      lembretes: prefs.getBool(_kLembretes) ?? false,
    );
  }

  /// Aplica a mudança no estado na hora (UI responde já) e persiste em seguida.
  Future<void> _aplicar(Preferencias p) async {
    state = AsyncData(p);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTema, p.tema.name);
    await prefs.setBool(_kSom, p.som);
    await prefs.setBool(_kVibracao, p.vibracao);
    await prefs.setBool(_kLembretes, p.lembretes);
  }

  Preferencias get _atual => state.value ?? const Preferencias();

  void definirTema(TemaPref tema) => _aplicar(_atual.copyWith(tema: tema));
  void definirSom(bool v) => _aplicar(_atual.copyWith(som: v));
  void definirVibracao(bool v) => _aplicar(_atual.copyWith(vibracao: v));
  void definirLembretes(bool v) => _aplicar(_atual.copyWith(lembretes: v));

  static TemaPref _temaDoConfig() => switch (AppConfig.themeMode.name) {
        'light' => TemaPref.claro,
        'dark' => TemaPref.escuro,
        _ => TemaPref.sistema,
      };
}

final preferenciasControllerProvider =
    AsyncNotifierProvider<PreferenciasController, Preferencias>(
        PreferenciasController.new);
