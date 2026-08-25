import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../configuracoes/configuracoes_screen.dart';
import '../passaporte/passaporte_screen.dart';
import 'auth_controller.dart';
import 'models.dart';
import 'widgets/identity_card.dart';
import 'widgets/passport_background.dart';
import 'widgets/stat_tile.dart';

/// **Perfil do aluno** — a tela "quem sou eu": identidade (avatar, nome, papel,
/// faixa etária, ano escolar) + progresso em cartões-estatística, com um atalho para o
/// **Passaporte** (a coleção) no topo e a entrada de **Configurações** ao pé.
///
/// Perfil e Passaporte são telas distintas (produto §3.10): o Perfil é o espaço
/// de identidade/gerência; o Passaporte é o espaço de coleção/celebração. Lê o
/// [Me] real do [authControllerProvider]; em preview/demo cai no [sampleMe].
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key, this.me});

  final Me? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final me =
        this.me ?? ref.watch(authControllerProvider).value?.meOuNull ?? sampleMe;
    final p = me.progresso;

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    void abrirPassaporte() => Navigator.of(context).push(
          adaptivePageRoute(builder: (_) => const PassaporteScreen()),
        );

    void abrirConfiguracoes() => Navigator.of(context).push(
          adaptivePageRoute(builder: (_) => ConfiguracoesScreen(me: me)),
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: PassportBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
              child: Column(
                children: [
                  _Header(
                    onBack: () => Navigator.of(context).maybePop(),
                    onConfiguracoes: abrirConfiguracoes,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          IdentityCard(me: me),
                          const SizedBox(height: 14),
                          _PassaporteAtalho(onTap: abrirPassaporte),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text('PROGRESSO',
                                style: AppType.mono(
                                    size: 9.5,
                                    weight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: c.muted)),
                          ),
                          const SizedBox(height: 9),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: StatTile(
                                    label: 'XP total',
                                    value: milhar(p.xpTotal),
                                    icon: AppIcons.star,
                                    accent: c.xp,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: StatTile(
                                    label: 'Palavras',
                                    value: '${p.palavrasDominadas}',
                                    icon: AppIcons.palavras,
                                    accent: c.goal,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: StatTile(
                                    label: 'Nível',
                                    value: '${p.nivelDificuldadeAtual}',
                                    icon: AppIcons.meta,
                                    accent: c.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Topo: voltar + título "Perfil" centralizado + a **engrenagem** de
/// Configurações à direita. O atalho ao Passaporte (a coleção) vive no corpo,
/// logo abaixo da carteira de identidade (não duplicamos no topo).
class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onConfiguracoes});
  final VoidCallback onBack;
  final VoidCallback onConfiguracoes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _RoundButton(icon: AppIcons.back, onTap: onBack),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.perfil, size: 18, color: c.accentStrong),
              const SizedBox(width: 7),
              Text('Perfil', style: AppType.fredoka(size: 19, color: c.ink)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _RoundButton(
              icon: AppIcons.ajustes,
              onTap: onConfiguracoes,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão circular de vidro (voltar / abrir configurações).
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.glass,
      shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 23, color: c.ink),
        ),
      ),
    );
  }
}

/// Atalho destacado para o Passaporte (a coleção) — convite caloroso, na cor
/// dourada da marca, logo abaixo da carteira de identidade.
class _PassaporteAtalho extends StatelessWidget {
  const _PassaporteAtalho({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(16);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: c.accent.withValues(alpha: 0.12),
            border: Border.all(
                color: c.accentStrong.withValues(alpha: 0.30), width: 1),
          ),
          child: Row(
            children: [
              Icon(AppIcons.passaporte, size: 20, color: c.accentStrong),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Meu passaporte',
                        style: AppType.nunito(
                            size: 15,
                            weight: FontWeight.w800,
                            color: c.ink)),
                    const SizedBox(height: 1),
                    Text('Carimbos, postais e selos da viagem',
                        style: AppType.nunito(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: c.muted)),
                  ],
                ),
              ),
              Icon(AppIcons.chevron, size: 20, color: c.accentStrong),
            ],
          ),
        ),
      ),
    );
  }
}

/// Viajante-amostra para preview/demo (mesmo padrão de `sample` das outras telas).
final Me sampleMe = Me(
  usuarioId: 1,
  nome: 'Manu',
  papel: 'aluno',
  perfil: PerfilCrianca(
    usuarioId: 1,
    apelido: 'Manu',
    faixaEtaria: '9-10',
    anoEscolar: 5,
  ),
  progresso: Progresso(
    xpTotal: 3120,
    noAtualId: 4,
    palavrasDominadas: 48,
    nivelDificuldadeAtual: 3,
  ),
  metaSemanal: MetaSemanal(atual: 6, alvo: 10),
);
