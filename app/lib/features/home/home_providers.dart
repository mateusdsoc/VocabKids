import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../identidade/auth_controller.dart';
import 'data/trilha_repository.dart';
import 'home_data.dart';
import 'home_mapper.dart';

/// Repositório da trilha, reaproveitando o [ApiClient] já provido pela
/// identidade (mesmo token/transporte).
final trilhaRepositoryProvider = Provider<TrilhaRepository>(
  (ref) => TrilhaRepository(ref.watch(apiClientProvider)),
);

/// Dados consolidados da Home (`/me` já em memória + `/trilha`).
///
/// `autoDispose`: a Home é destino de navegação; ao sair, o estado é liberado e
/// reconstruído fresco no retorno (evita servir dados velhos pós-sessão).
final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  if (AppConfig.demo) return HomeData.sample();

  final me = ref.watch(authControllerProvider).value;
  if (me == null) {
    throw StateError('Home requer um aluno autenticado.');
  }
  final trilha = await ref.watch(trilhaRepositoryProvider).carregar();
  return HomeMapper.from(me: me, trilha: trilha);
});
