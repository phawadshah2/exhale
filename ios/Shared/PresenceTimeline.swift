import Foundation

/// When the widgets redraw: now, when the next one is due, 15 min past it
/// (the quiet point) and the day reset. Locked and stale show one entry until
/// the reset; every write from the app reloads them sooner.
struct PresenceTimeline: Equatable {
  /// Oldest first; the first is always now.
  let dates: [Date]
  /// When WidgetKit asks for the next timeline.
  let reload: Date

  static let quietAfter: TimeInterval = 15 * 60

  /// The app's default, for when there is no snapshot to read it from.
  static let defaultResetHour = 4

  static func make(
    snapshot: PresenceSnapshot?,
    queue: [QueuedLog],
    now: Date,
    calendar: Calendar = .current
  ) -> PresenceTimeline {
    let boundary = DayBoundary(
      resetHour: snapshot?.resetHour ?? defaultResetHour, calendar: calendar)
    let reset = boundary.end(of: boundary.day(of: now))
    let state = PresenceState.make(snapshot: snapshot, queue: queue, now: now, calendar: calendar)
    guard state.kind == .live else { return PresenceTimeline(dates: [now], reload: reset) }

    var dates = [now]
    if let next = state.timer?.next {
      dates += [next, next.addingTimeInterval(quietAfter)].filter { $0 > now && $0 < reset }
    }
    dates.append(reset)
    return PresenceTimeline(dates: dates, reload: reset)
  }
}
