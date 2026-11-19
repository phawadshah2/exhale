import SwiftUI
import WidgetKit

/// No snapshot, or one past its last limit day: never guess a limit.
struct StaleView: View {
  var compact = false

  var body: some View {
    VStack(spacing: compact ? 2 : 8) {
      Image(systemName: "arrow.clockwise")
        .font(.system(size: compact ? 14 : 22, weight: .semibold))
        .widgetAccentable()
      Text("Open Exhale to update")
        .font(.system(size: compact ? 12 : 14, weight: .semibold))
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.7)
    }
    .accessibilityElement(children: .combine)
  }
}
