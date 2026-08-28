import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import 'auth_controller.dart';
import 'legal_texts.dart';
import 'widgets/brand_mark.dart';
import 'widgets/legal_text_screen.dart';
import 'widgets/passport_background.dart';
import 'widgets/passport_field.dart';
import 'widgets/perforation.dart';

/// Cadastro da conta do responsável (B2C, docs/plano_b2c.md Fase 1).
///
/// Consentimento LGPD (R-LG-1, art. 14 §1): o backend exige `aceite_termos`
/// e `consentimento_lgpd` como campos distintos — aqui são duas caixas de
/// marcação SEPARADAS, nenhuma pré-marcada, a de consentimento visualmente
/// destacada (não embutida no aceite genérico dos termos). O cadastro só
/// segue com as duas marcadas, e o valor real de cada uma (não um `true`
/// fixo) é o que vai pro backend — ver `repository.dart`.
class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _aceiteTermos = false;
  bool _consentimentoLgpd = false;
  bool _tentouSemAceite = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    final aceiteOk = _aceiteTermos && _consentimentoLgpd;
    if (!aceiteOk) setState(() => _tentouSemAceite = true);
    if (!formOk || !aceiteOk) return;
    await ref.read(authControllerProvider.notifier).cadastrar(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          senha: _senha.text,
          aceiteTermos: _aceiteTermos,
          consentimentoLgpd: _consentimentoLgpd,
        );
    // Esta tela foi empilhada (Navigator.push) sobre a Entrada — o `_Gate`
    // já trocou o que está por baixo ao mudar o estado, mas só desempilhar
    // revela isso. Sem erro = sucesso (AsyncValue.guard já tratou a falha).
    if (mounted && !ref.read(authControllerProvider).hasError) {
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
        final erro = next.error;
        final mensagem = erro.toString().contains('email_em_uso')
            ? 'Já existe uma conta com este e-mail.'
            : 'Não consegui criar a conta. Confira os dados e a conexão.';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: c.warn,
              content: Text(mensagem,
                  style: AppType.nunito(
                      size: 13.5, weight: FontWeight.w800, color: Colors.white)),
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
                              _CadastroCard(
                                nome: _nome,
                                email: _email,
                                senha: _senha,
                                aceiteTermos: _aceiteTermos,
                                consentimentoLgpd: _consentimentoLgpd,
                                erroAceite: _tentouSemAceite &&
                                    (!_aceiteTermos || !_consentimentoLgpd),
                                onAceiteTermosChanged: (v) => setState(() {
                                  _aceiteTermos = v;
                                  if (v && _consentimentoLgpd) _tentouSemAceite = false;
                                }),
                                onConsentimentoChanged: (v) => setState(() {
                                  _consentimentoLgpd = v;
                                  if (v && _aceiteTermos) _tentouSemAceite = false;
                                }),
                                onSubmit: _cadastrar,
                              ),
                              const SizedBox(height: 18),
                              PrimaryButton(
                                label: carregando ? 'Criando…' : 'Criar conta',
                                leadingIcon: AppIcons.flight,
                                onTap: carregando ? null : _cadastrar,
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

class _CadastroCard extends StatelessWidget {
  const _CadastroCard({
    required this.nome,
    required this.email,
    required this.senha,
    required this.aceiteTermos,
    required this.consentimentoLgpd,
    required this.erroAceite,
    required this.onAceiteTermosChanged,
    required this.onConsentimentoChanged,
    required this.onSubmit,
  });

  final TextEditingController nome;
  final TextEditingController email;
  final TextEditingController senha;
  final bool aceiteTermos;
  final bool consentimentoLgpd;
  final bool erroAceite;
  final ValueChanged<bool> onAceiteTermosChanged;
  final ValueChanged<bool> onConsentimentoChanged;
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
              Text('CONTA DO RESPONSÁVEL',
                  style: AppType.mono(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: c.muted)),
              Icon(AppIcons.familia, size: 17, color: c.accentStrong),
            ],
          ),
          const SizedBox(height: 14),
          const Perforation(),
          const SizedBox(height: 16),
          PassportField(
            controller: nome,
            label: 'Seu nome',
            icon: AppIcons.signature,
            hint: 'Como podemos te chamar?',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
          ),
          const SizedBox(height: 16),
          PassportField(
            controller: email,
            label: 'E-mail',
            icon: AppIcons.email,
            hint: 'voce@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
          ),
          const SizedBox(height: 16),
          PassportField(
            controller: senha,
            label: 'Senha',
            icon: AppIcons.lock,
            hint: 'Mínimo de 8 caracteres',
            obscureText: true,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => onSubmit(),
            validator: (v) =>
                (v == null || v.length < 8) ? 'Mínimo de 8 caracteres' : null,
          ),
          const SizedBox(height: 16),
          _AceiteTermos(
            checked: aceiteTermos,
            erro: erroAceite && !aceiteTermos,
            onChanged: onAceiteTermosChanged,
          ),
          const SizedBox(height: 10),
          _ConsentimentoLgpd(
            checked: consentimentoLgpd,
            erro: erroAceite && !consentimentoLgpd,
            onChanged: onConsentimentoChanged,
          ),
        ],
      ),
    );
  }
}

/// Aceite genérico dos Termos de Uso — checkbox simples, sem destaque
/// especial (o destaque fica reservado pro consentimento LGPD abaixo).
class _AceiteTermos extends StatelessWidget {
  const _AceiteTermos({
    required this.checked,
    required this.erro,
    required this.onChanged,
  });

  final bool checked;
  final bool erro;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: c.primary,
              side: BorderSide(color: erro ? c.warn : c.line, width: 1.4),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppType.nunito(
                      size: 12, weight: FontWeight.w700, color: erro ? c.warn : c.muted),
                  children: [
                    const TextSpan(text: 'Li e aceito os '),
                    TextSpan(
                      text: 'Termos de Uso',
                      style: const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalTextScreen(
                                  titulo: 'Termos de Uso',
                                  texto: termosDeUsoResumo,
                                ),
                              ),
                            ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consentimento parental específico (LGPD art. 14 §1) — texto próprio, num
/// cartão destacado (borda/fundo diferentes), separado do aceite genérico
/// dos termos acima. Nunca pré-marcado.
class _ConsentimentoLgpd extends StatelessWidget {
  const _ConsentimentoLgpd({
    required this.checked,
    required this.erro,
    required this.onChanged,
  });

  final bool checked;
  final bool erro;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: erro ? c.warn : c.accentStrong, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: c.primary,
                side: BorderSide(color: erro ? c.warn : c.accentStrong, width: 1.4),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONSENTIMENTO PARA DADOS DA CRIANÇA',
                        style: AppType.mono(
                            size: 9.5,
                            weight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: c.accentStrong)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: AppType.nunito(
                            size: 12,
                            weight: FontWeight.w700,
                            color: erro ? c.warn : c.ink),
                        children: [
                          const TextSpan(
                            text: 'Sou responsável legal e autorizo o tratamento dos '
                                'dados da(s) criança(s) que vou cadastrar, conforme a '
                                'LGPD (art. 14). ',
                          ),
                          TextSpan(
                            text: 'Ver o que isso significa',
                            style: const TextStyle(decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LegalTextScreen(
                                        titulo: 'Consentimento de dados',
                                        texto: consentimentoLgpdTexto,
                                      ),
                                    ),
                                  ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
