import SwiftUI
import WidgetKit

/// Widget 5: seven bars against each day's limit, the week's total against
/// its allowance. Opens Logs for the week.
struct WeekWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ThisWeek", provider: PresenceProvider()) { entry in
      WeekView(entry: entry)
    }
    .configurationDisplayName("This week")
    .description("Each day of the week against its limit.")
    .supportedFamilies([.systemMedium])
  }
}

struct WeekView: View {
  let entry: PresenceEntry

  var body: some View {
    let state = entry.state
    PresenceGate(state: state) {
      let total = state.week.reduce(0) { $0 + $1.count }
      let allowed = state.week.reduce(0) { $0 + $1.limit }
      let summary = state.weekSummary
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          WidgetLabel("This week")
          Spacer(minLength: 4)
          if summary.of > 0 {
            Text("\(summary.kept) of \(summary.of) days under")
              .font(.system(size: 12, weight: .medium))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }
        HStack(alignment: .bottom, spacing: 16) {
          WeekBars(week: state.week, today: state.today ?? entry.date)
          VStack(alignment: .leading, spacing: 2) {
            Text("\(total)")
              .font(.system(size: 26, weight: .bold))
              .monospacedDigit()
            Text("this week\nvs \(allowed) allowed")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(.secondary)
          }
          .frame(width: 96, alignment: .leading)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        "This week: \(total) of \(allowed) allowed."
          + (summary.of > 0 ? " \(summary.kept) of \(summary.of) days under." : ""))
    }
    .widgetURL(PresenceFormat.weekURL)
    .containerBackground(for: .widget) { Color(light: 0xFFFFFF, dark: 0x161C25) }
  }
}
