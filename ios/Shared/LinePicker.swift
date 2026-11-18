import Foundation

/// Swift's `pickLinePair`: two different lines, neither from the last pair.
enum LinePicker {
  static func pick(
    lines: [String], last: PresenceSnapshot.LinePair?
  ) -> PresenceSnapshot.LinePair {
    var random = SystemRandomNumberGenerator()
    return pick(lines: lines, last: last, using: &random)
  }

  static func pick(
    lines: [String], last: PresenceSnapshot.LinePair?,
    using random: inout some RandomNumberGenerator
  ) -> PresenceSnapshot.LinePair {
    var pool = lines.filter { $0 != last?.counting && $0 != last?.waiting }
    if pool.count < 2 { pool = lines }
    guard pool.count >= 2 else {
      let line = pool.first ?? ""
      return PresenceSnapshot.LinePair(counting: line, waiting: line)
    }
    let counting = pool.remove(at: Int.random(in: 0..<pool.count, using: &random))
    return PresenceSnapshot.LinePair(
      counting: counting, waiting: pool[Int.random(in: 0..<pool.count, using: &random)])
  }
}
