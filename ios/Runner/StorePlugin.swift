import Flutter
import StoreKit
import UIKit

/// StoreKit 2 calls the in_app_purchase plugin lacks: Apple's refund sheet and
/// whether a subscription is still set to renew.
final class StorePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "exhale/store",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(StorePlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestRefund":
      guard let productId = (call.arguments as? [String: Any])?["productId"] as? String else {
        result(FlutterError(code: "bad_args", message: "productId missing", details: nil))
        return
      }
      Task { @MainActor in
        await Self.requestRefund(productId: productId, result: result)
      }
    case "renewingSubscription":
      Task { @MainActor in
        result(await Self.renewingSubscription())
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @MainActor
  private static func requestRefund(productId: String, result: @escaping FlutterResult) async {
    guard case .verified(let transaction)? = await Transaction.latest(for: productId) else {
      result(FlutterError(code: "no_transaction", message: "No transaction for \(productId)", details: nil))
      return
    }
    guard let scene = activeScene() else {
      result(FlutterError(code: "refund_failed", message: "No active window scene", details: nil))
      return
    }
    do {
      switch try await transaction.beginRefundRequest(in: scene) {
      case .success:
        result("requested")
      case .userCancelled:
        result("cancelled")
      @unknown default:
        result("cancelled")
      }
    } catch {
      result(FlutterError(code: "refund_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// `{productId, renewsAt}` (ISO 8601, UTC) for the first current
  /// subscription that will auto-renew, or nil.
  private static func renewingSubscription() async -> [String: String]? {
    for await entitlement in Transaction.currentEntitlements {
      guard case .verified(let transaction) = entitlement,
            transaction.productType == .autoRenewable,
            transaction.revocationDate == nil,
            let status = await transaction.subscriptionStatus,
            case .verified(let renewal) = status.renewalInfo,
            renewal.willAutoRenew,
            let renewsAt = renewal.renewalDate ?? transaction.expirationDate
      else { continue }
      return [
        "productId": transaction.productID,
        "renewsAt": ISO8601DateFormatter().string(from: renewsAt),
      ]
    }
    return nil
  }

  @MainActor
  private static func activeScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
  }
}
