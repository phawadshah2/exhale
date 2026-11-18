import SwiftUI

/// The line under the ring in widgets 1 and 4: the time left, the wait
/// counting up, what's left today, or where the day stands.
struct CornerCounter: View {
  let state: PresenceState
  let date: Date

  var body: some View {
    Group {
      switch state.corner(at: date) {
      case .counting(let next):
        Text(timerInterval: date...next, countsDown: true)
          .font(.system(size: 13, weight: .bold))
          .monospacedDigit()
          .multilineTextAlignment(.center)
      case .waited(let since):
        (Text("Waited +") + Text(since, style: .timer))
          .monospacedDigit()
          .foregroundStyle(.secondary)
      case .left(let left):
        Text("\(left) left today").foregroundStyle(.secondary)
      case .limitReached:
        Text("Limit reached").foregroundStyle(.secondary)
      case .over(let by):
        Text("\(by) over").foregroundStyle(.secondary)
      case .free(let title):
        Text(title).foregroundStyle(.secondary)
      }
    }
    .font(.system(size: 12, weight: .semibold))
    .lineLimit(1)
    .minimumScaleFactor(0.7)
  }
}

/// "Stage 3" in the day's colour.
struct StagePill: View {
  let state: PresenceState
  var withCount = false

  var body: some View {
    if let stage = state.stage {
      Text(withCount ? "Stage \(stage) of \(state.stageCount)" : "Stage \(stage)")
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(state.status.ink)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(state.status.color.opacity(0.14), in: Capsule())
        .lineLimit(1)
    }
  }
}

/// The small caps label at the top of a widget.
struct WidgetLabel: View {
  let text: String

  init(_ text: String) { self.text = text }

  var body: some View {
    Text(text.uppercased())
      .font(.system(size: 11, weight: .bold))
      .tracking(0.5)
      .foregroundStyle(.secondary)
      .lineLimit(1)
  }
}
