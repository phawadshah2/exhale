import 'package:exhale/features/paywall/data/storekit/store_channel.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

export 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart'
    show
        SK2PriceLocale,
        SK2Product,
        SK2ProductPurchaseResult,
        SK2ProductType,
        SK2Transaction;

/// StoreKit 2, one to one. The only place the plugin is imported.
abstract interface class StoreKitGateway {
  Future<List<SK2Product>> products(List<String> ids);
  Future<bool> isIntroEligible(String productId);
  Future<SK2ProductPurchaseResult> purchase(String productId);
  Future<List<SK2Transaction>> currentEntitlements();
  Future<List<SK2Transaction>> transactions();
  Future<List<SK2Transaction>> unfinished();
  Future<void> finish(int id);
  Future<void> sync();
  Future<void> showManageSubscriptions();
  Future<void> presentCodeRedemptionSheet();

  /// `requested` or `cancelled`.
  Future<String> requestRefund(String productId);

  /// `{productId, renewsAt}` of a subscription still set to renew, or null.
  Future<Map<String, Object?>?> renewingSubscription();

  /// Fires on every transaction update.
  Stream<void> get updates;
}

class PluginStoreKitGateway implements StoreKitGateway {
  const PluginStoreKitGateway([this._channel = const StoreChannel()]);

  final StoreChannel _channel;

  @override
  Future<List<SK2Product>> products(List<String> ids) =>
      SK2Product.products(ids);

  @override
  Future<bool> isIntroEligible(String productId) =>
      SK2Product.isIntroductoryOfferEligible(productId);

  @override
  Future<SK2ProductPurchaseResult> purchase(String productId) =>
      SK2Product.purchase(productId);

  @override
  Future<List<SK2Transaction>> currentEntitlements() =>
      SK2Transaction.currentEntitlements();

  @override
  Future<List<SK2Transaction>> transactions() => SK2Transaction.transactions();

  @override
  Future<List<SK2Transaction>> unfinished() =>
      SK2Transaction.unfinishedTransactions();

  @override
  Future<void> finish(int id) => SK2Transaction.finish(id);

  @override
  Future<void> sync() => AppStore().sync();

  @override
  Future<void> showManageSubscriptions() =>
      AppStore().showManageSubscriptions();

  @override
  Future<void> presentCodeRedemptionSheet() =>
      InAppPurchaseStoreKitPlatformAddition().presentCodeRedemptionSheet();

  @override
  Future<String> requestRefund(String productId) =>
      _channel.requestRefund(productId);

  @override
  Future<Map<String, Object?>?> renewingSubscription() =>
      _channel.renewingSubscription();

  // In StoreKit 2 mode (the plugin's default) `purchaseStream` is the
  // broadcast stream fed by Transaction.updates; its first listener starts
  // the native listener. It also emits the result of each purchase call.
  @override
  Stream<void> get updates => InAppPurchase.instance.purchaseStream;
}
