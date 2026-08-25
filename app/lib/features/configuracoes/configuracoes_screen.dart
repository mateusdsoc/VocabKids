import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../identidade/auth_controller.dart';
import '../identidade/models.dart';
import '../identidade/widgets/passport_background.dart';
import 'preferencias.dart';
import 'preferencias_controller.dart';
import 'widgets/setting_tile.dart';
import 'widgets/settings_section.dart';
import 'widgets/tema_selector.dart';

/// Versão exibida em "Sobre" — espelha o `version:` do pubspec.
const _kVersaoApp = '1.0.0';

/// Configurações do app — alcançada a partir do Perfil. Reúne, na linguagem de
/// "folha de dados" do passaporte, as preferências locais do aparelho
/// (aparência, som/tato, lembretes) e os atalhos de conta/sobre.
///
/// Cliente fino: observa [preferenciasControllerProvider] e despacha mutações;
/// a persistência e a troca de tema ao vivo ficam por conta do controller.
class ConfiguracoesScreen extends ConsumerWidget {
  const ConfiguracoesScreen({super.key, required this.me});

  final Me me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final prefs = ref.watch(preferenciasControllerProvider).value ??
        const Preferencias();
    final ctrl = ref.read(preferenciasControllerProvider.notifier);
    final perfil = me.perfil;

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    Future<void> sair() async {
      await ref.read(authControllerProvider.notifier).sair();
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: PassportBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 8, 17, 10),
                  child: _Header(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(17, 6, 17, 28),
                    children: [
                      const _Eyebrow('APARÊNCIA'),
                      TemaSelector(
                        value: prefs.tema,
                        onChanged: ctrl.definirTema,
                      ),
                      const SizedBox(height: 22),
                      SettingsSection(
                        label: 'SOM & TATO',
                        children: [
                          SettingSwitchTile(
                            icon: AppIcons.speaker,
                            title: 'Efeitos sonoros',
                            subtitle: 'Sons de acerto e recompensa',
                            value: prefs.som,
                            onChanged: ctrl.definirSom,
                          ),
                          SettingSwitchTile(
                            icon: AppIcons.vibrar,
                            title: 'Vibração',
                            subtitle: 'Retorno tátil nos toques',
                            value: prefs.vibracao,
                            onChanged: ctrl.definirVibracao,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SettingsSection(
                        label: 'LEMBRETES',
                        children: [
                          SettingSwitchTile(
                            icon: AppIcons.sino,
                            title: 'Lembrete de prática',
                            subtitle: 'Um empurrãozinho diário',
                            accent: c.goal,
                            value: prefs.lembretes,
                            onChanged: ctrl.definirLembretes,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SettingsSection(
                        label: 'CONTA',
                        children: [
                          SettingTile(
                            icon: AppIcons.cake,
                            title: 'Faixa etária',
                            accent: c.accentStrong,
                            trailing: Text(
                              perfil == null ? '—' : '${perfil.faixaEtaria} anos',
                              style: AppType.nunito(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: c.muted),
                            ),
                          ),
                          SettingTile(
                            icon: AppIcons.signout,
                            title: 'Trocar de perfil / sair',
                            accent: c.warn,
                            trailing: Icon(AppIcons.chevron,
                                size: 20, color: c.muted),
                            onTap: sair,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SettingsSection(
                        label: 'SOBRE',
                        children: [
                          SettingTile(
                            icon: AppIcons.info,
                            title: 'Versão',
                            trailing: Text(
                              _kVersaoApp,
                              style: AppType.mono(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: c.muted),
                            ),
                          ),
                          SettingTile(
                            icon: AppIcons.privacidade,
                            title: 'Privacidade',
                            trailing: Icon(AppIcons.chevron,
                                size: 20, color: c.muted),
                            onTap: () => _emBreve(context),
                          ),
                        ],
                      ),
                    ],
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

void _emBreve(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Privacidade — em breve')));
}

/// Rótulo micro de seção (mesmo eyebrow mono do passaporte), usado solto antes
/// de elementos que não são um card de linhas (ex.: o seletor de tema).
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Text(
        text,
        style: AppType.mono(
            size: 9.5,
            weight: FontWeight.w700,
            letterSpacing: 1.4,
            color: c.muted),
      ),
    );
  }
}

/// Topo: voltar (botão de vidro) + título "Configurações" centralizado.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: c.glass,
              shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBack,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(AppIcons.back, size: 24, color: c.ink),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.ajustes, size: 18, color: c.accentStrong),
              const SizedBox(width: 8),
              Text('Configurações',
                  style: AppType.fredoka(size: 19, color: c.ink)),
            ],
          ),
        ],
      ),
    );
  }
}
