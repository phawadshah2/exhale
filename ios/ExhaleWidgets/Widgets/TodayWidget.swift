import SwiftUI
import WidgetKit

/// Widget 1: today's ring with the countdown ring, the corner counter and
/// the days to go, on a glow in the day's colour.
struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "Today", provider: PresenceProvider()) { entry in
      TodayView(entry: entry)
    }
    .configurationDisplayName("Today")
    .description("Today's ring and the time to the next one on schedule.")
    .supportedFamilies([.systemSmall])
  }
}

struct TodayView: View {
  let entry: PresenceEntry

  var body: some View {
    let state = entry.state
    PresenceGate(state: state) {
      VStack(spacing: 0) {
        HStack {
          WidgetLabel("Today")
          Spacer(minLength: 4)
          StagePill(state: state)
        }
        TodayRing(state: state, date: entry.date, size: 88)
          .frame(maxHeight: .infinity)
        HStack {
          CornerCounter(state: state, date: entry.date)
          Spacer(minLength: 4)
          Text(state.daysShort)
            .font(.system(size: 12, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(state.spoken(at: entry.date)) \(state.daysLine).")
    }
    .widgetURL(PresenceFormat.homeURL)
    .containerBackground(for: .widget) { GlowBackground(state: state) }
  }
}

/// The widget's surface with a soft glow in the day's colour.
struct GlowBackground: View {
  let state: PresenceState
  var center = UnitPoint(x: 0.5, y: 0.48)

  var body: some View {
    ZStack {
      Color(light: 0xFFFFFF, dark: 0x161C25)
      if state.kind == .live {
        RadialGradient(
          colors: [state.status.color.opacity(0.16), state.status.color.opacity(0)],
          center: center, startRadius: 0, endRadius: 90)
      }
    }
  }
}
