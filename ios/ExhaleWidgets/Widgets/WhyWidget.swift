import SwiftUI
import WidgetKit

/// Widget 3: the reason from setup and the days to go, on dark. With no
/// reason saved, a line of encouragement.
struct WhyWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "YourWhy", provider: PresenceProvider()) { entry in
      WhyView(entry: entry)
    }
    .configurationDisplayName("Your why")
    .description("The reason you're cutting down.")
    .supportedFamilies([.systemSmall])
  }
}

struct WhyView: View {
  let entry: PresenceEntry

  private let muted = Color(red: 0x9A / 255, green: 0xA3 / 255, blue: 0xB0 / 255)

  var body: some View {
    let state = entry.state
    PresenceGate(state: state) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 4) {
          Image(systemName: "heart.fill").widgetAccentable()
          Text(state.reason == nil ? "FOR TODAY" : "YOUR WHY").tracking(0.5)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(muted)
        Text(state.reason ?? entry.line ?? "")
          .font(.system(size: 16, weight: .semibold))
          .lineSpacing(2)
          .minimumScaleFactor(0.7)
          .padding(.top, 10)
        Spacer(minLength: 0)
        Text(state.daysLine)
          .font(.system(size: 12, weight: .medium))
          .monospacedDigit()
          .foregroundStyle(muted)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
    }
    .foregroundStyle(.white)
    .environment(\.colorScheme, .dark)
    .widgetURL(PresenceFormat.homeURL)
    .containerBackground(for: .widget) {
      Color(red: 0x11 / 255, green: 0x14 / 255, blue: 0x18 / 255)
    }
  }
}
