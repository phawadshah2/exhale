import Foundation

/// The App Group the app, the widgets and Log one share.
enum AppGroup {
  static let id = "group.com.phawadshah.exhale"

  /// Posted (Darwin) when Log one adds to the queue.
  static let queueChangedNotification = "com.phawadshah.exhale.queueChanged"

  static var containerURL: URL {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
      ?? FileManager.default.temporaryDirectory
  }

  static var snapshotURL: URL { containerURL.appendingPathComponent("snapshot.json") }

  static var queueURL: URL { containerURL.appendingPathComponent("queue.json") }
}

/// A calendar date with no time of day, as the app's `LogicalDay`.
struct Day: Hashable, Comparable, CustomStringConvertible {
  let year: Int
  let month: Int
  let day: Int

  init(year: Int, month: Int, day: Int) {
    self.year = year
    self.month = month
    self.day = day
  }

  /// Parses `yyyy-mm-dd`.
  init?(_ text: String) {
    let parts = text.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    self.init(year: parts[0], month: parts[1], day: parts[2])
  }

  private static let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private var utcDate: Date {
    Day.utc.date(from: DateComponents(year: year, month: month, day: day))!
  }

  func adding(days: Int) -> Day {
    let date = Day.utc.date(byAdding: .day, value: days, to: utcDate)!
    let parts = Day.utc.dateComponents([.year, .month, .day], from: date)
    return Day(year: parts.year!, month: parts.month!, day: parts.day!)
  }

  /// Whole days from [other] to this day; negative if this is earlier.
  func days(since other: Day) -> Int {
    Day.utc.dateComponents([.day], from: other.utcDate, to: utcDate).day!
  }

  /// 1 is Monday, 7 is Sunday.
  var weekday: Int {
    let sundayFirst = Day.utc.component(.weekday, from: utcDate)
    return (sundayFirst + 5) % 7 + 1
  }

  /// Local wall-clock time [minute] minutes after this day's midnight; the
  /// minutes may run past midnight into the next date.
  func at(minute: Int, calendar: Calendar) -> Date {
    calendar.date(
      from: DateComponents(year: year, month: month, day: day, hour: 0, minute: minute))!
  }

  static func < (lhs: Day, rhs: Day) -> Bool {
    (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
  }

  var description: String {
    String(format: "%04d-%02d-%02d", year, month, day)
  }
}

/// Which day a moment belongs to under a reset hour, as `DayBoundary`.
struct DayBoundary {
  let resetHour: Int
  var calendar: Calendar = .current

  func day(of instant: Date) -> Day {
    let parts = calendar.dateComponents([.year, .month, .day, .hour], from: instant)
    let date = Day(year: parts.year!, month: parts.month!, day: parts.day!)
    return parts.hour! < resetHour ? date.adding(days: -1) : date
  }

  func start(of day: Day) -> Date { day.at(minute: resetHour * 60, calendar: calendar) }

  func end(of day: Day) -> Date { start(of: day.adding(days: 1)) }
}

/// Dart writes UTC ISO 8601 with up to six fraction digits.
enum Iso8601 {
  private static let plain: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  private static let fractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static func date(_ text: String) -> Date? {
    guard let dot = text.firstIndex(of: ".") else { return plain.date(from: text) }
    let zone = text[dot...].firstIndex { $0 == "Z" || $0 == "+" || $0 == "-" } ?? text.endIndex
    guard let base = plain.date(from: String(text[..<dot]) + String(text[zone...])),
      let fraction = Double("0" + text[dot..<zone])
    else { return nil }
    return base.addingTimeInterval(fraction)
  }

  static func string(_ date: Date) -> String { fractional.string(from: date) }
}
