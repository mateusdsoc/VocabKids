import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import 'auth_controller.dart';
import 'models.dart';
import 'widgets/identity_card.dart';
import 'widgets/passport_background.dart';
import 'widgets/stat_tile.dart';

/// Perfil/progresso do aluno apresentado como a **página do Passaporte**:
/// identidade (avatar, nome, papel, escola, turma) + o progresso em
/// cartões-estatística. Quando [me] vem `null` (preview/demo), cai no
/// [sampleMe] — mesmo padrão de dado-amostra das outras telas.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key, this.me});

  final Me? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final me = this.me ?? sampleMe;
    final p = me.progresso;

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    Future<void> sair() async {
      await ref.read(authControllerProvider.notifier).sair();
      if (context.mounted) Navigator.of(context).maybePop();
    }

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
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          IdentityCard(me: me),
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
                          Row(
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LogoutButton(onTap: sair),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Topo: voltar + selo "PASSAPORTE" manuscrito centralizado.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

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
              Icon(AppIcons.passaporte, size: 18, color: c.accentStrong),
              const SizedBox(width: 7),
              Text('Passaporte',
                  style: AppType.caveat(size: 23, color: c.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão circular de vidro (voltar).
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
          child: Icon(icon, size: 24, color: c.ink),
        ),
      ),
    );
  }
}

/// Sair da conta — botão de contorno discreto (ação rara, não compete com nada).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
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
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.line, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.signout, size: 18, color: c.muted),
              const SizedBox(width: 9),
              Text('Sair da conta',
                  style: AppType.fredoka(
                      size: 15.5, weight: FontWeight.w500, color: c.muted)),
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
  nome: 'Manu Oliveira',
  papel: 'aluno',
  escola: Escola(id: 1, nome: 'EM Cecília Meireles'),
  turma: Turma(id: 1, nome: 'Turma 7A', anoEscolar: 7),
  progresso: Progresso(
    xpTotal: 3120,
    noAtualId: 4,
    palavrasDominadas: 48,
    nivelDificuldadeAtual: 3,
  ),
);
