import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../identidade/auth_controller.dart';
import '../identidade/widgets/passport_field.dart';

/// Exclusão de conta (R-ID-6, produto §08 item 4): apaga a conta do
/// responsável e os dados de **todos** os perfis. Pede a senha de novo —
/// mesmo já tendo passado pelo PIN — porque é irreversível e o PIN sozinho é
/// um gate leve demais para essa ação.
class ExcluirContaScreen extends ConsumerStatefulWidget {
  const ExcluirContaScreen({super.key});

  @override
  ConsumerState<ExcluirContaScreen> createState() => _ExcluirContaScreenState();
}

class _ExcluirContaScreenState extends ConsumerState<ExcluirContaScreen> {
  final _senha = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _confirmado = false;
  bool _enviando = false;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _excluir() async {
    FocusScope.of(context).unfocus();
    if (!_confirmado) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    if (AppConfig.demo) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .excluirConta(senha: _senha.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content:
                Text(e.code == 'credenciais_invalidas' ? 'Senha incorreta.' : e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: c.glass,
                      shape:
                          CircleBorder(side: BorderSide(color: c.line, width: 1)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(AppIcons.back, size: 24, color: c.ink),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(AppIcons.delete, size: 40, color: c.error),
                              const SizedBox(height: 14),
                              Text('Excluir conta',
                                  textAlign: TextAlign.center,
                                  style: AppType.fredoka(size: 22, color: c.ink)),
                              const SizedBox(height: 8),
                              Text(
                                'Isso apaga a conta e os dados de todos os '
                                'perfis de criança — progresso, redações e '
                                'assinatura. Não tem como desfazer.',
                                textAlign: TextAlign.center,
                                style: AppType.nunito(
                                    size: 13.5,
                                    weight: FontWeight.w600,
                                    color: c.muted,
                                    height: 1.4),
                              ),
                              const SizedBox(height: 22),
                              SurfaceCard(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    PassportField(
                                      controller: _senha,
                                      label: 'Confirme sua senha',
                                      icon: AppIcons.lock,
                                      obscureText: true,
                                      autofocus: true,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _excluir(),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Digite sua senha'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _CheckboxLinha(
                                      value: _confirmado,
                                      onChanged: (v) =>
                                          setState(() => _confirmado = v),
                                      texto:
                                          'Entendo que essa ação é permanente.',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _BotaoExcluir(
                                enviando: _enviando,
                                habilitado: _confirmado && !_enviando,
                                onTap: _excluir,
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

class _CheckboxLinha extends StatelessWidget {
  const _CheckboxLinha({
    required this.value,
    required this.onChanged,
    required this.texto,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: c.error,
          ),
          Expanded(
            child: Text(texto,
                style: AppType.nunito(
                    size: 12.5, weight: FontWeight.w700, color: c.ink)),
          ),
        ],
      ),
    );
  }
}

/// Botão destrutivo — vermelho de alerta, distinto do [PrimaryButton] azul.
class _BotaoExcluir extends StatelessWidget {
  const _BotaoExcluir({
    required this.enviando,
    required this.habilitado,
    required this.onTap,
  });

  final bool enviando;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(16);
    if (!habilitado) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.muted.withValues(alpha: 0.22), c.paper),
          borderRadius: radius,
          border: Border.all(color: c.line, width: 1),
        ),
        child: Text(enviando ? 'Excluindo…' : 'Excluir conta',
            style: AppType.fredoka(
                size: 17, weight: FontWeight.w500, color: c.muted)),
      );
    }
    return Material(
      color: c.error,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          alignment: Alignment.center,
          child: Text('Excluir conta',
              style: AppType.fredoka(
                  size: 17, weight: FontWeight.w500, color: Colors.white)),
        ),
      ),
    );
  }
}
