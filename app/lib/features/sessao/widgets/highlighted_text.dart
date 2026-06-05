import 'package:flutter/material.dart';

/// Texto com um **token destacado** inline. Reutilizado para os três casos do
/// design: a palavra marcada do enunciado/exemplo (sublinhado pontilhado), a
/// lacuna "_____" da questão de completar, e a palavra em negrito nas frases.
///
/// Mantém tudo num só `Text.rich`, então quebra de linha e seleção funcionam
/// naturalmente.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.token,
    required this.tokenStyle,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle baseStyle;

  /// Trecho a destacar (primeira e demais ocorrências exatas).
  final String token;
  final TextStyle tokenStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: baseStyle, children: _spans()),
      textAlign: textAlign,
    );
  }

  List<InlineSpan> _spans() {
    if (token.isEmpty) return [TextSpan(text: text)];
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final i = text.indexOf(token, start);
      if (i < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(TextSpan(text: token, style: tokenStyle));
      start = i + token.length;
    }
    return spans;
  }
}
