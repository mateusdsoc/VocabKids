import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../identidade/auth_controller.dart';
import '../identidade/widgets/passport_background.dart';
import 'assinatura_controller.dart';

/// Paywall — só o **responsável** vê esta tela (aberta a partir do Seletor de
/// Perfil ou da Área do Responsável), nunca a criança em meio ao jogo.
///
/// Guideline 5.1.4 da Apple + `docs/plano_b2c.md` R-RS-1: nenhuma compra
/// acontece sem um adulto na tela — quando a criança esbarra no gate de
/// assinatura ([SessionScreen]), a mensagem é "peça pra um adulto", não um
/// botão de comprar.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _inicializando = true;
  Object? _erroInicializacao;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final conta = await ref.read(identidadeRepositoryProvider).conta();
      await ref
          .read(assinaturaRepositoryProvider)
          .inicializar(contaId: conta.contaId);
    } catch (e) {
      _erroInicializacao = e;
    } finally {
      if (mounted) setState(() => _inicializando = false);
    }
  }

  Future<void> _assinar(Package pacote) async {
    final ok = await ref.read(assinaturaControllerProvider.notifier).assinar(pacote);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(assinaturaStatusProvider);
      Navigator.of(context).maybePop();
      return;
    }
    final erro = ref.read(assinaturaControllerProvider).error;
    if (erro == null) return; // cancelou a folha nativa — sem mensagem
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('Não deu para completar a assinatura. Tente de novo.')));
  }

  Future<void> _restaurar() async {
    final ok = await ref.read(assinaturaControllerProvider.notifier).restaurar();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(ok
              ? 'Compras restauradas.'
              : 'Não encontramos uma assinatura pra restaurar.')));
    if (ok) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final carregando = ref.watch(assinaturaControllerProvider).isLoading;

    return Scaffold(
      body: PassportBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
                child: SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: c.glass,
                      shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(AppIcons.close, size: 20, color: c.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(AppIcons.passaporte, size: 44, color: c.accentStrong),
                          const SizedBox(height: 14),
                          Text('Continue a viagem',
                              textAlign: TextAlign.center,
                              style: AppType.fredoka(size: 24, color: c.ink)),
                          const SizedBox(height: 8),
                          Text(
                            'O 1º destino é grátis. Assine pra desbloquear o '
                            'mapa inteiro, novas palavras toda semana e o '
                            'passaporte completo.',
                            textAlign: TextAlign.center,
                            style: AppType.nunito(
                                size: 14, weight: FontWeight.w600, color: c.muted),
                          ),
                          const SizedBox(height: 24),
                          _ofertaOuFallback(context, carregando),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: carregando ? null : _restaurar,
                              child: Text('Já assinei — restaurar compra',
                                  style: AppType.nunito(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: c.primary)),
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
    );
  }

  Widget _ofertaOuFallback(BuildContext context, bool carregando) {
    if (AppConfig.revenueCatApiKey.isEmpty) {
      // Placeholder de desenvolvimento (docs/plano_b2c.md Fase 3): sem API key
      // real do RevenueCat ainda não há oferta pra listar.
      final c = context.colors;
      return SurfaceCard(
        child: Text(
          'Configuração de pagamento pendente — a oferta aparece aqui assim '
          'que a conta do RevenueCat estiver conectada.',
          textAlign: TextAlign.center,
          style: AppType.nunito(size: 13, weight: FontWeight.w700, color: c.muted),
        ),
      );
    }

    final oferta = ref.watch(ofertaAtualProvider);
    if (_inicializando || oferta.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erroInicializacao != null || oferta.hasError) {
      final c = context.colors;
      return Text(
        'Não deu para carregar os planos agora. Confira a conexão e tente de novo.',
        textAlign: TextAlign.center,
        style: AppType.nunito(size: 13, weight: FontWeight.w700, color: c.warn),
      );
    }

    final pacotes = oferta.value?.availablePackages ?? const [];
    if (pacotes.isEmpty) {
      final c = context.colors;
      return Text('Nenhum plano disponível no momento.',
          textAlign: TextAlign.center,
          style: AppType.nunito(size: 13, weight: FontWeight.w700, color: c.muted));
    }

    return Column(
      children: [
        for (final pacote in pacotes) ...[
          _PacoteCard(
            pacote: pacote,
            disabled: carregando,
            onTap: () => _assinar(pacote),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PacoteCard extends StatelessWidget {
  const _PacoteCard({
    required this.pacote,
    required this.disabled,
    required this.onTap,
  });

  final Package pacote;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final produto = pacote.storeProduct;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(produto.title,
                          style: AppType.nunito(
                              size: 15,
                              weight: FontWeight.w800,
                              color: context.colors.ink)),
                      const SizedBox(height: 2),
                      Text(produto.priceString,
                          style: AppType.fredoka(
                              size: 18, color: context.colors.accentStrong)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: PrimaryButton(
                      label: 'Assinar', onTap: disabled ? null : onTap),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
