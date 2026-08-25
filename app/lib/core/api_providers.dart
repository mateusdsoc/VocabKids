import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'token_store.dart';

/// Providers de infraestrutura de rede — **compartilhados** por todas as
/// features do app do aluno. Vivem em `core/` (não em `features/identidade/`)
/// pra qualquer feature poder importar só o necessário.
///
/// `features/identidade/auth_controller.dart` os re-exporta, então o código do
/// aluno que já os importava de lá continua funcionando sem mudança.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);
