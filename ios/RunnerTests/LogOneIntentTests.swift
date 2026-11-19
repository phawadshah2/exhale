import XCTest

@testable import Runner

final class LogOneIntentTests: XCTestCase {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()
  private let locale = Locale(identifier: "en_US")

  private var folder: URL!
  private var queue: QueueStore!
  private var widgets: ReloadSpy!
  private var activities: CountdownSpy!
  private var notified = 0

  override func setUpWithError() throws {
    try super.setUpWithError()
    folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("log-one-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    queue = QueueStore(url: folder.appendingPathComponent("queue.json"))
    widgets = ReloadSpy()
    activities = CountdownSpy()
    notified = 0
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: folder)
    super.tearDown()
  }

  private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
  }

  private func time(_ date: Date) -> String {
    date.formatted(
      Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar,
        timeZone: calendar.timeZone))
  }

  /// Limit 8 every day of November up to [lastDay]; [logs] today, the 14th.
  private func snapshot(
    lastDay: Int = 30, entitled: Bool = true, logs: [Date] = []
  ) throws -> PresenceSnapshot {
    let days: [[String: Any]] = (1...lastDay).map { day in
      var entry: [String: Any] = [
        "day": String(format: "2026-11-%02d", day), "limit": 8, "stage": 2, "stageCount": 7,
      ]
      if day <= 14 { entry["count"] = day == 14 ? logs.count : 0 }
      return entry
    }
    let json: [String: Any] = [
      "version": 1,
      "writtenAt": Iso8601.string(at(14, 8)),
      "entitled": entitled,
      "resetHour": 4,
      "wakeMinute": 420,
      "awakeMinutes": 960,
      "habit": [
        "name": "Vaping", "kind": "vaping", "reason": "Stairs", "freeDayTitle": "Vape-free day",
      ],
      "quitDay": "2026-12-20",
      "days": days,
      "todayLogs": logs.map(Iso8601.string),
      "showLiveActivity": true,
      "lines": ["One", "Two", "Three", "Four"],
      "lastPair": ["counting": "One", "waiting": "Two"],
    ]
    return try JSONDecoder().decode(
      PresenceSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
  }

  private func logOne(_ snapshot: PresenceSnapshot?) -> LogOne {
    LogOne(
      readSnapshot: { snapshot },
      queue: queue,
      activities: activities,
      widgets: widgets,
      notifyApp: { self.notified += 1 },
      calendar: calendar,
      locale: locale)
  }

  func testAppendsOneLogAndReplies() async throws {
    let snapshot = try snapshot(logs: [at(14, 8), at(14, 9), at(14, 10), at(14, 11)])
    let now = at(14, 12)

    let outcome = try await logOne(snapshot).run(now: now)

    let logged = try queue.read()
    XCTAssertEqual(logged.map(\.loggedAt), [now])
    let next = try XCTUnwrap(
      PresenceState.make(snapshot: snapshot, queue: logged, now: now, calendar: calendar).timer
    ).next
    XCTAssertEqual(
      outcome, .logged("Logged · 5 of 8 today. Next one on schedule at \(time(next))."))
    XCTAssertEqual(notified, 1)
    XCTAssertEqual(widgets.reloads, 1)
    let started = try XCTUnwrap(activities.requested.first)
    XCTAssertEqual(activities.requested.count, 1)
    XCTAssertEqual(started.state.next, next)
    XCTAssertEqual(started.state.count, 5)
    XCTAssertEqual(started.state.limit, 8)
    XCTAssertEqual(started.staleDate, next.addingTimeInterval(15 * 60))
    XCTAssertFalse(["One", "Two"].contains(started.state.countingLine))
    XCTAssertFalse(["One", "Two"].contains(started.state.waitingLine))
  }

  func testOverTheLimitStillLogs() async throws {
    activities.running = ["running"]
    let logs = (0..<8).map { at(14, 8 + $0) }

    let outcome = try await logOne(try snapshot(logs: logs)).run(now: at(14, 17))

    XCTAssertEqual(outcome, .logged("Logged · 9 of 8 today."))
    XCTAssertEqual(try queue.read().count, 1)
    XCTAssertEqual(activities.requested.count, 0)
    XCTAssertEqual(activities.ended, ["running"])
  }

  func testPickNeverRepeatsLastPair() {
    var random = SeededRandom(seed: 7)
    let lines = ["One", "Two", "Three", "Four", "Five"]
    let last = PresenceSnapshot.LinePair(counting: "One", waiting: "Two")
    for _ in 0..<200 {
      let pair = LinePicker.pick(lines: lines, last: last, using: &random)
      XCTAssertNotEqual(pair.counting, pair.waiting)
      XCTAssertFalse(["One", "Two"].contains(pair.counting))
      XCTAssertFalse(["One", "Two"].contains(pair.waiting))
    }
  }

  func testLockedWritesNothingAndOpensTheApp() async throws {
    let outcome = try await logOne(try snapshot(entitled: false)).run(now: at(14, 12))

    XCTAssertEqual(outcome, .locked)
    XCTAssertEqual(try queue.read(), [])
    XCTAssertEqual(notified, 0)
    XCTAssertEqual(widgets.reloads, 0)
    XCTAssertEqual(activities.requested.count, 0)
  }

  func testStaleWritesNothingAndOpensTheApp() async throws {
    let outcome = try await logOne(try snapshot(lastDay: 10)).run(now: at(14, 12))
    let missing = try await logOne(nil).run(now: at(14, 12))

    XCTAssertEqual(outcome, .stale)
    XCTAssertEqual(missing, .stale)
    XCTAssertEqual(try queue.read(), [])
    XCTAssertEqual(notified, 0)
    XCTAssertEqual(widgets.reloads, 0)
  }
}

private final class ReloadSpy: WidgetReloading {
  private(set) var reloads = 0

  func reloadAllTimelines() { reloads += 1 }
}

private final class CountdownSpy: CountdownActivities {
  var running: [String] = []
  private(set) var requested: [(state: CountdownAttributes.ContentState, staleDate: Date)] = []
  private(set) var ended: [String] = []

  var runningIds: [String] { running }

  func request(_ state: CountdownAttributes.ContentState, staleDate: Date) throws {
    requested.append((state, staleDate))
    running.append("activity-\(requested.count)")
  }

  func update(id: String, to state: CountdownAttributes.ContentState, staleDate: Date) async {}

  func end(id: String) async {
    ended.append(id)
    running.removeAll { $0 == id }
  }
}

/// SplitMix64, so the picker test is repeatable.
private struct SeededRandom: RandomNumberGenerator {
  var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
