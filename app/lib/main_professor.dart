import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/professor/professor_app.dart';

/// Entrypoint da **superfície do professor** (web).
///
/// Projeto único, build separado:
/// `flutter run -d chrome -t lib/main_professor.dart --dart-define=DEMO=true`.
///
/// Este arquivo (e a árvore `features/professor/`) é o **único** ponto que
/// alcança o código do professor. `lib/main.dart` (aluno) nunca o importa, então
/// o tree-shaking do compilador Dart o remove por completo do APK/IPA do aluno —
/// garantia coberta pelo teste `test/arquitetura_professor_test.dart`.
void main() {
  runApp(const ProviderScope(child: ProfessorApp()));
}
