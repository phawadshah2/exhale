import XCTest

@testable import Runner

final class PresenceProviderTests: XCTestCase {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
  }

  /// Limit 6 every day to [lastDay], reset at 4 AM, awake 7 AM to 11 PM.
  private func snapshot(
    lastDay: Int = 30,
    entitled: Bool = true,
    counts: [Int: Int] = [:],
    todayLogs: [Date] = []
  ) throws -> PresenceSnapshot {
    let days: [[String: Any]] = (1...lastDay).map { day in
      var entry: [String: Any] = [
        "day": String(format: "2026-11-%02d", day), "limit": 6, "stage": 2, "stageCount": 7,
      ]
      if day <= 14 { entry["count"] = counts[day] ?? 0 }
      return entry
    }
    let json: [String: Any] = [
      "version": 1,
      "writtenAt": Iso8601.string(at(14, 9, 1)),
      "entitled": entitled,
      "resetHour": 4,
      "wakeMinute": 420,
      "awakeMinutes": 960,
      "habit": [
        "name": "Vaping", "kind": "vaping", "reason": "Stairs", "freeDayTitle": "Vape-free day",
      ],
      "quitDay": "2026-12-20",
      "days": days,
      "todayLogs": todayLogs.map(Iso8601.string),
      "showLiveActivity": true,
      "lines": ["One", "Two", "Three"],
      "lastPair": ["counting": "One", "waiting": "Two"],
    ]
    return try JSONDecoder().decode(
      PresenceSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
  }

  private func timeline(_ snapshot: PresenceSnapshot?, now: Date) -> PresenceTimeline {
    PresenceTimeline.make(snapshot: snapshot, queue: [], now: now, calendar: calendar)
  }

  func testEntriesAtDueStaleAndReset() throws {
    let snap = try snapshot(counts: [14: 2], todayLogs: [at(14, 8), at(14, 9)])
    let now = at(14, 9, 5)
    let next = try XCTUnwrap(
      PresenceState.make(snapshot: snap, queue: [], now: now, calendar: calendar).timer?.next)
    let reset = at(15, 4)

    let steps = stride(from: 300.0, to: next.timeIntervalSince(now), by: 300).map {
      now.addingTimeInterval($0)
    }
    XCTAssertFalse(steps.isEmpty)

    let counting = timeline(snap, now: now)
    XCTAssertEqual(
      counting.dates, [now] + steps + [next, next.addingTimeInterval(15 * 60), reset])
    XCTAssertEqual(counting.reload, reset)

    let pastDue = next.addingTimeInterval(5 * 60)
    XCTAssertEqual(
      timeline(snap, now: pastDue).dates, [pastDue, next.addingTimeInterval(15 * 60), reset])

    let quiet = next.addingTimeInterval(20 * 60)
    XCTAssertEqual(timeline(snap, now: quiet).dates, [quiet, reset])
  }

  func testNoTimerHasNoDueEntries() throws {
    let now = at(14, 10)
    let result = timeline(try snapshot(), now: now)

    XCTAssertEqual(result.dates, [now, at(15, 4)])
    XCTAssertEqual(result.reload, at(15, 4))
  }

  func testLockedAndStaleHaveOneEntryUntilReset() throws {
    let now = at(14, 10)

    let locked = timeline(try snapshot(entitled: false), now: now)
    XCTAssertEqual(locked.dates, [now])
    XCTAssertEqual(locked.reload, at(15, 4))

    let missing = timeline(nil, now: now)
    XCTAssertEqual(missing.dates, [now])
    XCTAssertEqual(missing.reload, at(15, 4))

    let late = at(21, 10)
    let stale = timeline(try snapshot(lastDay: 20), now: late)
    XCTAssertEqual(stale.dates, [late])
    XCTAssertEqual(stale.reload, at(22, 4))
  }
}
