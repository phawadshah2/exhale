import SwiftUI
import WidgetKit

/// One moment of the widgets: the snapshot and the queue, as of [date].
struct PresenceEntry: TimelineEntry {
  let date: Date
  let state: PresenceState
  /// A line of encouragement, for "Your why" when no reason is saved.
  let line: String?
}

/// Every widget reads the same timeline (see `PresenceTimeline`).
struct PresenceProvider: TimelineProvider {
  func placeholder(in context: Context) -> PresenceEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (PresenceEntry) -> Void) {
    completion(context.isPreview ? .sample : current().first ?? .sample)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PresenceEntry>) -> Void) {
    let now = Date()
    let snapshot = PresenceSnapshot.read()
    let queue = (try? QueueStore().read()) ?? []
    let timeline = PresenceTimeline.make(snapshot: snapshot, queue: queue, now: now)
    let entries = timeline.dates.map { entry(at: $0, snapshot: snapshot, queue: queue) }
    completion(Timeline(entries: entries, policy: .after(timeline.reload)))
  }

  private func current() -> [PresenceEntry] {
    let snapshot = PresenceSnapshot.read()
    let queue = (try? QueueStore().read()) ?? []
    return [entry(at: Date(), snapshot: snapshot, queue: queue)]
  }

  private func entry(at date: Date, snapshot: PresenceSnapshot?, queue: [QueuedLog])
    -> PresenceEntry
  {
    PresenceEntry(
      date: date,
      state: PresenceState.make(snapshot: snapshot, queue: queue, now: date),
      line: snapshot?.lastPair.counting)
  }
}

extension PresenceEntry {
  /// The gallery's example day: 4 of 8, next one in a little over an hour.
  static var sample: PresenceEntry {
    let now = Date()
    var state = PresenceState(kind: .live)
    state.count = 4
    state.limit = 8
    state.timer = PresenceState.Timer(
      next: now.addingTimeInterval(73 * 60), gapStart: now.addingTimeInterval(-60 * 60))
    state.stage = 3
    state.stageCount = 6
    state.daysToGo = 41
    state.reason = "To run with my kids without stopping."
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: now)
    let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? today
    var day = monthStart
    while day <= today {
      let n = calendar.component(.day, from: day)
      state.month[day] = n % 9 == 0 ? .over : n % 7 == 0 ? .at : .under
      day = calendar.date(byAdding: .day, value: 1, to: day)!
    }
    let weekday = (calendar.component(.weekday, from: today) + 5) % 7
    let monday = calendar.date(byAdding: .day, value: -weekday, to: today)!
    let counts = [7, 6, 8, 5, 6, 4, 0]
    state.week = (0..<7).map { offset in
      PresenceState.WeekDay(
        day: calendar.date(byAdding: .day, value: offset, to: monday)!,
        count: offset < weekday ? counts[offset] : offset == weekday ? 4 : 0,
        limit: 8)
    }
    return PresenceEntry(date: now, state: state, line: nil)
  }
}
