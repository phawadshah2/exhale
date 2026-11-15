import Foundation

/// What the widgets and Log one show: the snapshot with the queued logs
/// counted in, at one moment.
struct PresenceState {
  enum Kind: Equatable {
    /// Up to date: show the day.
    case live
    /// No access: "Exhale is locked", opens the app.
    case locked
    /// Missing, or past its last limit day: "Open Exhale to update".
    case stale
  }

  /// As Dart `LimitStatus`.
  enum Status: Equatable {
    case under, at, over

    static func of(count: Int, limit: Int) -> Status {
      if count > limit { return .over }
      if count == limit && limit > 0 { return .at }
      return .under
    }
  }

  struct Timer: Equatable {
    let next: Date
    /// When the gap began, for the draining bar and ring.
    let gapStart: Date
  }

  struct WeekDay: Equatable {
    let day: Date
    let count: Int
    let limit: Int
  }

  var kind: Kind
  var count = 0
  var limit = 0
  var status = Status.under
  var timer: Timer?
  var stage: Int?
  var stageCount = 0
  var daysToGo = 0
  /// "Day 3 at zero" from the quit day on; 0 before it.
  var daysAtZero = 0
  /// This month up to today, keyed by each day's local midnight.
  var month: [Date: Status] = [:]
  /// Monday to Sunday of this week; later days count 0.
  var week: [WeekDay] = []
  var reason: String?
  var freeDayTitle = ""
  var quitReached = false

  static func make(
    snapshot: PresenceSnapshot?,
    queue: [QueuedLog],
    now: Date,
    calendar: Calendar = .current
  ) -> PresenceState {
    guard let snapshot else { return PresenceState(kind: .stale) }
    if !snapshot.entitled { return PresenceState(kind: .locked) }

    let boundary = DayBoundary(resetHour: snapshot.resetHour, calendar: calendar)
    let today = boundary.day(of: now)
    let entries = Dictionary(snapshot.days.map { ($0.day, $0) }, uniquingKeysWith: { a, _ in a })
    guard let todayEntry = entries[today] else { return PresenceState(kind: .stale) }

    var queued: [Day: [Date]] = [:]
    for log in queue {
      queued[boundary.day(of: log.loggedAt), default: []].append(log.loggedAt)
    }
    func count(on day: Day) -> Int {
      guard day <= today, let entry = entries[day] else { return 0 }
      return (entry.count ?? 0) + (queued[day]?.count ?? 0)
    }

    var state = PresenceState(kind: .live)
    state.count = count(on: today)
    state.limit = todayEntry.limit
    state.status = Status.of(count: state.count, limit: state.limit)
    state.stage = todayEntry.stage
    state.stageCount = todayEntry.stageCount
    state.daysToGo = max(0, snapshot.quitDay.days(since: today))
    state.quitReached = today >= snapshot.quitDay
    state.daysAtZero = state.quitReached ? today.days(since: snapshot.quitDay) + 1 : 0
    state.reason = snapshot.habit.reason
    state.freeDayTitle = snapshot.habit.freeDayTitle

    // The snapshot's own log times belong to the day it was written.
    let written = boundary.day(of: snapshot.writtenAt) == today ? snapshot.todayLogs : []
    let todayLogs = (written + (queued[today] ?? [])).sorted()
    if let wake = snapshot.wakeMinute, let awake = snapshot.awakeMinutes, !todayLogs.isEmpty,
      let guide = PaceGuide.compute(
        now: now, day: today, resetHour: snapshot.resetHour, wakeMinute: wake,
        awakeMinutes: awake, limit: state.limit, countToday: state.count, logs: todayLogs,
        calendar: calendar)
    {
      state.timer = Timer(next: guide.next, gapStart: guide.next.addingTimeInterval(-guide.gap))
    }

    var day = Day(year: today.year, month: today.month, day: 1)
    while day <= today {
      if let entry = entries[day] {
        state.month[day.at(minute: 0, calendar: calendar)] =
          Status.of(count: count(on: day), limit: entry.limit)
      }
      day = day.adding(days: 1)
    }

    let monday = today.adding(days: 1 - today.weekday)
    state.week = (0..<7).map { offset in
      let day = monday.adding(days: offset)
      return WeekDay(
        day: day.at(minute: 0, calendar: calendar),
        count: count(on: day),
        limit: entries[day]?.limit ?? 0)
    }
    return state
  }
}
