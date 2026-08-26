import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/surface_card.dart';
import '../assinatura/paywall_screen.dart';
import '../responsavel/pin_gate_screen.dart';
import 'auth_controller.dart';
import 'criar_crianca_screen.dart';
import 'models.dart';
import 'widgets/brand_mark.dart';
import 'widgets/passport_background.dart';

const _kMaximoPerfis = 3; // espelha LIMITE_PERFIS_POR_CONTA no backend

/// "Quem vai estudar hoje?" — seleção de perfil de criança dentro da conta do
/// responsável (B2C, docs/plano_b2c.md Fase 1). Cada cartão é um filho; tocar
/// troca o token de responsável pelo token de gameplay daquele perfil.
class SeletorPerfilScreen extends ConsumerWidget {
  const SeletorPerfilScreen({super.key, required this.perfis});

  final List<PerfilCrianca> perfis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final auth = ref.watch(authControllerProvider);
    final carregando = auth.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: c.warn,
              content: Text(
                'Não consegui abrir esse perfil. Tente de novo.',
                style: AppType.nunito(
                    size: 13.5, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          );
      }
    });

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: PassportBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
                  child: _Header(
                    onResponsavel: () => Navigator.of(context).push(
                      adaptivePageRoute(builder: (_) => const PinGateScreen()),
                    ),
                    onAssinatura: () => Navigator.of(context).push(
                      adaptivePageRoute(builder: (_) => const PaywallScreen()),
                    ),
                    onSair: () =>
                        ref.read(authControllerProvider.notifier).sair(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BrandMark(),
                            const SizedBox(height: 8),
                            Text(
                              'Quem vai viajar hoje?',
                              textAlign: TextAlign.center,
                              style: AppType.fredoka(size: 21, color: c.ink),
                            ),
                            const SizedBox(height: 22),
                            for (final perfil in perfis) ...[
                              _PerfilCard(
                                perfil: perfil,
                                disabled: carregando,
                                onTap: () => ref
                                    .read(authControllerProvider.notifier)
                                    .entrarComoCrianca(perfil.usuarioId),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (perfis.length < _kMaximoPerfis)
                              _NovoPerfilCard(
                                disabled: carregando,
                                onTap: () => Navigator.of(context).push(
                                  adaptivePageRoute(
                                    builder: (_) => const CriarCriancaScreen(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onResponsavel,
    required this.onAssinatura,
    required this.onSair,
  });
  final VoidCallback onResponsavel;
  final VoidCallback onAssinatura;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget botao(IconData icon, VoidCallback onTap) => Material(
          color: c.glass,
          shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: c.ink),
            ),
          ),
        );
    return SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            botao(AppIcons.familia, onResponsavel),
            const SizedBox(width: 10),
            botao(AppIcons.passaporte, onAssinatura),
            const SizedBox(width: 10),
            botao(AppIcons.signout, onSair),
          ],
        ),
      ),
    );
  }
}

class _PerfilCard extends StatelessWidget {
  const _PerfilCard({
    required this.perfil,
    required this.disabled,
    required this.onTap,
  });

  final PerfilCrianca perfil;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: c.avatarGradient,
                    ),
                  ),
                  child: Text(_inicial(perfil.apelido),
                      style: AppType.fredoka(size: 22, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(perfil.apelido,
                          style: AppType.nunito(
                              size: 16, weight: FontWeight.w800, color: c.ink)),
                      const SizedBox(height: 2),
                      Text('${perfil.faixaEtaria} anos',
                          style: AppType.nunito(
                              size: 12.5, weight: FontWeight.w700, color: c.muted)),
                    ],
                  ),
                ),
                Icon(AppIcons.chevron, size: 22, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _inicial(String nome) {
    final t = nome.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }
}

class _NovoPerfilCard extends StatelessWidget {
  const _NovoPerfilCard({required this.disabled, required this.onTap});
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(16);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
                color: c.line, width: 1.4, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.add, size: 20, color: c.primary),
              const SizedBox(width: 8),
              Text('Adicionar criança',
                  style: AppType.nunito(
                      size: 14.5, weight: FontWeight.w800, color: c.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
