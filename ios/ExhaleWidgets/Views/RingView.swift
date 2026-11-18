import SwiftUI
import WidgetKit

/// Today's ring: the day's count against its limit in the day's colour, with
/// "4/8 today" in the middle (days at zero from the quit day on).
struct RingView: View {
  let state: PresenceState
  var size: CGFloat = 88
  var lineWidth: CGFloat = 9
  /// Room left around the ring for the countdown ring.
  var inset: CGFloat = 9

  var body: some View {
    ZStack {
      Circle().stroke(Color.track, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: state.ringProgress)
        .stroke(state.status.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .widgetAccentable()
      VStack(spacing: 1) {
        Text(state.quitReached ? "\(state.daysAtZero)" : "\(state.count)/\(state.limit)")
          .font(.system(size: size * 0.21, weight: .bold))
          .monospacedDigit()
        Text(state.quitReached ? "at zero" : "today")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .minimumScaleFactor(0.6)
      .lineLimit(1)
      .padding(.horizontal, lineWidth + 2)
    }
    .padding(inset)
    .frame(width: size, height: size)
  }
}
