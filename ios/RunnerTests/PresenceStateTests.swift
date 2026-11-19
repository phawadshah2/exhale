import XCTest

@testable import Runner

final class PresenceStateTests: XCTestCase {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
  }

  /// A snapshot as the app writes it: limit 6 every day, [counts] by day
  /// of November (absent after [today]).
  private func snapshot(
    today: Int = 14,
    lastDay: Int = 30,
    writtenAt: Date? = nil,
    entitled: Bool = true,
    quitDay: String = "2026-12-20",
    counts: [Int: Int] = [:],
    todayLogs: [Date] = []
  ) throws -> PresenceSnapshot {
    let days: [[String: Any]] = (1...lastDay).map { day in
      var entry: [String: Any] = [
        "day": String(format: "2026-11-%02d", day), "limit": 6, "stage": 2, "stageCount": 7,
      ]
      if day <= today { entry["count"] = counts[day] ?? 0 }
      return entry
    }
    let json: [String: Any] = [
      "version": 1,
      "writtenAt": Iso8601.string(writtenAt ?? at(today, 8)),
      "entitled": entitled,
      "resetHour": 4,
      "wakeMinute": 420,
      "awakeMinutes": 960,
      "habit": [
        "name": "Vaping", "kind": "vaping", "reason": "Stairs", "freeDayTitle": "Vape-free day",
      ],
      "quitDay": quitDay,
      "days": days,
      "todayLogs": todayLogs.map(Iso8601.string),
      "showLiveActivity": true,
      "lines": ["One", "Two", "Three"],
      "lastPair": ["counting": "One", "waiting": "Two"],
    ]
    return try JSONDecoder().decode(
      PresenceSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
  }

  private func state(
    _ snapshot: PresenceSnapshot?, queue: [QueuedLog] = [], now: Date
  ) -> PresenceState {
    PresenceState.make(snapshot: snapshot, queue: queue, now: now, calendar: calendar)
  }

  func testQueuedLogAddsToToday() throws {
    let result = state(
      try snapshot(counts: [14: 2], todayLogs: [at(14, 8), at(14, 9)]),
      queue: [QueuedLog(id: "a", loggedAt: at(14, 10))],
      now: at(14, 10, 5))

    XCTAssertEqual(result.kind, .live)
    XCTAssertEqual(result.count, 3)
    XCTAssertEqual(result.limit, 6)
    XCTAssertEqual(result.status, .under)
    XCTAssertNotNil(result.timer)
  }

  func testQueuedLogBeforeResetHourCountsYesterday() throws {
    // Sunday the 15th; the log at 02:30 belongs to Saturday the 14th.
    let result = state(
      try snapshot(today: 15, writtenAt: at(15, 8), counts: [14: 4, 15: 1]),
      queue: [QueuedLog(id: "a", loggedAt: at(15, 2, 30))],
      now: at(15, 9))

    XCTAssertEqual(result.count, 1)
    let saturday = try XCTUnwrap(result.week.first { $0.day == at(14, 0) })
    XCTAssertEqual(saturday.count, 5)
  }

  func testPastTheLastLimitDayIsStale() throws {
    XCTAssertEqual(state(try snapshot(lastDay: 20), now: at(21, 10)).kind, .stale)
    XCTAssertEqual(state(try snapshot(lastDay: 20), now: at(20, 23)).kind, .live)
  }

  func testMissingSnapshotIsStale() {
    XCTAssertEqual(state(nil, now: at(14, 10)).kind, .stale)
  }

  func testNotEntitledIsLocked() throws {
    XCTAssertEqual(state(try snapshot(entitled: false), now: at(14, 10)).kind, .locked)
  }

  func testQuitDayShowsDaysAtZero() throws {
    let result = state(try snapshot(quitDay: "2026-11-12"), now: at(14, 10))

    XCTAssertTrue(result.quitReached)
    XCTAssertEqual(result.daysAtZero, 3)
    XCTAssertEqual(result.daysToGo, 0)
  }

  func testBeforeTheQuitDayCountsDaysToGo() throws {
    let result = state(try snapshot(), now: at(14, 10))

    XCTAssertFalse(result.quitReached)
    XCTAssertEqual(result.daysAtZero, 0)
    XCTAssertEqual(result.daysToGo, 36)
    XCTAssertEqual(result.stage, 2)
    XCTAssertEqual(result.stageCount, 7)
    XCTAssertEqual(result.reason, "Stairs")
    XCTAssertEqual(result.freeDayTitle, "Vape-free day")
  }

  func testNoLogTodayHasNoTimer() throws {
    XCTAssertNil(state(try snapshot(), now: at(14, 10)).timer)
  }

  func testYesterdaysLogTimesAreNotToday() throws {
    let result = state(
      try snapshot(writtenAt: at(13, 22), counts: [14: 0], todayLogs: [at(13, 21)]),
      now: at(14, 10))

    XCTAssertNil(result.timer)
  }

  func testMonthAndWeekColourEachDay() throws {
    let result = state(try snapshot(counts: [2: 6, 3: 8, 14: 1]), now: at(14, 10))

    XCTAssertEqual(result.month.count, 14)
    XCTAssertEqual(result.month[at(1, 0)], .under)
    XCTAssertEqual(result.month[at(2, 0)], .at)
    XCTAssertEqual(result.month[at(3, 0)], .over)
    XCTAssertEqual(result.week.map(\.day), (9...15).map { at($0, 0) })
    XCTAssertEqual(result.week.last?.count, 0)
  }
}
