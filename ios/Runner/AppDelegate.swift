import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeUiPlugin") {
      NativeUiPlugin.register(with: registrar)
    }
  }
}

/// System UI Flutter can't draw itself: iOS alerts (Liquid Glass on iOS 26+)
/// and the Reduce Transparency accessibility setting.
final class NativeUiPlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reduceTransparencyChanged),
      name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil
    )
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "exhale/native_ui",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(NativeUiPlugin(channel: channel), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "reduceTransparency":
      result(UIAccessibility.isReduceTransparencyEnabled)
    case "showAlert":
      showAlert(call.arguments as? [String: Any] ?? [:], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @objc private func reduceTransparencyChanged() {
    channel.invokeMethod(
      "reduceTransparencyChanged",
      arguments: UIAccessibility.isReduceTransparencyEnabled
    )
  }

  /// Returns the index of the tapped action.
  private func showAlert(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_view", message: "No view to present on", details: nil))
      return
    }
    let alert = UIAlertController(
      title: args["title"] as? String,
      message: args["message"] as? String,
      preferredStyle: .alert
    )
    let actions = args["actions"] as? [[String: Any]] ?? []
    for (index, action) in actions.enumerated() {
      let style: UIAlertAction.Style = switch action["style"] as? String {
      case "cancel": .cancel
      case "destructive": .destructive
      default: .default
      }
      alert.addAction(
        UIAlertAction(title: action["label"] as? String, style: style) { _ in result(index) }
      )
    }
    presenter.present(alert, animated: true)
  }

  private func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    var top = scene?.keyWindow?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
