import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/theme/app_dimens.dart';
import 'core/theme/app_theme.dart';
import 'features/configuracoes/preferencias_controller.dart';
import 'features/home/home_screen.dart';
import 'features/identidade/auth_controller.dart';
import 'features/identidade/criar_crianca_screen.dart';
import 'features/identidade/entrada_screen.dart';
import 'features/identidade/seletor_perfil_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: VocabKidsApp()));
}

class VocabKidsApp extends ConsumerWidget {
  const VocabKidsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aparência escolhida pelo usuário (Configurações), persistida no aparelho.
    // Enquanto a preferência carrega do disco, cai no default de compilação.
    final themeMode = ref.watch(preferenciasControllerProvider).maybeWhen(
          data: (p) => p.tema.themeMode,
          orElse: () => AppConfig.themeMode,
        );
    return MaterialApp(
      title: 'VocabBR Kids',
      debugShowCheckedModeBanner: false,
      // Tema da marca: claro "Azul Brilhante", escuro "Capa do Passaporte".
      // A mesma árvore renderiza nos dois; a escolha vem das preferências.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: AppDurations.themeSwitch,
      // pt-BR nos widgets do Material (datepicker, tooltips, semântica).
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Gate(),
    );
  }
}

/// Roteamento por estado de sessão (cliente fino, B2C — docs/plano_b2c.md
/// Fase 1): carregando → splash; deslogado → entrada; token de responsável
/// sem perfil escolhido → seletor de perfil (ou criar o 1º); perfil recém-
/// criado → onboarding (com o diagnóstico real); perfil ativo → Home.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Demo: começa no embarque para contar a história desde o início
    // (Entrada → Onboarding → Home), tudo com dados de exemplo.
    if (AppConfig.demo) return const EntradaScreen();

    final auth = ref.watch(authControllerProvider);
    final onboarding = ref.watch(onboardingPendenteProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const EntradaScreen(),
      data: (estado) => switch (estado) {
        Deslogado() => const EntradaScreen(),
        AguardandoPerfil(perfis: final perfis) => perfis.isEmpty
            ? const CriarCriancaScreen()
            : SeletorPerfilScreen(perfis: perfis),
        Autenticado(me: final me) => onboarding
            ? OnboardingScreen(nome: me.perfil?.apelido ?? me.nome)
            : const HomeScreen(),
      },
    );
  }
}
