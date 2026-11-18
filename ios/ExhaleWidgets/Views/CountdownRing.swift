import SwiftUI
import WidgetKit

/// The thin ring around today's ring that drains to the next one on
/// schedule; iOS animates it with no code running.
struct CountdownRing: View {
  let timer: PresenceState.Timer
  let size: CGFloat

  var body: some View {
    ProgressView(timerInterval: timer.gapStart...timer.next, countsDown: true) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    }
    .progressViewStyle(.circular)
    .tint(.primary)
    .frame(width: size, height: size)
    .widgetAccentable()
    .accessibilityHidden(true)
  }
}

/// Today's ring, with the countdown ring around it while the timer runs.
struct TodayRing: View {
  let state: PresenceState
  let date: Date
  let size: CGFloat

  var body: some View {
    ZStack {
      if let timer = state.timer, timer.next > date {
        CountdownRing(timer: timer, size: size)
      }
      // The system ring is about 5 pt wide; keep today's ring clear of it.
      RingView(state: state, size: size, inset: 14)
    }
  }
}
