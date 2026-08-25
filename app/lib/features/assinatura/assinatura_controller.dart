import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/api_providers.dart';
import 'models.dart';
import 'repository.dart';

final assinaturaRepositoryProvider = Provider<AssinaturaRepository>(
  (ref) => AssinaturaRepository(ref.watch(apiClientProvider)),
);

/// Status real da assinatura (fonte: backend). `autoDispose` — relido a cada
/// vez que a Área do Responsável ou o paywall abrem.
final assinaturaStatusProvider =
    FutureProvider.autoDispose<AssinaturaStatus>((ref) async {
  return ref.watch(assinaturaRepositoryProvider).status();
});

/// Oferta corrente do RevenueCat (preço/produtos do paywall).
final ofertaAtualProvider = FutureProvider.autoDispose<Offering?>((ref) async {
  return ref.watch(assinaturaRepositoryProvider).ofertaAtual();
});

/// Conduz a compra/restauração. Não guarda "está assinante" — isso é sempre
/// [assinaturaStatusProvider], relido do backend depois da ação (R-AS-1: o
/// app nunca decide sozinho, só dispara a compra e confere de novo).
class AssinaturaController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// `true` = compra concluída (ou já era assinante); `false` = cancelou ou
  /// falhou (o [state] carrega o erro, se houver — cancelamento não é erro).
  Future<bool> assinar(Package pacote) async {
    state = const AsyncLoading();
    try {
      await ref.read(assinaturaRepositoryProvider).comprar(pacote);
      state = const AsyncData(null);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        state = const AsyncData(null); // usuário fechou a folha nativa — não é erro
        return false;
      }
      state = AsyncError(e, StackTrace.current);
      return false;
    }
    ref.invalidate(assinaturaStatusProvider);
    return true;
  }

  Future<bool> restaurar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(assinaturaRepositoryProvider).restaurar(),
    );
    ref.invalidate(assinaturaStatusProvider);
    return !state.hasError;
  }
}

final assinaturaControllerProvider =
    AsyncNotifierProvider<AssinaturaController, void>(AssinaturaController.new);
