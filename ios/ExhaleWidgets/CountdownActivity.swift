import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The countdown Live Activity and its Dynamic Island. From the stale date
/// (15 min past due) it reads "On schedule" with no code running.
struct CountdownActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CountdownAttributes.self) { context in
      CountdownCard(state: context.state, quiet: context.isStale)
        .activityBackgroundTint(Color(red: 24 / 255, green: 26 / 255, blue: 32 / 255).opacity(0.86))
        .activitySystemActionForegroundColor(.white)
        .widgetURL(PresenceFormat.homeURL)
    } dynamicIsland: { context in
      let state = context.state
      let quiet = context.isStale
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Exhale")
            .font(.system(size: 13, weight: .semibold))
            .opacity(0.8)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(state.count) of \(state.limit) today")
            .font(.system(size: 13, weight: .semibold))
            .monospacedDigit()
            .opacity(0.8)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
              if quiet {
                Text("On schedule").font(.system(size: 28, weight: .bold))
                Text(daysToGo(state.daysToGo)).font(.system(size: 13)).opacity(0.75)
              } else {
                Text(timerInterval: state.gapStart...state.next, countsDown: true)
                  .font(.system(size: 32, weight: .bold))
                  .monospacedDigit()
                Text("until your next · \(PresenceFormat.time(state.next))")
                  .font(.system(size: 13))
                  .opacity(0.75)
              }
            }
            Spacer(minLength: 8)
            Button(intent: LogOneIntent()) {
              Text("+ Log one")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 17 / 255, green: 20 / 255, blue: 24 / 255))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            }
            .buttonStyle(.plain)
          }
          .padding(.top, 4)
        }
      } compactLeading: {
        IslandRing(state: state, quiet: quiet)
      } compactTrailing: {
        if quiet {
          Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(PresenceState.Status.under.color)
            .accessibilityLabel("On schedule")
        } else {
          Text(timerInterval: state.gapStart...state.next, countsDown: true)
            .font(.system(size: 15, weight: .bold))
            .monospacedDigit()
            .frame(maxWidth: 64)
        }
      } minimal: {
        IslandRing(state: state, quiet: quiet)
      }
      .widgetURL(PresenceFormat.homeURL)
      .keylineTint(PresenceState.Status.under.color)
    }
  }
}

private func daysToGo(_ days: Int) -> String {
  days == 1 ? "1 day to go" : "\(days) days to go"
}

/// The Lock Screen card: timer, count and next time, the draining bar, a line.
struct CountdownCard: View {
  let state: CountdownAttributes.ContentState
  let quiet: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 0) {
          Text("Exhale")
            .font(.system(size: 12, weight: .semibold))
            .opacity(0.8)
          if quiet {
            Text("On schedule").font(.system(size: 26, weight: .bold))
          } else {
            Text(timerInterval: state.gapStart...state.next, countsDown: true)
              .font(.system(size: 26, weight: .bold))
              .monospacedDigit()
          }
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 1) {
          Text("\(state.count) of \(state.limit) today")
            .fontWeight(.semibold)
            .monospacedDigit()
          Text(quiet ? daysToGo(state.daysToGo) : "next at \(PresenceFormat.time(state.next))")
            .opacity(0.8)
        }
        .font(.system(size: 12))
      }
      CardBar(state: state, quiet: quiet)
        .padding(.top, 9)
        .padding(.bottom, 8)
      Text(quiet ? state.waitingLine : state.countingLine)
        .font(.system(size: 12.5))
        .italic()
        .opacity(0.85)
        .lineLimit(2)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 14)
    .padding(.top, 11)
    .padding(.bottom, 12)
    .accessibilityElement(children: .combine)
  }
}

/// 4 pt; drains in green while counting, full once quiet.
private struct CardBar: View {
  let state: CountdownAttributes.ContentState
  let quiet: Bool

  var body: some View {
    if quiet {
      Capsule()
        .fill(PresenceState.Status.under.color)
        .frame(height: 4)
    } else {
      ProgressView(timerInterval: state.gapStart...state.next, countsDown: true) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .progressViewStyle(.linear)
      .tint(PresenceState.Status.under.color)
      .frame(height: 4)
    }
  }
}

/// The Island's draining ring; full once quiet.
private struct IslandRing: View {
  let state: CountdownAttributes.ContentState
  let quiet: Bool

  var body: some View {
    Group {
      if quiet {
        Circle()
          .stroke(PresenceState.Status.under.color, lineWidth: 3)
      } else {
        ProgressView(timerInterval: state.gapStart...state.next, countsDown: true) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(PresenceState.Status.under.color)
      }
    }
    .frame(width: 18, height: 18)
    .accessibilityLabel(quiet ? "On schedule" : "Counting down to your next")
  }
}
