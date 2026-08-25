import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import 'auth_controller.dart';
import 'widgets/brand_mark.dart';
import 'widgets/passport_background.dart';
import 'widgets/passport_field.dart';
import 'widgets/perforation.dart';

/// Cria o perfil de uma criança na conta do responsável e já entra nele
/// (B2C, docs/plano_b2c.md Fase 1). Coleta o mínimo necessário — apelido e
/// ano de nascimento — nunca o nome completo (R-ID-7, minimização de dados).
class CriarCriancaScreen extends ConsumerStatefulWidget {
  const CriarCriancaScreen({super.key});

  @override
  ConsumerState<CriarCriancaScreen> createState() => _CriarCriancaScreenState();
}

class _CriarCriancaScreenState extends ConsumerState<CriarCriancaScreen> {
  final _apelido = TextEditingController();
  final _anoNascimento = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static final _anoMinimo = DateTime.now().year - 14;
  static final _anoMaximo = DateTime.now().year - 5;

  @override
  void dispose() {
    _apelido.dispose();
    _anoNascimento.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).criarPerfilEEntrar(
          apelido: _apelido.text.trim(),
          anoNascimento: int.parse(_anoNascimento.text.trim()),
        );
    // Esta tela é ou a raiz mostrada pelo `_Gate` (1º perfil, nada para
    // desempilhar) ou foi empilhada a partir do Seletor ("Adicionar
    // criança") — só desempilha quando há o quê, e só em caso de sucesso.
    if (mounted &&
        !ref.read(authControllerProvider).hasError &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Não consegui criar o perfil. Confira os dados e a conexão.',
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
                  child: _Header(onBack: () => Navigator.of(context).maybePop()),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const BrandMark(),
                              const SizedBox(height: 22),
                              _CriancaCard(
                                apelido: _apelido,
                                anoNascimento: _anoNascimento,
                                anoMinimo: _anoMinimo,
                                anoMaximo: _anoMaximo,
                                onSubmit: _criar,
                              ),
                              const SizedBox(height: 18),
                              PrimaryButton(
                                label: carregando ? 'Criando…' : 'Começar a viagem',
                                leadingIcon: AppIcons.flight,
                                onTap: carregando ? null : _criar,
                              ),
                            ],
                          ),
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
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: Align(
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
              child: Icon(AppIcons.back, size: 23, color: c.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _CriancaCard extends StatelessWidget {
  const _CriancaCard({
    required this.apelido,
    required this.anoNascimento,
    required this.anoMinimo,
    required this.anoMaximo,
    required this.onSubmit,
  });

  final TextEditingController apelido;
  final TextEditingController anoNascimento;
  final int anoMinimo;
  final int anoMaximo;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NOVO VIAJANTE',
                  style: AppType.mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: c.muted)),
              Icon(AppIcons.perfil, size: 17, color: c.accentStrong),
            ],
          ),
          const SizedBox(height: 14),
          const Perforation(),
          const SizedBox(height: 16),
          PassportField(
            controller: apelido,
            label: 'Apelido da criança',
            icon: AppIcons.signature,
            hint: 'Como ela gosta de ser chamada?',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofocus: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Escolha um apelido' : null,
          ),
          const SizedBox(height: 16),
          PassportField(
            controller: anoNascimento,
            label: 'Ano de nascimento',
            icon: AppIcons.cake,
            hint: 'ex.: 2017',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => onSubmit(),
            validator: (v) {
              final ano = int.tryParse((v ?? '').trim());
              if (ano == null) return 'Informe o ano de nascimento';
              if (ano < anoMinimo || ano > anoMaximo) {
                return 'Digite um ano entre $anoMinimo e $anoMaximo';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
