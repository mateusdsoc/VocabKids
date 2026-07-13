import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/data/trilha_models.dart';
import '../home/home_providers.dart' show trilhaRepositoryProvider;

/// A trilha crua do servidor (`GET /v1/trilha`) para o mapa.
///
/// `autoDispose`: a Trilha é destino de navegação; sair libera o estado e o
/// retorno refaz o GET — o mapa nunca mostra um snapshot de antes da sessão.
final trilhaProvider = FutureProvider.autoDispose<Trilha>(
  (ref) => ref.watch(trilhaRepositoryProvider).carregar(),
);
