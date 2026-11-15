import Flutter
import XCTest

@testable import Runner

final class PresencePluginTests: XCTestCase {
  private var folder: URL!
  private var widgets: WidgetSpy!
  private var activities: ActivitySpy!
  private var plugin: PresencePlugin!

  override func setUpWithError() throws {
    try super.setUpWithError()
    folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("presence-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    widgets = WidgetSpy()
    activities = ActivitySpy()
    plugin = PresencePlugin(
      snapshotURL: folder.appendingPathComponent("snapshot.json"),
      queue: QueueStore(url: folder.appendingPathComponent("queue.json")),
      activities: activities,
      widgets: widgets
    )
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: folder)
    super.tearDown()
  }

  func testWriteSnapshotWritesTheFileAndReloads() throws {
    let json = #"{"version":1,"entitled":true}"#

    XCTAssertNil(call("writeSnapshot", json))

    let written = try String(
      contentsOf: folder.appendingPathComponent("snapshot.json"), encoding: .utf8)
    XCTAssertEqual(written, json)
    XCTAssertEqual(widgets.reloads, 1)
  }

  func testShowActivityTwiceUpdatesTheSameActivity() throws {
    XCTAssertNil(call("showActivity", activityJson(count: 3)))
    XCTAssertNil(call("showActivity", activityJson(count: 4)))

    XCTAssertEqual(activities.requested.count, 1)
    XCTAssertEqual(activities.updated.map(\.id), ["activity-1"])
    XCTAssertEqual(activities.running, ["activity-1"])

    let next = Date(timeIntervalSince1970: 1_800_000_000)
    let state = try XCTUnwrap(activities.updated.first?.state)
    XCTAssertEqual(state.next, next)
    XCTAssertEqual(state.gapStart, next.addingTimeInterval(-5_400))
    XCTAssertEqual(state.count, 4)
    XCTAssertEqual(state.limit, 8)
    XCTAssertEqual(state.daysToGo, 41)
    XCTAssertEqual(state.countingLine, "One breath at a time.")
    XCTAssertEqual(state.waitingLine, "You're on schedule.")
    XCTAssertEqual(activities.updated.first?.staleDate, next.addingTimeInterval(900))
  }

  func testEndActivityEndsAll() {
    activities.running = ["activity-a", "activity-b"]

    XCTAssertNil(call("endActivity", nil))

    XCTAssertEqual(activities.ended, ["activity-a", "activity-b"])
    XCTAssertEqual(activities.running, [])
  }

  func testReadQueueThenRemoveLeavesOtherIdsAndReloads() throws {
    let queue = QueueStore(url: folder.appendingPathComponent("queue.json"))
    try queue.append(QueuedLog(id: "a", loggedAt: Date(timeIntervalSince1970: 1_800_000_000)))
    try queue.append(QueuedLog(id: "b", loggedAt: Date(timeIntervalSince1970: 1_800_000_060)))

    let json = try XCTUnwrap(call("readQueue", nil) as? String)
    let entries = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: String]])
    XCTAssertEqual(entries.map { $0["id"] }, ["a", "b"])
    XCTAssertEqual(entries.first?["loggedAt"], "2027-01-15T08:00:00.000Z")

    XCTAssertNil(call("removeFromQueue", ["a"]))

    XCTAssertEqual(try queue.read().map(\.id), ["b"])
    XCTAssertEqual(widgets.reloads, 1)
  }

  func testUnknownMethodIsNotImplemented() {
    XCTAssertIdentical(call("drainQueue", nil) as? NSObject, FlutterMethodNotImplemented)
  }

  /// Calls [method] as the channel would and waits for its result.
  private func call(_ method: String, _ arguments: Any?) -> Any? {
    let done = expectation(description: method)
    var value: Any?
    plugin.handle(FlutterMethodCall(methodName: method, arguments: arguments)) { result in
      value = result
      done.fulfill()
    }
    wait(for: [done], timeout: 5)
    return value
  }

  private func activityJson(count: Int) -> String {
    """
    {"next":"2027-01-15T08:00:00.000Z","gapSeconds":5400,"count":\(count),"limit":8,\
    "daysToGo":41,"countingLine":"One breath at a time.",\
    "waitingLine":"You're on schedule.","staleAt":"2027-01-15T08:15:00.000Z"}
    """
  }
}

private final class WidgetSpy: WidgetReloading {
  private(set) var reloads = 0

  func reloadAllTimelines() { reloads += 1 }
}

private final class ActivitySpy: CountdownActivities {
  var running: [String] = []
  private(set) var requested: [CountdownAttributes.ContentState] = []
  private(set) var updated:
    [(id: String, state: CountdownAttributes.ContentState, staleDate: Date)] = []
  private(set) var ended: [String] = []

  var runningIds: [String] { running }

  func request(_ state: CountdownAttributes.ContentState, staleDate: Date) throws {
    requested.append(state)
    running.append("activity-\(requested.count)")
  }

  func update(id: String, to state: CountdownAttributes.ContentState, staleDate: Date) async {
    updated.append((id, state, staleDate))
  }

  func end(id: String) async {
    ended.append(id)
    running.removeAll { $0 == id }
  }
}
