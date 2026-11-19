import ActivityKit
import Foundation

/// The countdown Live Activity and its Dynamic Island. Quiet from its stale
/// date (15 min past [ContentState.next]) with no code running.
struct CountdownAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// When the next one is due.
    var next: Date
    /// When the wait began; the bar drains from here to [next].
    var gapStart: Date
    var count: Int
    var limit: Int
    var daysToGo: Int
    /// Shown while counting down.
    var countingLine: String
    /// Shown once the activity is stale.
    var waitingLine: String
  }
}
