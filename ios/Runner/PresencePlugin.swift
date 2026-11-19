import ActivityKit
import Flutter
import Foundation
import WidgetKit

protocol WidgetReloading {
  func reloadAllTimelines()
}

struct SystemWidgets: WidgetReloading {
  func reloadAllTimelines() { WidgetCenter.shared.reloadAllTimelines() }
}

/// The countdown activities ActivityKit is running for the app.
protocol CountdownActivities {
  var runningIds: [String] { get }
  func request(_ state: CountdownAttributes.ContentState, staleDate: Date) throws
  func update(id: String, to state: CountdownAttributes.ContentState, staleDate: Date) async
  func end(id: String) async
}

extension CountdownActivities {
  /// Updates the running activity, or starts one; extras are ended.
  func show(_ state: CountdownAttributes.ContentState, staleDate: Date) async throws {
    let running = runningIds
    guard let current = running.first else {
      try request(state, staleDate: staleDate)
      return
    }
    await update(id: current, to: state, staleDate: staleDate)
    for id in running.dropFirst() { await end(id: id) }
  }

  func endAll() async {
    for id in runningIds { await end(id: id) }
  }
}

struct SystemActivities: CountdownActivities {
  var runningIds: [String] { running.map(\.id) }

  func request(_ state: CountdownAttributes.ContentState, staleDate: Date) throws {
    _ = try Activity.request(
      attributes: CountdownAttributes(),
      content: ActivityContent(state: state, staleDate: staleDate),
      pushType: nil
    )
  }

  func update(id: String, to state: CountdownAttributes.ContentState, staleDate: Date) async {
    await running.first { $0.id == id }?
      .update(ActivityContent(state: state, staleDate: staleDate))
  }

  func end(id: String) async {
    await running.first { $0.id == id }?.end(nil, dismissalPolicy: .immediate)
  }

  private var running: [Activity<CountdownAttributes>] {
    Activity<CountdownAttributes>.activities.filter {
      $0.activityState == .active || $0.activityState == .stale
    }
  }
}

/// The `exhale/presence` channel: the snapshot and queue in the App Group,
/// the one countdown Live Activity, and `queueChanged` when Log one adds to
/// the queue while the app runs.
final class PresencePlugin: NSObject, FlutterPlugin {
  private let snapshotURL: URL
  private let queue: QueueStore
  private let activities: CountdownActivities
  private let widgets: WidgetReloading
  private var channel: FlutterMethodChannel?

  init(
    snapshotURL: URL = AppGroup.snapshotURL,
    queue: QueueStore = QueueStore(),
    activities: CountdownActivities = SystemActivities(),
    widgets: WidgetReloading = SystemWidgets()
  ) {
    self.snapshotURL = snapshotURL
    self.queue = queue
    self.activities = activities
    self.widgets = widgets
    super.init()
  }

  deinit {
    if channel != nil {
      CFNotificationCenterRemoveEveryObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque())
    }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "exhale/presence",
      binaryMessenger: registrar.messenger()
    )
    let plugin = PresencePlugin()
    plugin.channel = channel
    plugin.observeQueue()
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "writeSnapshot":
      guard let json = call.arguments as? String else { return result(badArguments(call)) }
      result(attempt { try self.writeSnapshot(json) })
    case "readQueue":
      do {
        result(String(decoding: try JSONEncoder().encode(queue.read()), as: UTF8.self))
      } catch {
        result(failure(error))
      }
    case "removeFromQueue":
      guard let ids = call.arguments as? [String] else { return result(badArguments(call)) }
      result(attempt { try self.removeFromQueue(Set(ids)) })
    case "showActivity":
      guard let json = call.arguments as? String, let request = ActivityRequest(json: json)
      else { return result(badArguments(call)) }
      Task { @MainActor in
        do {
          try await self.showActivity(request)
          result(nil)
        } catch {
          result(self.failure(error))
        }
      }
    case "endActivity":
      Task { @MainActor in
        await self.endActivity()
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func writeSnapshot(_ json: String) throws {
    try Data(json.utf8).write(to: snapshotURL, options: .atomic)
    widgets.reloadAllTimelines()
  }

  /// Reloads too, so a drained log stops counting twice in the widgets.
  private func removeFromQueue(_ ids: Set<String>) throws {
    try queue.remove(ids: ids)
    widgets.reloadAllTimelines()
  }

  private func showActivity(_ request: ActivityRequest) async throws {
    try await activities.show(request.state, staleDate: request.staleAt)
  }

  private func endActivity() async {
    await activities.endAll()
  }

  private func observeQueue() {
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      Unmanaged.passUnretained(self).toOpaque(),
      { _, observer, _, _, _ in
        guard let observer else { return }
        let plugin = Unmanaged<PresencePlugin>.fromOpaque(observer).takeUnretainedValue()
        DispatchQueue.main.async { plugin.channel?.invokeMethod("queueChanged", arguments: nil) }
      },
      AppGroup.queueChangedNotification as CFString,
      nil,
      .deliverImmediately
    )
  }

  private func attempt(_ action: () throws -> Void) -> Any? {
    do {
      try action()
      return nil
    } catch {
      return failure(error)
    }
  }

  private func failure(_ error: Error) -> FlutterError {
    FlutterError(code: "presence", message: error.localizedDescription, details: nil)
  }

  private func badArguments(_ call: FlutterMethodCall) -> FlutterError {
    FlutterError(code: "bad_arguments", message: "Bad arguments for \(call.method)", details: nil)
  }
}

/// `showActivity`'s JSON, as the app's `ActivityContent.toJson`.
struct ActivityRequest {
  let state: CountdownAttributes.ContentState
  let staleAt: Date

  init?(json: String) {
    guard
      let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
      let next = (object["next"] as? String).flatMap(Iso8601.date),
      let staleAt = (object["staleAt"] as? String).flatMap(Iso8601.date),
      let gapSeconds = object["gapSeconds"] as? Int,
      let count = object["count"] as? Int,
      let limit = object["limit"] as? Int,
      let daysToGo = object["daysToGo"] as? Int,
      let countingLine = object["countingLine"] as? String,
      let waitingLine = object["waitingLine"] as? String
    else { return nil }
    state = CountdownAttributes.ContentState(
      next: next,
      gapStart: next.addingTimeInterval(-Double(gapSeconds)),
      count: count,
      limit: limit,
      daysToGo: daysToGo,
      countingLine: countingLine,
      waitingLine: waitingLine
    )
    self.staleAt = staleAt
  }
}
