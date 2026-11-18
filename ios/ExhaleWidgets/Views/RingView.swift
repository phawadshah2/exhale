import SwiftUI
import WidgetKit

/// Today's ring: the day's count against its limit in the day's colour.
struct RingView: View {
  let state: PresenceState
  var size: CGFloat = 88
  var lineWidth: CGFloat = 9

  var body: some View {
    ZStack {
      Circle().stroke(Color.track, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: state.ringProgress)
        .stroke(state.status.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .widgetAccentable()
    }
    .padding(lineWidth / 2)
    .frame(width: size, height: size)
  }
}
