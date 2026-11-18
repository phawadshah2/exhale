import AppIntents
import Foundation

/// "Log one": Siri, Shortcuts, the Action Button, the controls and the + on
/// the widgets. A Live Activity intent, so it always runs in the app's
/// process; the widget extension only needs the type.
struct LogOneIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Log one"
  static let description = IntentDescription("Logs one now, without opening Exhale.")
  static let openAppWhenRun = false

  init() {}

  #if WIDGET_EXTENSION
    func perform() async throws -> some IntentResult & ProvidesDialog {
      .result(dialog: "")
    }
  #else
    func perform() async throws -> some IntentResult & ProvidesDialog {
      switch try await LogOne.system.run(now: Date()) {
      case .logged(let reply):
        return .result(dialog: "\(reply)")
      case .locked:
        throw needsToContinueInForegroundError("Exhale is locked.")
      case .stale:
        throw needsToContinueInForegroundError("Open Exhale to update.")
      }
    }
  #endif
}

#if !WIDGET_EXTENSION
  extension LogOneIntent: ForegroundContinuableIntent {}

  /// What Log one does: queue the log, tell the app and the widgets, start
  /// or update the countdown, and say where the day stands.
  struct LogOne {
    enum Outcome: Equatable {
      case logged(String)
      /// Not entitled: nothing written, the app opens.
      case locked
      /// No snapshot covers today: nothing written, the app opens.
      case stale
    }

    var readSnapshot: () -> PresenceSnapshot?
    var queue: QueueStore
    var activities: CountdownActivities
    var widgets: WidgetReloading
    var notifyApp: () -> Void
    var calendar: Calendar = .current
    var locale: Locale = .current
    var pickLines: ([String], PresenceSnapshot.LinePair) -> PresenceSnapshot.LinePair = {
      LinePicker.pick(lines: $0, last: $1)
    }

    static var system: LogOne {
      LogOne(
        readSnapshot: { PresenceSnapshot.read() },
        queue: QueueStore(),
        activities: SystemActivities(),
        widgets: SystemWidgets(),
        notifyApp: {
          CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(AppGroup.queueChangedNotification as CFString),
            nil, nil, true)
        })
    }

    func run(now: Date) async throws -> Outcome {
      let snapshot = readSnapshot()
      let before = PresenceState.make(
        snapshot: snapshot, queue: try queue.read(), now: now, calendar: calendar)
      guard let snapshot, before.kind == .live else {
        return before.kind == .locked ? .locked : .stale
      }

      try queue.append(QueuedLog(loggedAt: now))
      notifyApp()
      widgets.reloadAllTimelines()

      let state = PresenceState.make(
        snapshot: snapshot, queue: try queue.read(), now: now, calendar: calendar)
      await showCountdown(state, snapshot: snapshot, now: now)

      let logged = "Logged · \(state.count) of \(state.limit) today."
      guard state.status == .under, let timer = state.timer else { return .logged(logged) }
      return .logged("\(logged) Next one on schedule at \(time(timer.next)).")
    }

    /// Logging never fails because of the activity (iOS's switch may be off).
    private func showCountdown(_ state: PresenceState, snapshot: PresenceSnapshot, now: Date)
      async
    {
      guard snapshot.showLiveActivity, let timer = state.timer,
        now < timer.next.addingTimeInterval(PresenceTimeline.quietAfter)
      else {
        await activities.endAll()
        return
      }
      let pair = pickLines(snapshot.lines, snapshot.lastPair)
      let content = CountdownAttributes.ContentState(
        next: timer.next,
        gapStart: timer.gapStart,
        count: state.count,
        limit: state.limit,
        daysToGo: state.daysToGo,
        countingLine: pair.counting,
        waitingLine: pair.waiting)
      try? await activities.show(
        content, staleDate: timer.next.addingTimeInterval(PresenceTimeline.quietAfter))
    }

    private func time(_ date: Date) -> String {
      date.formatted(
        Date.FormatStyle(
          date: .omitted, time: .shortened, locale: locale, calendar: calendar,
          timeZone: calendar.timeZone))
    }
  }
#endif
