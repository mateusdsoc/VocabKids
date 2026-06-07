import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/theme/app_dimens.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/identidade/auth_controller.dart';
import 'features/identidade/entrada_screen.dart';

void main() {
  runApp(const ProviderScope(child: VocabKidsApp()));
}

class VocabKidsApp extends StatelessWidget {
  const VocabKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocabBR Kids',
      debugShowCheckedModeBanner: false,
      // Tema da marca: claro "Azul Brilhante", escuro "Capa do Passaporte".
      // A escolha segue o sistema; a mesma árvore renderiza nos dois.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppConfig.themeMode,
      themeAnimationDuration: AppDurations.themeSwitch,
      home: const _Gate(),
    );
  }
}

/// Roteamento por estado de autenticação (cliente fino):
/// carregando → splash; logado → perfil; deslogado → entrada.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.demo) return const HomeScreen();

    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const EntradaScreen(),
      data: (me) => me == null ? const EntradaScreen() : const HomeScreen(),
    );
  }
}
