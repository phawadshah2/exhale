import Foundation

/// What the app writes to the App Group (Dart `PresenceSnapshot`, version 1).
struct PresenceSnapshot: Decodable {
  struct Habit: Decodable {
    let name: String
    let kind: String
    let reason: String?
    let freeDayTitle: String
  }

  struct DayEntry: Decodable {
    let day: Day
    let limit: Int
    let stage: Int?
    let stageCount: Int
    /// Absent on future days.
    let count: Int?

    private enum CodingKeys: String, CodingKey { case day, limit, stage, stageCount, count }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let text = try container.decode(String.self, forKey: .day)
      guard let day = Day(text) else {
        throw DecodingError.dataCorruptedError(
          forKey: .day, in: container, debugDescription: "Not yyyy-mm-dd: \(text)")
      }
      self.day = day
      limit = try container.decode(Int.self, forKey: .limit)
      stage = try container.decodeIfPresent(Int.self, forKey: .stage)
      stageCount = try container.decode(Int.self, forKey: .stageCount)
      count = try container.decodeIfPresent(Int.self, forKey: .count)
    }
  }

  struct LinePair: Decodable, Equatable {
    let counting: String
    let waiting: String
  }

  let version: Int
  let writtenAt: Date
  let entitled: Bool
  let resetHour: Int
  let wakeMinute: Int?
  let awakeMinutes: Int?
  let habit: Habit
  let quitDay: Day
  let days: [DayEntry]
  let todayLogs: [Date]
  let showLiveActivity: Bool
  let lines: [String]
  let lastPair: LinePair

  private enum CodingKeys: String, CodingKey {
    case version, writtenAt, entitled, resetHour, wakeMinute, awakeMinutes, habit, quitDay
    case days, todayLogs, showLiveActivity, lines, lastPair
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    func date(_ text: String, _ key: CodingKeys) throws -> Date {
      guard let date = Iso8601.date(text) else {
        throw DecodingError.dataCorruptedError(
          forKey: key, in: container, debugDescription: "Not ISO 8601: \(text)")
      }
      return date
    }
    version = try container.decode(Int.self, forKey: .version)
    writtenAt = try date(container.decode(String.self, forKey: .writtenAt), .writtenAt)
    entitled = try container.decode(Bool.self, forKey: .entitled)
    resetHour = try container.decode(Int.self, forKey: .resetHour)
    wakeMinute = try container.decodeIfPresent(Int.self, forKey: .wakeMinute)
    awakeMinutes = try container.decodeIfPresent(Int.self, forKey: .awakeMinutes)
    habit = try container.decode(Habit.self, forKey: .habit)
    let quit = try container.decode(String.self, forKey: .quitDay)
    guard let quitDay = Day(quit) else {
      throw DecodingError.dataCorruptedError(
        forKey: .quitDay, in: container, debugDescription: "Not yyyy-mm-dd: \(quit)")
    }
    self.quitDay = quitDay
    days = try container.decode([DayEntry].self, forKey: .days)
    todayLogs = try container.decode([String].self, forKey: .todayLogs).map {
      try date($0, .todayLogs)
    }
    showLiveActivity = try container.decode(Bool.self, forKey: .showLiveActivity)
    lines = try container.decode([String].self, forKey: .lines)
    lastPair = try container.decode(LinePair.self, forKey: .lastPair)
  }

  /// The snapshot at [url]; nil when it is missing or unreadable.
  static func read(from url: URL = AppGroup.snapshotURL) -> PresenceSnapshot? {
    var result: PresenceSnapshot?
    var error: NSError?
    NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &error) { url in
      guard let data = try? Data(contentsOf: url) else { return }
      result = try? JSONDecoder().decode(PresenceSnapshot.self, from: data)
    }
    return result
  }
}
