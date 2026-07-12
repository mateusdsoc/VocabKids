import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../home/home_providers.dart' show trilhaRepositoryProvider;
import '../identidade/auth_controller.dart';
import 'conquista_queue.dart';
import 'data/passaporte_repository.dart';
import 'models.dart';
import 'passaporte_mapper.dart';

/// Repositório do Passaporte. Criá-lo também **arma a persistência do reveal**
/// na [ConquistaQueue]: qualquer reveal (venha do teaser do Resumo ou da fila
/// drenada no Passaporte) marca o item como visto no servidor, melhor esforço.
final passaporteRepositoryProvider = Provider<PassaporteRepository>((ref) {
  final repo = PassaporteRepository(ref.watch(apiClientProvider));
  if (!AppConfig.demo) {
    ConquistaQueue.instance.persistir = (Conquista c) async {
      final id = c.colecionavelId;
      if (id != null) await repo.marcarRevelado(id);
    };
  }
  return repo;
});

/// Coleção + fila de reveals pendentes (`/me` + `/trilha` + `/passaporte`).
///
/// `autoDispose`: recarrega fresco a cada abertura do Passaporte (a coleção
/// muda a cada sessão praticada). Ao carregar, a fila local de conquistas é
/// **substituída** pela pendência do servidor — a fonte de verdade real; o
/// enfileiramento local da sessão cobre só o atalho imediato do Resumo.
final passaporteProvider =
    FutureProvider.autoDispose<PassaporteCarregado>((ref) async {
  if (AppConfig.demo) {
    // Demo: coleção de amostra; a fila local (sessão demo) fica como está.
    return PassaporteCarregado(
      passaporte: Passaporte.sample,
      pendentes: ConquistaQueue.instance.pendentes,
    );
  }

  final me = ref.watch(authControllerProvider).value;
  if (me == null) {
    throw StateError('Passaporte requer um aluno autenticado.');
  }
  final repo = ref.watch(passaporteRepositoryProvider);
  final (dto, trilha) = await (
    repo.carregar(),
    ref.watch(trilhaRepositoryProvider).carregar(),
  ).wait;

  final carregado = PassaporteMapper.carregadoDe(me: me, trilha: trilha, dto: dto);
  ConquistaQueue.instance.substituir(carregado.pendentes);
  return carregado;
});
