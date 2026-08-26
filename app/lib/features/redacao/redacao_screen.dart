import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import 'envio_screen.dart';
import 'models.dart';
import 'redacao_controller.dart';
import 'resultado_screen.dart';
import 'widgets/empty_open.dart';
import 'widgets/open_redacao_card.dart';
import 'widgets/redacao_background.dart';
import 'widgets/sent_redacao_row.dart';

/// Área de Redação (produto §3.7 atalho · §4.6 envio) — desenhada como
/// **herói + histórico**, não lista: na prática há 1 (raramente 2) redação
/// aberta por vez, então a aberta vira o herói e as enviadas dão corpo embaixo.
///
/// Consome `GET /v1/redacoes` (server-side atribui o tema, a cada 15 dias ou
/// sob demanda pelo responsável — o app nunca escolhe tema).
class RedacaoScreen extends ConsumerWidget {
  const RedacaoScreen({super.key});

  Future<void> _enviar(
      BuildContext context, WidgetRef ref, Redacao r) async {
    final status = await Navigator.of(context).push<String>(
      adaptivePageRoute(builder: (_) => EnvioScreen(redacao: r)),
    );
    if (status == null) return;
    ref.invalidate(redacaoListaProvider);
    if (!context.mounted) return;
    final (msg, alerta) = _mensagemEnvio(status);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: AppType.nunito(
                size: 13.5, weight: FontWeight.w800, color: Colors.white)),
        backgroundColor: alerta ? context.colors.warn : context.colors.goal,
      ));
  }

  (String, bool) _mensagemEnvio(String status) => switch (status) {
        'analisada' => ('Redação enviada! A análise já está pronta.', false),
        'revisao_humana' => (
            'Recebemos sua redação. Um adulto de confiança vai dar uma '
                'olhada com você antes de continuar.',
            true
          ),
        'erro_ingestao' => (
            'Sua redação ficou mais curta do que o esperado para essa fase. '
                'Tente escrever um pouco mais e enviar de novo.',
            true
          ),
        'erro_analise' => (
            'Não conseguimos analisar sua redação agora. Tente de novo mais '
                'tarde.',
            true
          ),
        _ => ('Redação enviada! Avisamos quando a análise sair.', false),
      };

  void _abrirResultado(BuildContext context, Redacao r) {
    Navigator.of(context).push(
      adaptivePageRoute(builder: (_) => ResultadoScreen(redacao: r)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(redacaoListaProvider);

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: RedacaoBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: async.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _ErroCarregando(
                        mensagem: e is ApiException
                            ? e.message
                            : 'Não deu para carregar suas redações.',
                        onRetry: () => ref.invalidate(redacaoListaProvider),
                      ),
                      data: (estado) => _Lista(
                        itens: estado.itens,
                        onEnviar: (r) => _enviar(context, ref, r),
                        onAbrirResultado: (r) => _abrirResultado(context, r),
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

class _Lista extends StatelessWidget {
  const _Lista({
    required this.itens,
    required this.onEnviar,
    required this.onAbrirResultado,
  });

  final List<Redacao> itens;
  final ValueChanged<Redacao> onEnviar;
  final ValueChanged<Redacao> onAbrirResultado;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final abertas = itens.where((r) => r.aberta).toList();
    final enviadas = itens.where((r) => !r.aberta).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          if (abertas.isEmpty)
            const EmptyOpen()
          else
            for (var i = 0; i < abertas.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              OpenRedacaoCard(
                redacao: abertas[i],
                onEnviar: () => onEnviar(abertas[i]),
              ),
            ],
          if (enviadas.isNotEmpty) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('ENVIADAS',
                  style: AppType.mono(
                      size: 9.5,
                      weight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: c.muted)),
            ),
            const SizedBox(height: 9),
            for (var i = 0; i < enviadas.length; i++) ...[
              if (i > 0) const SizedBox(height: 9),
              SentRedacaoRow(
                redacao: enviadas[i],
                onTap: () => onAbrirResultado(enviadas[i]),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ErroCarregando extends StatelessWidget {
  const _ErroCarregando({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.report, size: 32, color: c.muted),
            const SizedBox(height: 12),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: AppType.nunito(
                    size: 13.5, weight: FontWeight.w700, color: c.muted)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text('Tentar de novo',
                  style: AppType.nunito(
                      size: 13.5,
                      weight: FontWeight.w800,
                      color: c.accentStrong)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topo: voltar + título manuscrito "Redação".
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
              Icon(AppIcons.redacao, size: 17, color: c.accentStrong),
              const SizedBox(width: 7),
              Text('Redação', style: AppType.caveat(size: 23, color: c.ink)),
            ],
          ),
        ],
      ),
    );
  }
}
