import SwiftUI
import WidgetKit

/// Monday to Sunday: each day's count as a bar in its colour, with a mark at
/// that day's limit. Today is lighter; later days are empty.
struct WeekBars: View {
  let week: [PresenceState.WeekDay]
  let today: Date
  var height: CGFloat = 64
  var calendar = Calendar.current

  var body: some View {
    let scale = Double(max(week.map { max($0.count, $0.limit) }.max() ?? 1, 1))
    VStack(spacing: 4) {
      HStack(alignment: .bottom, spacing: 7) {
        ForEach(week, id: \.day) { day in
          bar(day, scale: scale)
        }
      }
      .frame(height: height)
      HStack(spacing: 7) {
        ForEach(week, id: \.day) { day in
          let isToday = calendar.isDate(day.day, inSameDayAs: today)
          Text(initial(day.day))
            .font(.system(size: 9, weight: isToday ? .bold : .semibold))
            .foregroundStyle(isToday ? .primary : .tertiary)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .accessibilityHidden(true)
  }

  private func bar(_ day: PresenceState.WeekDay, scale: Double) -> some View {
    let status = PresenceState.Status.of(count: day.count, limit: day.limit)
    let isFuture = day.day > today && !calendar.isDate(day.day, inSameDayAs: today)
    let fill = max(CGFloat(Double(day.count) / scale) * height, isFuture ? 0 : 3)
    let mark = CGFloat(Double(day.limit) / scale) * height
    return ZStack(alignment: .bottom) {
      UnevenRoundedRectangle(
        topLeadingRadius: 4, bottomLeadingRadius: 2, bottomTrailingRadius: 2,
        topTrailingRadius: 4
      )
      .fill(isFuture ? Color.track : status.color)
      .opacity(calendar.isDate(day.day, inSameDayAs: today) ? 0.55 : 1)
      .frame(height: isFuture ? 3 : fill)
      .widgetAccentable()
      if day.limit > 0 && !isFuture {
        Capsule()
          .fill(.primary.opacity(0.35))
          .frame(height: 1.5)
          .offset(y: -mark)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }

  private func initial(_ day: Date) -> String {
    ["M", "T", "W", "T", "F", "S", "S"][(calendar.component(.weekday, from: day) + 5) % 7]
  }
}

extension PresenceState {
  /// Local midnight of the logical today (the latest day in the month).
  var today: Date? { month.keys.max() }

  /// The days of this week before today, and how many stayed under the limit.
  var weekSummary: (kept: Int, of: Int) {
    guard let today else { return (0, 0) }
    let done = week.filter { $0.day < today }
    return (done.filter { Status.of(count: $0.count, limit: $0.limit) == .under }.count, done.count)
  }
}
