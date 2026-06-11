import 'package:flutter/foundation.dart';

import 'models.dart';

/// Fila de **conquistas pendentes de revelação** (Modo Conquista, §7).
///
/// Resolve o caso do aluno que termina a sessão e segue direto pra Trilha sem
/// tocar "Ver no Passaporte": a conquista fica guardada aqui e o reveal toca
/// quando ele **abrir o Passaporte** — uma de cada vez, se acumulou várias
/// (várias sessões sem abrir o Passaporte).
///
/// Hoje vive em memória (singleton): cobre o cenário "várias sessões na mesma
/// sessão do app". A **fonte de verdade real é o servidor** (cliente fino) —
/// com o backend, `GET /v1/passaporte` traz os itens novos não revelados e
/// `POST` marca como vistos; este store então só espelha. Por isso é leve:
/// guarda referências de itens, não reproduz nada em paralelo.
class ConquistaQueue {
  ConquistaQueue._();
  static final ConquistaQueue instance = ConquistaQueue._();

  final ValueNotifier<List<Conquista>> _pendentes = ValueNotifier(const []);

  /// Observável (ex.: badge "novidades" no avatar do Passaporte, depois).
  ValueListenable<List<Conquista>> get listenable => _pendentes;

  List<Conquista> get pendentes => List.unmodifiable(_pendentes.value);
  bool get vazia => _pendentes.value.isEmpty;

  /// Enfileira ao fim da sessão (quando houve item novo).
  void enfileirar(Conquista c) {
    _pendentes.value = [..._pendentes.value, c];
  }

  /// Marca como revelada (tira da fila). Chamado pelo reveal ao mostrar cada
  /// item — assim tanto o caminho do teaser quanto o do Passaporte drenam a
  /// mesma fila, sem mostrar duplicado.
  void revelada(Conquista c) {
    final lista = [..._pendentes.value]..remove(c);
    _pendentes.value = lista;
  }

  @visibleForTesting
  void limpar() => _pendentes.value = const [];
}
