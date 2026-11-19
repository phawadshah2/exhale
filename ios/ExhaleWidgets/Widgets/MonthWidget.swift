import SwiftUI
import WidgetKit

/// Widget 4: widget 1's ring column and this month by colour. The calendar
/// opens Logs for the week; the rest opens Home.
struct MonthWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayAndMonth", provider: PresenceProvider()) { entry in
      MonthView(entry: entry)
    }
    .configurationDisplayName("Today and the month")
    .description("Today's ring and each day of the month.")
    .supportedFamilies([.systemMedium])
  }
}

struct MonthView: View {
  let entry: PresenceEntry

  var body: some View {
    let state = entry.state
    PresenceGate(state: state) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 0) {
          StagePill(state: state, withCount: true)
          TodayRing(state: state, date: entry.date, size: 92)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          CornerCounter(state: state, date: entry.date)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 116)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(state.spoken(at: entry.date)) \(state.daysLine).")
        if let today = state.today {
          Link(destination: PresenceFormat.weekURL) {
            VStack(spacing: 6) {
              HStack {
                WidgetLabel(today.formatted(.dateTime.month(.wide)))
                Spacer(minLength: 4)
                StatusKey()
              }
              MonthGrid(month: state.month, today: today)
              Spacer(minLength: 0)
            }
          }
        }
      }
    }
    .widgetURL(PresenceFormat.homeURL)
    .containerBackground(for: .widget) {
      GlowBackground(state: state, center: UnitPoint(x: 0.2, y: 0.5))
    }
  }
}
