import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/identidade/auth_controller.dart';
import 'features/identidade/entrada_screen.dart';
import 'features/identidade/me_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
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
      data: (me) => me == null ? const EntradaScreen() : MeScreen(me: me),
    );
  }
}
