import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_icons.dart';
import 'screens/painel_screen.dart';
import 'widgets/professor_shell.dart';

/// Raiz da superfície do professor. Reusa o tema da marca (`AppTheme`), mas
/// **padrão claro** — é uma ferramenta de tela grande (laptop/projetor). O
/// `--dart-define=THEME=dark` ainda força o escuro para conferência visual.
class ProfessorApp extends StatelessWidget {
  const ProfessorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = AppConfig.themeMode == ThemeMode.system
        ? ThemeMode.light
        : AppConfig.themeMode;
    return MaterialApp(
      title: 'VocabBR Kids — Professor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      // pt-BR nos widgets do Material (showDatePicker de "Atribuir redação").
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _ProfessorHome(),
    );
  }
}

/// Casca com navegação lateral; troca a tela ativa pelo índice selecionado.
/// Por ora só o Painel está implementado (fases seguintes ligam as demais).
class _ProfessorHome extends StatefulWidget {
  const _ProfessorHome();

  @override
  State<_ProfessorHome> createState() => _ProfessorHomeState();
}

class _ProfessorHomeState extends State<_ProfessorHome> {
  int _index = 0;

  static const _destinations = [
    ProfessorNavItem(icon: AppIcons.home, label: 'Painel'),
    ProfessorNavItem(icon: AppIcons.redacao, label: 'Redações'),
    ProfessorNavItem(icon: AppIcons.ajustes, label: 'Configurações'),
  ];

  @override
  Widget build(BuildContext context) {
    return ProfessorShell(
      destinations: _destinations,
      currentIndex: _index,
      onSelect: (i) => setState(() => _index = i),
      body: switch (_index) {
        0 => const PainelScreen(),
        _ => EmBreveProfessor(titulo: _destinations[_index].label),
      },
    );
  }
}
