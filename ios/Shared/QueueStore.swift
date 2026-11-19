import Foundation

/// A log made outside the app, waiting for the app to store it.
struct QueuedLog: Codable, Equatable {
  let id: String
  let loggedAt: Date

  init(id: String = UUID().uuidString, loggedAt: Date) {
    self.id = id
    self.loggedAt = loggedAt
  }

  private enum CodingKeys: String, CodingKey { case id, loggedAt }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    let text = try container.decode(String.self, forKey: .loggedAt)
    guard let date = Iso8601.date(text) else {
      throw DecodingError.dataCorruptedError(
        forKey: .loggedAt, in: container, debugDescription: "Not ISO 8601: \(text)")
    }
    loggedAt = date
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(Iso8601.string(loggedAt), forKey: .loggedAt)
  }
}

/// `queue.json` in the App Group. Every change is a coordinated
/// read-modify-write with an atomic replace, so the app, the widgets and
/// Log one never lose each other's entries.
final class QueueStore {
  let url: URL

  init(url: URL = AppGroup.queueURL) {
    self.url = url
  }

  func append(_ log: QueuedLog) throws {
    try update { $0.append(log) }
  }

  func read() throws -> [QueuedLog] {
    var result: Result<[QueuedLog], Error> = .success([])
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(
      readingItemAt: url, options: [], error: &coordinationError
    ) { url in
      result = Result { try Self.decode(url) }
    }
    if let coordinationError { throw coordinationError }
    return try result.get()
  }

  /// Removes exactly [ids]; entries added since they were read stay.
  func remove(ids: Set<String>) throws {
    try update { $0.removeAll { ids.contains($0.id) } }
  }

  private func update(_ change: (inout [QueuedLog]) -> Void) throws {
    var failure: Error?
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(
      writingItemAt: url, options: .forMerging, error: &coordinationError
    ) { url in
      do {
        var logs = try Self.decode(url)
        change(&logs)
        try JSONEncoder().encode(logs).write(to: url, options: .atomic)
      } catch {
        failure = error
      }
    }
    if let coordinationError { throw coordinationError }
    if let failure { throw failure }
  }

  private static func decode(_ url: URL) throws -> [QueuedLog] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    let data = try Data(contentsOf: url)
    if data.isEmpty { return [] }
    return try JSONDecoder().decode([QueuedLog].self, from: data)
  }
}
