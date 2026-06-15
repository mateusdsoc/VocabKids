import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'token_store.dart';

/// Providers de infraestrutura de rede — **compartilhados** por todas as
/// features (aluno e professor). Vivem em `core/` para que a superfície do
/// professor os reuse sem importar `features/identidade/` (regra R2 de
/// isolamento; ver `design/notas-implementacao.md`).
///
/// `features/identidade/auth_controller.dart` os re-exporta, então o código do
/// aluno que já os importava de lá continua funcionando sem mudança.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);
