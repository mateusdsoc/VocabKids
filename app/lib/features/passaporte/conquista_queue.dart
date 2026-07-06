import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Fila de **conquistas pendentes de revelação** (Modo Conquista, §7).
///
/// Resolve o caso do aluno que termina a sessão e segue direto pra Trilha sem
/// tocar "Ver no Passaporte": a conquista fica guardada aqui e o reveal toca
/// quando ele **abrir o Passaporte** — uma de cada vez, se acumulou várias
/// (várias sessões sem abrir o Passaporte).
///
/// A **fonte de verdade é o servidor** (cliente fino): `GET /v1/passaporte`
/// traz os itens ganhos e não revelados, e este store só espelha —
/// [substituir] re-hidrata a fila ao abrir o Passaporte, e [revelada] persiste
/// o "visto" via [persistir] (`POST /v1/passaporte/{id}/revelado`). O
/// enfileiramento local ([enfileirar], nas respostas da sessão) cobre o
/// atalho imediato do Resumo sem esperar rede.
class ConquistaQueue {
  ConquistaQueue._();
  static final ConquistaQueue instance = ConquistaQueue._();

  final ValueNotifier<List<Conquista>> _pendentes = ValueNotifier(const []);

  /// Persistência do reveal, armada pelo `passaporteRepositoryProvider`
  /// (nula em demo/testes). Melhor esforço: o reveal nunca trava por rede —
  /// se o POST falhar, o item volta pendente do servidor na próxima abertura
  /// e o reveal repete (aceitável e raro; melhor que perder o momento).
  Future<void> Function(Conquista)? persistir;

  /// Observável (ex.: badge "novidades" no avatar do Passaporte, depois).
  ValueListenable<List<Conquista>> get listenable => _pendentes;

  List<Conquista> get pendentes => List.unmodifiable(_pendentes.value);
  bool get vazia => _pendentes.value.isEmpty;

  /// Enfileira ao ganhar (respostas da sessão, quando houve item novo).
  void enfileirar(Conquista c) {
    _pendentes.value = [..._pendentes.value, c];
  }

  /// Re-hidrata a fila com a pendência do servidor (abertura do Passaporte).
  /// Substituição total: o servidor já inclui o que a sessão enfileirou local
  /// (persistido no `responder`) — trocar em bloco é o dedupe.
  void substituir(List<Conquista> pendentes) {
    _pendentes.value = List.unmodifiable(pendentes);
  }

  /// Marca como revelada (tira da fila e persiste o "visto"). Chamado pelo
  /// reveal ao mostrar cada item — assim tanto o caminho do teaser quanto o
  /// do Passaporte drenam a mesma fila, sem mostrar duplicado.
  void revelada(Conquista c) {
    final lista = [..._pendentes.value]..remove(c);
    _pendentes.value = lista;
    persistir?.call(c).ignore();
  }

  @visibleForTesting
  void limpar() => _pendentes.value = const [];
}
