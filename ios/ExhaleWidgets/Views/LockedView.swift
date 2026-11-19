import SwiftUI
import WidgetKit

/// Without access: "Exhale is locked"; tapping opens the app.
struct LockedView: View {
  var compact = false

  var body: some View {
    VStack(spacing: compact ? 2 : 8) {
      Image(systemName: "lock.fill")
        .font(.system(size: compact ? 14 : 22, weight: .semibold))
        .widgetAccentable()
      Text("Exhale is locked")
        .font(.system(size: compact ? 12 : 14, weight: .semibold))
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.7)
    }
    .accessibilityElement(children: .combine)
  }
}

/// Shows [live] only when the snapshot is up to date and unlocked.
struct PresenceGate<Live: View>: View {
  let state: PresenceState
  var compact = false
  @ViewBuilder let live: () -> Live

  var body: some View {
    switch state.kind {
    case .live: live()
    case .locked: LockedView(compact: compact)
    case .stale: StaleView(compact: compact)
    }
  }
}
