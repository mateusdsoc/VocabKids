import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../analise_mock.dart';

/// Cor e rótulo de cada dimensão de análise, via tokens (nunca hardcoded).
/// Pontuação usa o `error` no padrão **suavizado** (tint + sublinhado), o mesmo
/// tratamento não-punitivo da resposta errada na Sessão.
({Color cor, String rotulo}) estiloDimensao(AppColors c, DimensaoAnalise d) =>
    switch (d) {
      DimensaoAnalise.vocabulario => (cor: c.primary, rotulo: 'Vocabulário'),
      DimensaoAnalise.acentuacao => (cor: c.warn, rotulo: 'Acentuação'),
      DimensaoAnalise.pontuacao => (cor: c.error, rotulo: 'Pontuação'),
      DimensaoAnalise.estrutura => (cor: c.accentStrong, rotulo: 'Estrutura'),
    };

/// A transcrição da redação com os grifos coloridos por dimensão (produto
/// §4.4: "é o próprio texto do aluno com camadas de feedback", não uma tela
/// por dimensão). Cada grifo é tocável e chama [onTapAnotacao]; o grifo da
/// anotação [selecionada] fica mais forte.
class TextoAnotado extends StatefulWidget {
  const TextoAnotado({
    super.key,
    required this.analise,
    required this.selecionada,
    required this.onTapAnotacao,
  });

  final AnaliseRedacao analise;
  final int? selecionada;
  final ValueChanged<int> onTapAnotacao;

  @override
  State<TextoAnotado> createState() => _TextoAnotadoState();
}

class _TextoAnotadoState extends State<TextoAnotado> {
  /// Um recognizer por trecho grifado (índice do trecho → recognizer). Criados
  /// uma vez (a amostra é const) e descartados no dispose.
  late final Map<int, TapGestureRecognizer> _taps = {
    for (var i = 0; i < widget.analise.trechos.length; i++)
      if (widget.analise.trechos[i].anotacao != null)
        i: TapGestureRecognizer()
          ..onTap = () {
            HapticFeedback.selectionClick();
            widget.onTapAnotacao(widget.analise.trechos[i].anotacao!);
          },
  };

  @override
  void dispose() {
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = AppType.nunito(
        size: 14.5, weight: FontWeight.w600, color: c.ink, height: 1.7);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < widget.analise.trechos.length; i++)
            _span(c, i, widget.analise.trechos[i]),
        ],
      ),
    );
  }

  TextSpan _span(AppColors c, int i, TrechoAnalisado t) {
    final idx = t.anotacao;
    if (idx == null) return TextSpan(text: t.texto);

    final cor = estiloDimensao(c, widget.analise.anotacoes[idx].dimensao).cor;
    final ativa = widget.selecionada == idx;
    return TextSpan(
      text: t.texto,
      recognizer: _taps[i],
      style: TextStyle(
        fontWeight: FontWeight.w800,
        backgroundColor: cor.withValues(alpha: ativa ? 0.30 : 0.14),
        decoration: TextDecoration.underline,
        decorationColor: cor,
        decorationThickness: 2,
      ),
    );
  }
}
