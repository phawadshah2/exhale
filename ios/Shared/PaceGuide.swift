import Foundation

/// The Dart `PaceGuide` in Swift, line for line, so the widgets and Log one
/// show the countdown the app shows. `test/fixtures/pace_cases.json` keeps the
/// two in step. Times run in whole microseconds, as Dart's `Duration`.
struct PaceGuide: Equatable {
  let next: Date
  /// From the last log (or wake) to [next].
  let gap: TimeInterval
  let pace: TimeInterval
  /// The end of the waking window, cut at the day's end.
  let bed: Date

  /// Nil when there is nothing to pace: at or over the limit, on a limit of
  /// 0, or before wake. Past bed it keeps running until the day resets.
  /// [logs] are the day's logs, oldest first.
  static func compute(
    now: Date,
    day: Day,
    resetHour: Int,
    wakeMinute: Int,
    awakeMinutes: Int,
    limit: Int,
    countToday: Int,
    logs: [Date],
    calendar: Calendar = .current
  ) -> PaceGuide? {
    if limit <= 0 || countToday >= limit { return nil }

    let boundary = DayBoundary(resetHour: resetHour, calendar: calendar)
    let wake = max(micros(day.at(minute: wakeMinute, calendar: calendar)), micros(boundary.start(of: day)))
    let end = micros(boundary.end(of: day))
    let bed = min(micros(day.at(minute: wakeMinute + awakeMinutes, calendar: calendar)), end)
    let nowMicros = micros(now)
    if nowMicros < wake || nowMicros >= end { return nil }

    // A guide to cutting down never suggests going faster than the even rate.
    let even = (bed - wake) / Int64(limit)
    func gap(_ from: Int64, _ count: Int) -> Int64 {
      let share = (bed - from) / Int64(limit - count)
      return share > even ? share : even
    }

    // Replayed from the day's logs, so it holds still until the next one.
    // Time left on the timer when a log comes carries into the next gap; the
    // first log has no timer before it.
    var count = countToday - logs.count
    var anchor = wake
    var due = wake + gap(wake, count)
    for (index, log) in logs.map(micros).enumerated() {
      count += 1
      let left = index == 0 || log < wake ? 0 : due - log
      anchor = max(log, wake)
      due = anchor + gap(anchor, count)
      if left > 0 { due += left }
    }

    return PaceGuide(
      next: date(due),
      gap: seconds(due - anchor),
      pace: seconds(gap(max(nowMicros, wake), countToday)),
      bed: date(bed)
    )
  }

  private static func micros(_ date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 * 1_000_000).rounded())
  }

  private static func date(_ micros: Int64) -> Date {
    Date(timeIntervalSince1970: Double(micros) / 1_000_000)
  }

  private static func seconds(_ micros: Int64) -> TimeInterval { Double(micros) / 1_000_000 }
}
