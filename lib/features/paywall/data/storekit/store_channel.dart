import 'package:flutter/services.dart';

/// The StoreKit 2 calls the plugin lacks, answered by `StorePlugin.swift`.
class StoreChannel {
  const StoreChannel();

  static const MethodChannel _channel = MethodChannel('exhale/store');

  /// Apple's refund sheet for [productId]'s latest transaction:
  /// `requested` or `cancelled`.
  Future<String> requestRefund(String productId) async =>
      await _channel.invokeMethod<String>('requestRefund', {
        'productId': productId,
      }) ??
      'cancelled';

  /// `{productId, renewsAt}` (ISO 8601, UTC) of a subscription still set to
  /// renew, or null.
  Future<Map<String, Object?>?> renewingSubscription() =>
      _channel.invokeMapMethod<String, Object?>('renewingSubscription');
}
