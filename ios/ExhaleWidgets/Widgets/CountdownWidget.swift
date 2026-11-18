import AppIntents
import SwiftUI
import WidgetKit

/// Widget 2: the live timer to the next one on schedule and its green bar.
struct CountdownWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "Countdown", provider: PresenceProvider()) { entry in
      CountdownView(entry: entry)
    }
    .configurationDisplayName("Countdown")
    .description("The time to the next one on schedule.")
    .supportedFamilies([.systemSmall])
  }
}

struct CountdownView: View {
  let entry: PresenceEntry

  var body: some View {
    let state = entry.state
    PresenceGate(state: state) {
      VStack(alignment: .leading, spacing: 0) {
        WidgetLabel(label(state))
        headline(state)
          .padding(.top, 8)
        bar(state)
          .padding(.top, 8)
        Spacer(minLength: 0)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(state.count) of \(state.limit)")
          if let timer = state.timer {
            Text("at \(PresenceFormat.time(timer.next))")
          } else {
            Text("today")
          }
        }
        .font(.system(size: 12, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(state.spoken(at: entry.date))
      .overlay(alignment: .bottomTrailing) { LogOneButton() }
    }
    .widgetURL(PresenceFormat.homeURL)
    .containerBackground(for: .widget) { Color(light: 0xFFFFFF, dark: 0x161C25) }
  }

  private func label(_ state: PresenceState) -> String {
    if case .waited = state.corner(at: entry.date) { return "Waited" }
    return "Until your next"
  }

  @ViewBuilder private func headline(_ state: PresenceState) -> some View {
    let big = Font.system(size: 28, weight: .bold)
    let line = Font.system(size: 20, weight: .bold)
    switch state.corner(at: entry.date) {
    case .counting(let next):
      Text(timerInterval: entry.date...next, countsDown: true)
        .font(big).monospacedDigit()
    case .waited(let since):
      (Text("+") + Text(since, style: .timer)).font(big).monospacedDigit()
    case .left(let left):
      Text("\(left) left today").font(line)
    case .limitReached:
      Text("That's today's \(state.limit)").font(line).foregroundStyle(state.status.color)
    case .over(let by):
      Text("\(by) over").font(line).foregroundStyle(state.status.color)
    case .free(let title):
      Text(title).font(line).foregroundStyle(state.status.color)
    }
  }

  @ViewBuilder private func bar(_ state: PresenceState) -> some View {
    switch state.corner(at: entry.date) {
    case .counting:
      if let timer = state.timer {
        ProgressView(timerInterval: timer.gapStart...timer.next, countsDown: true) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(PresenceState.Status.under.color)
        .widgetAccentable()
      }
    case .left:
      FullBar(color: .track, fraction: 0)
    default:
      FullBar(color: state.status.color, fraction: 1)
    }
  }
}

/// The round + that runs Log one.
struct LogOneButton: View {
  var body: some View {
    Button(intent: LogOneIntent()) {
      Image(systemName: "plus")
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(Color(light: 0xFFFFFF, dark: 0x111418))
        .frame(width: 40, height: 40)
        .background(Circle().fill(Color(light: 0x111418, dark: 0xFFFFFF)))
        .widgetAccentable()
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Log one")
  }
}

/// A 5 pt bar at a fixed fill.
struct FullBar: View {
  let color: Color
  let fraction: Double

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.track)
        Capsule().fill(color).frame(width: proxy.size.width * fraction).widgetAccentable()
      }
    }
    .frame(height: 5)
  }
}
