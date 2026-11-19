import SwiftUI
import WidgetKit

/// This month by day, Monday first: each day up to today in its colour,
/// today outlined, later days faint.
struct MonthGrid: View {
  let month: [Date: PresenceState.Status]
  let today: Date
  var calendar = Calendar.current

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

  var body: some View {
    let days = self.days
    LazyVGrid(columns: columns, spacing: 2) {
      ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, initial in
        Text(initial)
          .font(.system(size: 9, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 13) }
      ForEach(days, id: \.self) { day in cell(day) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(spoken)
  }

  private var lead: Int {
    guard let first = days.first else { return 0 }
    return (calendar.component(.weekday, from: first) + 5) % 7
  }

  private var days: [Date] {
    guard let interval = calendar.dateInterval(of: .month, for: today),
      let count = calendar.range(of: .day, in: .month, for: today)?.count
    else { return [] }
    return (0..<count).compactMap {
      calendar.date(byAdding: .day, value: $0, to: interval.start)
    }
  }

  @ViewBuilder private func cell(_ day: Date) -> some View {
    let number = Text("\(calendar.component(.day, from: day))")
      .font(.system(size: 9.5, weight: .semibold))
      .monospacedDigit()
      .frame(maxWidth: .infinity, minHeight: 13, maxHeight: 13)
    if calendar.isDate(day, inSameDayAs: today) {
      number
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.primary, lineWidth: 1.5))
    } else if day > today {
      number.foregroundStyle(.tertiary)
    } else if let status = month[calendar.startOfDay(for: day)] {
      number
        .foregroundStyle(status.ink)
        .background {
          RoundedRectangle(cornerRadius: 5)
            .fill(status.color.opacity(0.2))
            .widgetAccentable()
        }
    } else {
      number.foregroundStyle(.tertiary)
    }
  }

  private var spoken: String {
    let past = month.filter { !calendar.isDate($0.key, inSameDayAs: today) }.values
    let under = past.filter { $0 == .under }.count
    return "This month: \(under) of \(past.count) days under the limit."
  }
}

/// "Under · At · Over" for the month.
struct StatusKey: View {
  private static let items: [(name: String, status: PresenceState.Status)] = [
    ("Under", .under), ("At", .at), ("Over", .over),
  ]

  var body: some View {
    HStack(spacing: 2) {
      ForEach(Self.items, id: \.name) { item in
        RoundedRectangle(cornerRadius: 2)
          .fill(item.status.color)
          .frame(width: 7, height: 7)
          .padding(.leading, item.status == .under ? 0 : 4)
        Text(item.name)
      }
    }
    .fixedSize()
    .font(.system(size: 9, weight: .semibold))
    .foregroundStyle(.secondary)
    .lineLimit(1)
    .accessibilityHidden(true)
  }
}
