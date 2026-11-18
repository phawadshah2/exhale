import SwiftUI
import WidgetKit

/// The thin ring inside today's ring that drains to the next one on
/// schedule, as on Home. Drawn at the entry's time; the timeline redraws it
/// every few minutes (`PresenceTimeline.ringStep`).
struct CountdownRing: View {
  let timer: PresenceState.Timer
  let date: Date
  let size: CGFloat
  var lineWidth: CGFloat = 2

  private var left: Double {
    let gap = timer.next.timeIntervalSince(timer.gapStart)
    guard gap > 0 else { return 0 }
    return min(max(timer.next.timeIntervalSince(date) / gap, 0), 1)
  }

  var body: some View {
    ZStack {
      Circle().stroke(.primary.opacity(0.1), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: left)
        .stroke(.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .widgetAccentable()
    }
    .padding(lineWidth / 2)
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

/// Today's ring with "4/8 today" in the middle (days at zero from the quit
/// day on) and, while the timer runs, the countdown ring inside it.
struct TodayRing: View {
  let state: PresenceState
  let date: Date
  let size: CGFloat

  private let lineWidth: CGFloat = 9

  var body: some View {
    let inner = size - 2 * lineWidth - 8
    ZStack {
      RingView(state: state, size: size, lineWidth: lineWidth)
      if let timer = state.timer, timer.next > date {
        CountdownRing(timer: timer, date: date, size: inner)
      }
      VStack(spacing: 1) {
        Text(state.quitReached ? "\(state.daysAtZero)" : "\(state.count)/\(state.limit)")
          .font(.system(size: size * 0.21, weight: .bold))
          .monospacedDigit()
        Text(state.quitReached ? "at zero" : "today")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .frame(width: inner - 8)
      .lineLimit(1)
      .minimumScaleFactor(0.6)
    }
    .frame(width: size, height: size)
  }
}
