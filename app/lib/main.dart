import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      themeMode: ThemeMode.system,
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
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // Erro na restauração inicial não deve travar o app: vai para a entrada.
      error: (_, _) => const EntradaScreen(),
      data: (me) => me == null ? const EntradaScreen() : const HomeScreen(),
    );
  }
}
