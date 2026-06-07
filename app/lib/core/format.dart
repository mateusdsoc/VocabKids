/// Formatação de números no padrão pt-BR.
library;

/// Separa milhares com ponto (3120 → "3.120"). Usado no XP da Home e do Resumo.
String milhar(int n) {
  final s = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return n < 0 ? '-$buffer' : buffer.toString();
}
