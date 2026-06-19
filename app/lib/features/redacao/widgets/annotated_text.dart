import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../analise.dart';

/// Renderiza o texto do aluno com a correção **inline**: cada trecho ancorado
/// recebe um **sublinhado colorido** da sua dimensão (produto 4.4) e é tocável —
/// tocar chama [onTocar] com a anotação (a tela abre a dica).
///
/// O texto entre marcas fica em tinta normal. Marcas que se sobrepõem são
/// resolvidas pela primeira (a de menor início); as demais são ignoradas para
/// não embaralhar o recorte — o mock não sobrepõe, isto é só blindagem.
class AnnotatedText extends StatefulWidget {
  const AnnotatedText({
    super.key,
    required this.texto,
    required this.anotacoes,
    required this.onTocar,
  });

  final String texto;
  final List<Anotacao> anotacoes;
  final void Function(Anotacao) onTocar;

  @override
  State<AnnotatedText> createState() => _AnnotatedTextState();
}

class _AnnotatedTextState extends State<AnnotatedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _limparRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    _limparRecognizers();

    // Achata (anotação × âncora) em marcas e ordena pela posição no texto.
    final marcas = <({int inicio, int fim, Anotacao anotacao})>[];
    for (final a in widget.anotacoes) {
      for (final anc in a.ancoras) {
        marcas.add((inicio: anc.inicio, fim: anc.fim, anotacao: a));
      }
    }
    marcas.sort((x, y) => x.inicio.compareTo(y.inicio));

    final base = AppType.nunito(
        size: 15.5, weight: FontWeight.w600, color: c.ink, height: 1.62);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in marcas) {
      if (m.inicio < cursor || m.fim > widget.texto.length) continue; // overlap
      if (m.inicio > cursor) {
        spans.add(TextSpan(text: widget.texto.substring(cursor, m.inicio)));
      }
      final cor = m.anotacao.dimensao.cor(context);
      final tap = TapGestureRecognizer()
        ..onTap = () => widget.onTocar(m.anotacao);
      _recognizers.add(tap);
      spans.add(TextSpan(
        text: widget.texto.substring(m.inicio, m.fim),
        recognizer: tap,
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationColor: cor,
          decorationThickness: 2.4,
        ),
      ));
      cursor = m.fim;
    }
    if (cursor < widget.texto.length) {
      spans.add(TextSpan(text: widget.texto.substring(cursor)));
    }

    return Text.rich(TextSpan(style: base, children: spans));
  }
}
