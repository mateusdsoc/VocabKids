import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import 'envio_screen.dart';
import 'models.dart';
import 'resultado_screen.dart';
import 'widgets/empty_open.dart';
import 'widgets/open_redacao_card.dart';
import 'widgets/redacao_background.dart';
import 'widgets/sent_redacao_row.dart';

/// Área de Redação (produto §3.7 atalho · §4.6 envio) — desenhada como
/// **herói + histórico**, não lista: na prática há 1 (raramente 2) redação
/// aberta por vez, então a aberta vira o herói e as enviadas dão corpo embaixo.
///
/// Cliente fino do apresentável: parte de [Redacao.sample] e atualiza o estado
/// local ao enviar. Trocar por `GET /redacoes` quando ligar no backend.
class RedacaoScreen extends StatefulWidget {
  const RedacaoScreen({super.key});

  @override
  State<RedacaoScreen> createState() => _RedacaoScreenState();
}

class _RedacaoScreenState extends State<RedacaoScreen> {
  late List<Redacao> _itens = Redacao.sample();

  Future<void> _enviar(Redacao r) async {
    final paginas = await Navigator.of(context).push<int>(
      adaptivePageRoute(builder: (_) => EnvioScreen(redacao: r)),
    );
    if (paginas == null || !mounted) return;
    setState(() {
      _itens = [
        for (final it in _itens)
          if (it.id == r.id)
            it.copyWith(
              status: RedacaoStatus.emAnalise,
              enviadaEm: DateTime.now(),
              paginas: paginas,
            )
          else
            it,
      ];
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Redação enviada! Avisamos quando a análise sair.',
            style: AppType.nunito(
                size: 13.5, weight: FontWeight.w800, color: Colors.white)),
        backgroundColor: context.colors.goal,
      ));
  }

  void _abrirResultado(Redacao r) {
    Navigator.of(context).push(
      adaptivePageRoute(builder: (_) => ResultadoScreen(redacao: r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final abertas = _itens.where((r) => r.aberta).toList();
    final enviadas = _itens.where((r) => !r.aberta).toList()
      ..sort((a, b) =>
          (b.enviadaEm ?? DateTime(0)).compareTo(a.enviadaEm ?? DateTime(0)));

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
                    child: SingleChildScrollView(
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
                                onEnviar: () => _enviar(abertas[i]),
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
                                onTap: () => _abrirResultado(enviadas[i]),
                              ),
                            ],
                          ],
                          const SizedBox(height: 8),
                        ],
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
