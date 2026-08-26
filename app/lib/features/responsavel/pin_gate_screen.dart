import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/config.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../identidade/widgets/passport_background.dart';
import '../identidade/widgets/passport_field.dart';
import 'responsavel_controller.dart';
import 'responsavel_home_screen.dart';

/// Portão parental (R-RS-1, `docs/plano_b2c.md` §08): nenhum dado da Área do
/// Responsável aparece antes do PIN de 4 dígitos ser conferido pelo servidor
/// (`POST /conta/pin/verificar`). Quem ainda não definiu um PIN passa primeiro
/// por criar um (`POST /conta/pin` — não exige o PIN antigo, o token do
/// responsável já é a autenticação forte por trás dele).
class PinGateScreen extends ConsumerStatefulWidget {
  const PinGateScreen({super.key});

  @override
  ConsumerState<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends ConsumerState<PinGateScreen> {
  final _pin = TextEditingController();
  final _confirmacao = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _enviando = false;
  bool _criandoNovo = false; // "esqueci o PIN" força o fluxo de criação

  @override
  void dispose() {
    _pin.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _continuar({required bool criando}) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    if (AppConfig.demo) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _abrirArea();
      return;
    }

    try {
      final repo = ref.read(responsavelRepositoryProvider);
      if (criando) {
        await repo.definirPin(_pin.text.trim());
      } else {
        await repo.verificarPin(_pin.text.trim());
      }
      if (!mounted) return;
      _abrirArea();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _avisar(e.statusCode == 429
          ? 'Muitas tentativas. Espere um pouco e tente de novo.'
          : e.code == 'pin_invalido'
              ? 'PIN incorreto.'
              : e.message);
      _pin.clear();
    }
  }

  void _abrirArea() {
    Navigator.of(context).pushReplacement(
      adaptivePageRoute(builder: (_) => const ResponsavelHomeScreen()),
    );
  }

  void _avisar(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
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
                        child: ref.watch(pinStatusProvider).when(
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (_, _) => _ErroCarregando(
                                onRetry: () => ref.invalidate(pinStatusProvider),
                              ),
                              data: (status) {
                                final criando = _criandoNovo || !status.definido;
                                return _Formulario(
                                  formKey: _formKey,
                                  pin: _pin,
                                  confirmacao: _confirmacao,
                                  criando: criando,
                                  jaTinhaPin: status.definido,
                                  enviando: _enviando,
                                  onEsqueciPin: () =>
                                      setState(() => _criandoNovo = true),
                                  onContinuar: () => _continuar(criando: criando),
                                );
                              },
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
              child: Icon(AppIcons.close, size: 20, color: c.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErroCarregando extends StatelessWidget {
  const _ErroCarregando({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Não deu para carregar.',
            style: AppType.nunito(
                size: 13.5, weight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
      ],
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.formKey,
    required this.pin,
    required this.confirmacao,
    required this.criando,
    required this.jaTinhaPin,
    required this.enviando,
    required this.onEsqueciPin,
    required this.onContinuar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController pin;
  final TextEditingController confirmacao;
  final bool criando;
  final bool jaTinhaPin;
  final bool enviando;
  final VoidCallback onEsqueciPin;
  final VoidCallback onContinuar;

  String? _validarPin(String? v) {
    final t = (v ?? '').trim();
    if (t.length != 4 || int.tryParse(t) == null) return 'Digite os 4 números.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(AppIcons.privacidade, size: 40, color: c.accentStrong),
          const SizedBox(height: 14),
          Text(
            criando ? 'Crie um PIN de 4 números' : 'Área do Responsável',
            textAlign: TextAlign.center,
            style: AppType.fredoka(size: 22, color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            criando
                ? 'Só você vai usar esse número pra abrir o resumo da '
                    'criança — guarde-o num lugar que só um adulto acesse.'
                : 'Digite o PIN pra ver o resumo da semana e gerenciar a '
                    'conta.',
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 13.5, weight: FontWeight.w600, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          SurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PassportField(
                  controller: pin,
                  label: criando ? 'Novo PIN' : 'PIN',
                  icon: AppIcons.lock,
                  hint: '____',
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textInputAction:
                      criando ? TextInputAction.next : TextInputAction.done,
                  autofocus: true,
                  onSubmitted: criando ? null : (_) => onContinuar(),
                  validator: _validarPin,
                ),
                if (criando) ...[
                  const SizedBox(height: 14),
                  PassportField(
                    controller: confirmacao,
                    label: 'Confirme o PIN',
                    icon: AppIcons.lock,
                    hint: '____',
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onContinuar(),
                    validator: (v) {
                      final erro = _validarPin(v);
                      if (erro != null) return erro;
                      if (v!.trim() != pin.text.trim()) {
                        return 'Os números não conferem.';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: enviando
                ? 'Confirmando…'
                : criando
                    ? 'Salvar PIN'
                    : 'Entrar',
            leadingIcon: AppIcons.lock,
            onTap: enviando ? null : onContinuar,
          ),
          if (!criando && jaTinhaPin) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: enviando ? null : onEsqueciPin,
                child: Text('Esqueci o PIN',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w800, color: c.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
