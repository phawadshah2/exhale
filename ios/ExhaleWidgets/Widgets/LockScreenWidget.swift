import SwiftUI
import WidgetKit

/// The Lock Screen trio: inline above the clock, today's ring, and the
/// rectangle with the count, the next one and the days to go.
struct LockScreenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "LockScreen", provider: PresenceProvider()) { entry in
      LockScreenView(entry: entry)
    }
    .configurationDisplayName("Exhale")
    .description("Today's count and the next one on schedule.")
    .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
  }
}

struct LockScreenView: View {
  let entry: PresenceEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    content
      .widgetURL(PresenceFormat.homeURL)
      .containerBackground(for: .widget) {
        if family == .accessoryCircular { AccessoryWidgetBackground() }
      }
  }

  @ViewBuilder private var content: some View {
    let state = entry.state
    switch family {
    case .accessoryInline: inline(state)
    case .accessoryCircular: circular(state)
    default: rectangular(state)
    }
  }

  @ViewBuilder private func inline(_ state: PresenceState) -> some View {
    switch state.kind {
    case .locked: Text("Exhale is locked")
    case .stale: Text("Open Exhale to update")
    case .live:
      Text(
        state.quitReached
          ? "Exhale · \(state.daysLine)"
          : "Exhale · \(state.count) of \(state.limit) · \(state.daysLine)")
    }
  }

  @ViewBuilder private func circular(_ state: PresenceState) -> some View {
    switch state.kind {
    case .locked: Image(systemName: "lock.fill").font(.title3).accessibilityLabel("Exhale is locked")
    case .stale:
      Image(systemName: "arrow.clockwise").font(.title3)
        .accessibilityLabel("Open Exhale to update")
    case .live:
      Gauge(value: state.ringProgress) {
        EmptyView()
      } currentValueLabel: {
        Text(state.quitReached ? "\(state.daysAtZero)" : "\(state.count)/\(state.limit)")
          .font(.system(size: 15, weight: .bold))
          .monospacedDigit()
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .widgetAccentable()
      .accessibilityLabel(state.spoken(at: entry.date))
    }
  }

  @ViewBuilder private func rectangular(_ state: PresenceState) -> some View {
    PresenceGate(state: state, compact: true) {
      VStack(alignment: .leading, spacing: 0) {
        Text("\(state.count) of \(state.limit) today")
          .font(.headline)
          .widgetAccentable()
        second(state)
        Text(state.daysLine)
      }
      .monospacedDigit()
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(state.spoken(at: entry.date)) \(state.daysLine).")
    }
  }

  @ViewBuilder private func second(_ state: PresenceState) -> some View {
    switch state.corner(at: entry.date) {
    case .counting(let next): Text("Next one at \(PresenceFormat.time(next))")
    case .waited(let since): Text("Waited +") + Text(since, style: .timer)
    case .left(let left): Text("\(left) left today")
    case .limitReached: Text("Limit reached")
    case .over(let by): Text("\(by) over")
    case .free(let title): Text(title)
    }
  }
}
