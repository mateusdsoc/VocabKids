import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard de arquitetura da superfície do professor (ver
/// `design/notas-implementacao.md`, seção "Professor (web)").
///
/// Torna executáveis as duas regras que garantem **zero peso** no app do aluno:
/// - **R1:** nada fora de `features/professor/` (nem `main.dart`) importa
///   `features/professor/` → o tree-shaking remove o professor do APK/IPA.
/// - **R2:** `features/professor/` importa só `core/` e a própria subárvore.
///
/// O teste lê os imports dos arquivos `.dart` (não compila a árvore), então é
/// rápido e roda no `flutter test` comum. CWD = raiz do pacote (`app/`).

const _professorRoot = 'lib/features/professor/';
const _coreRoot = 'lib/core/';
const _professorEntry = 'lib/main_professor.dart';

String _posix(String s) => s.replaceAll('\\', '/');

/// Resolve um import relativo contra o diretório do arquivo, normalizando `..`
/// e devolvendo um caminho `lib/...` relativo à raiz do pacote.
String _resolveRelative(String fromDir, String rel) {
  final parts = _posix(fromDir).split('/').where((s) => s.isNotEmpty).toList();
  for (final seg in rel.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.' && seg.isNotEmpty) {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

/// Alvos de import **internos** ao pacote (normalizados para `lib/...`).
/// Ignora `dart:` e pacotes externos; mapeia `package:vocabkids/...` → `lib/...`.
List<String> _internalImports(File f) {
  final dir = _posix(f.parent.path);
  final re = RegExp(r'''import\s+['"]([^'"]+)['"]''');
  final out = <String>[];
  for (final m in re.allMatches(f.readAsStringSync())) {
    final raw = m.group(1)!;
    if (raw.startsWith('dart:')) continue;
    if (raw.startsWith('package:')) {
      const self = 'package:vocabkids/';
      if (raw.startsWith(self)) out.add('lib/${raw.substring(self.length)}');
      continue;
    }
    out.add(_resolveRelative(dir, raw));
  }
  return out;
}

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  group('Arquitetura — isolamento da superfície do professor', () {
    test('R1: o app do aluno nunca importa features/professor/', () {
      final offenders = <String>[];
      for (final f in _dartFiles('lib')) {
        final path = _posix(f.path);
        if (path.contains(_professorRoot)) continue; // a própria árvore
        if (path.endsWith(_professorEntry)) continue; // entrypoint do professor
        for (final imp in _internalImports(f)) {
          if (imp.contains(_professorRoot)) offenders.add('$path → $imp');
        }
      }
      expect(offenders, isEmpty,
          reason: 'Importar features/professor/ a partir do app do aluno '
              'quebra R1 e pesaria o APK/IPA do aluno:\n'
              '${offenders.join('\n')}');
    });

    test('R2: features/professor/ importa só core/ e a própria subárvore', () {
      if (!Directory(_professorRoot).existsSync()) return;
      final offenders = <String>[];
      for (final f in _dartFiles(_professorRoot)) {
        final path = _posix(f.path);
        for (final imp in _internalImports(f)) {
          final ok =
              imp.startsWith(_professorRoot) || imp.startsWith(_coreRoot);
          if (!ok) offenders.add('$path → $imp');
        }
      }
      expect(offenders, isEmpty,
          reason: 'features/professor/ só pode importar core/ e a si mesmo '
              '(quebra R2):\n${offenders.join('\n')}');
    });
  });
}
