import SwiftUI
import UIKit

/// The app's limit colours: green under, amber at, red over.
extension PresenceState.Status {
  var color: Color {
    switch self {
    case .under: Color(light: 0x2E9E6A, dark: 0x3DBE83)
    case .at: Color(light: 0xD9962B, dark: 0xEBAE4A)
    case .over: Color(light: 0xD9534F, dark: 0xEA6A66)
    }
  }

  /// Text on a [color] tint.
  var ink: Color {
    switch self {
    case .under: Color(light: 0x1F6E49, dark: 0x7FD8AE)
    case .at: Color(light: 0x8A5A10, dark: 0xF2C778)
    case .over: Color(light: 0x9C2F2B, dark: 0xF29A97)
    }
  }
}

extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(
      uiColor: UIColor { traits in
        let hex = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
          blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
      })
  }

  static let track = Color(light: 0xE4E9EF, dark: 0x2C333D)
}

/// What the corner of widgets 1 and 4 (and the other summaries) say.
enum CornerState: Equatable {
  /// Counting down to the next one.
  case counting(Date)
  /// Past the time on schedule; the wait counts up from it.
  case waited(since: Date)
  case left(Int)
  case limitReached
  case over(Int)
  /// A limit of 0 kept: the habit's free-day wording.
  case free(String)
}

extension PresenceState {
  func corner(at date: Date) -> CornerState {
    switch status {
    case .over: return .over(count - limit)
    case .at: return .limitReached
    case .under:
      if limit == 0 { return .free(freeDayTitle) }
      if let timer {
        return timer.next > date ? .counting(timer.next) : .waited(since: timer.next)
      }
      return .left(limit - count)
    }
  }

  /// The ring's fill; full on a limit of 0.
  var ringProgress: Double {
    limit > 0 ? min(Double(count) / Double(limit), 1) : 1
  }

  /// "41 days to go", or "Day 3 at zero" from the quit day on.
  var daysLine: String {
    if quitReached { return "Day \(daysAtZero) at zero" }
    return daysToGo == 1 ? "1 day to go" : "\(daysToGo) days to go"
  }

  /// "41 days" in the corner of widget 1.
  var daysShort: String {
    if quitReached { return "Day \(daysAtZero) at zero" }
    return daysToGo == 1 ? "1 day" : "\(daysToGo) days"
  }

  /// Spoken like the Home ring.
  func spoken(at date: Date) -> String {
    let count = "\(count) of \(limit) today"
    switch corner(at: date) {
    case .counting(let next):
      return "Next one on schedule in \(PresenceFormat.hoursMinutes(next.timeIntervalSince(date)))."
        + " \(count), \(limit - self.count) left."
    case .waited, .left: return "\(count), \(limit - self.count) left."
    case .limitReached: return "\(count). Limit reached."
    case .over(let by): return "\(count), \(by) over."
    case .free(let title): return quitReached ? "\(title). \(daysLine)." : "\(title)."
    }
  }
}

enum PresenceFormat {
  /// "1 h 13 min", rounded up to the minute, as the app's `AppFormat.hoursMinutes`.
  static func hoursMinutes(_ interval: TimeInterval) -> String {
    let total = Int((interval / 60).rounded(.up))
    if total < 60 { return "\(total) min" }
    let rest = total % 60
    return rest == 0 ? "\(total / 60) h" : "\(total / 60) h \(rest) min"
  }

  /// "10:13 AM" in the person's locale.
  static func time(_ date: Date) -> String {
    date.formatted(date: .omitted, time: .shortened)
  }

  static let homeURL = URL(string: "exhale://home")!
  static let weekURL = URL(string: "exhale://logs/week")!
}
