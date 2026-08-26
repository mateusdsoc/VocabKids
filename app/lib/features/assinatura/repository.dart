import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import 'models.dart';

/// Fala com o RevenueCat (StoreKit) e com `GET /v1/assinatura`.
///
/// O RevenueCat é quem valida a compra com a Apple e manda o webhook pro
/// backend (docs/plano_b2c.md Fase 3, §12) — o app nunca decide sozinho se a
/// assinatura está ativa, só inicia a compra e depois relê o status real do
/// backend (`status()`).
class AssinaturaRepository {
  AssinaturaRepository(this._api);

  final ApiClient _api;
  bool _configurado = false;

  /// Liga o SDK identificando o usuário pelo `conta_id` — mesma convenção que
  /// o backend usa pra casar o `app_user_id` do webhook com a conta
  /// (`identidade/service.py`). Sem API key real configurada
  /// (`AppConfig.revenueCatApiKey`), não faz nada: é o estado de
  /// desenvolvimento até a conta RevenueCat existir.
  Future<void> inicializar({required int contaId}) async {
    if (_configurado || AppConfig.revenueCatApiKey.isEmpty) return;
    await Purchases.configure(
      PurchasesConfiguration(AppConfig.revenueCatApiKey)
        ..appUserID = contaId.toString(),
    );
    _configurado = true;
  }

  /// Oferta corrente (mensal + anual, configurados no painel do RevenueCat).
  /// `null` sem API key real ou sem oferta publicada.
  Future<Offering?> ofertaAtual() async {
    if (AppConfig.revenueCatApiKey.isEmpty) return null;
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  Future<void> comprar(Package pacote) =>
      Purchases.purchase(PurchaseParams.package(pacote));

  Future<void> restaurar() => Purchases.restorePurchases();

  /// Status real, sempre do backend — nunca derivado do SDK local.
  Future<AssinaturaStatus> status() async {
    if (AppConfig.demo) {
      return AssinaturaStatus(
          assinante: true, status: 'ativa', expiraEm: null, emTrial: false);
    }
    final json = await _api.get('/assinatura');
    return AssinaturaStatus.fromJson(json as Map<String, dynamic>);
  }
}
