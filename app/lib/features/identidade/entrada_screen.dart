import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../onboarding/onboarding_screen.dart';
import 'auth_controller.dart';
import 'widgets/brand_mark.dart';
import 'widgets/passport_background.dart';
import 'widgets/passport_field.dart';
import 'widgets/perforation.dart';

/// Tela de entrada por código de turma — o **embarque** da jornada.
///
/// O fluxo de dados (acesso por turma) é o mesmo de sempre; o que mudou é a
/// roupa: agora é um *passe de embarque* dentro da metáfora de viagem do app
/// (carimbo da marca, bilhete picotado, "Embarcar"), nos tokens de [AppColors]
/// — claro "Azul Brilhante", escuro "Capa do Passaporte".
class EntradaScreen extends ConsumerStatefulWidget {
  const EntradaScreen({super.key});

  @override
  ConsumerState<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends ConsumerState<EntradaScreen> {
  final _codigo = TextEditingController();
  final _nome = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    // Demo: pula o backend e segue para o onboarding com o nome digitado.
    if (AppConfig.demo) {
      Navigator.of(context).push(
        adaptivePageRoute(
          builder: (_) => OnboardingScreen(nome: _nome.text.trim()),
        ),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).entrar(
          codigoTurma: _codigo.text.trim(),
          nome: _nome.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = ref.watch(authControllerProvider);
    final carregando = auth.isLoading;

    // Erro de acesso (código inexistente, sem conexão, etc.) — âmbar gentil.
    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: c.warn,
              content: Text(
                'Não consegui embarcar. Confira o código e a conexão.',
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BrandMark(),
                        const SizedBox(height: 26),
                        _BoardingCard(codigo: _codigo, nome: _nome, onSubmit: _entrar),
                        const SizedBox(height: 18),
                        _BoardingButton(loading: carregando, onTap: _entrar),
                        const SizedBox(height: 14),
                        Text(
                          'Peça o código da turma ao seu professor.',
                          textAlign: TextAlign.center,
                          style: AppType.nunito(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O "passe de embarque": cabeçalho picotado + os dois campos.
class _BoardingCard extends StatelessWidget {
  const _BoardingCard({
    required this.codigo,
    required this.nome,
    required this.onSubmit,
  });

  final TextEditingController codigo;
  final TextEditingController nome;
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
              Text('PASSE DE EMBARQUE',
                  style: AppType.mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: c.muted)),
              Icon(AppIcons.flight, size: 17, color: c.accentStrong),
            ],
          ),
          const SizedBox(height: 14),
          const Perforation(),
          const SizedBox(height: 16),
          PassportField(
            controller: codigo,
            label: 'Código da turma',
            icon: AppIcons.ticket,
            hint: 'ex.: DEMO7A',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
          ),
          const SizedBox(height: 16),
          PassportField(
            controller: nome,
            label: 'Seu apelido',
            icon: AppIcons.signature,
            hint: 'Como quer ser chamado?',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => onSubmit(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Escolha um apelido' : null,
          ),
        ],
      ),
    );
  }
}

/// Botão de embarque: o [PrimaryButton] da marca, ou um bloco com spinner
/// enquanto valida o acesso.
class _BoardingButton extends StatelessWidget {
  const _BoardingButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!loading) {
      return PrimaryButton(
        label: 'Embarcar',
        leadingIcon: AppIcons.flight,
        onTap: onTap,
      );
    }
    final radius = BorderRadius.circular(16);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 11),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(c.onPrimary),
            ),
          ),
          const SizedBox(width: 11),
          Text('Embarcando…',
              style: AppType.fredoka(
                  size: 17, weight: FontWeight.w500, color: c.onPrimary)),
        ],
      ),
    );
  }
}
