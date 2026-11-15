import XCTest

@testable import Runner

/// Runs `test/fixtures/pace_cases.json`, the cases the Dart tests also run,
/// against the Swift `PaceGuide`.
final class PaceGuideParityTests: XCTestCase {
  private struct Case: Decodable {
    struct Expect: Decodable {
      let next: String
      let gap: Double
      let pace: Double
      let bed: String
    }

    let name: String
    let now: String
    let day: String
    let resetHour: Int
    let wakeMinute: Int
    let awakeMinutes: Int
    let limit: Int
    let countToday: Int
    let logs: [String]
    let expect: Expect?
  }

  /// The fixture's times carry no zone; read them all in UTC.
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func local(_ text: String) throws -> Date {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    // Dart writes up to six fraction digits, beyond what DateFormatter reads.
    let parts = text.split(separator: ".", maxSplits: 1)
    let whole = try XCTUnwrap(formatter.date(from: String(parts[0])), text)
    guard parts.count == 2 else { return whole }
    return whole.addingTimeInterval(try XCTUnwrap(Double("0.\(parts[1])"), text))
  }

  func testEveryPaceCaseMatches() throws {
    let fixture = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("../../test/fixtures/pace_cases.json")
      .standardizedFileURL
    let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: fixture))
    XCTAssertEqual(cases.count, 14)

    for c in cases {
      let guide = PaceGuide.compute(
        now: try local(c.now),
        day: try XCTUnwrap(Day(c.day)),
        resetHour: c.resetHour,
        wakeMinute: c.wakeMinute,
        awakeMinutes: c.awakeMinutes,
        limit: c.limit,
        countToday: c.countToday,
        logs: try c.logs.map(local),
        calendar: calendar)

      guard let expect = c.expect else {
        XCTAssertNil(guide, c.name)
        continue
      }
      let found = try XCTUnwrap(guide, c.name)
      XCTAssertEqual(
        found.next.timeIntervalSince1970, try local(expect.next).timeIntervalSince1970,
        accuracy: 0.001, c.name)
      XCTAssertEqual(found.gap, expect.gap, accuracy: 0.001, c.name)
      XCTAssertEqual(found.pace, expect.pace, accuracy: 0.001, c.name)
      XCTAssertEqual(
        found.bed.timeIntervalSince1970, try local(expect.bed).timeIntervalSince1970,
        accuracy: 0.001, c.name)
    }
  }
}
