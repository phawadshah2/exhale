import XCTest

@testable import Runner

final class QueueStoreTests: XCTestCase {
  private var url: URL!

  override func setUp() {
    super.setUp()
    url = FileManager.default.temporaryDirectory
      .appendingPathComponent("queue-\(UUID().uuidString).json")
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: url)
    super.tearDown()
  }

  func testMissingFileReadsEmpty() throws {
    XCTAssertEqual(try QueueStore(url: url).read(), [])
  }

  func testAppendWhileReadingKeepsBoth() throws {
    let total = 40
    let url = self.url!
    DispatchQueue.concurrentPerform(iterations: total) { index in
      let store = QueueStore(url: url)
      do {
        if index.isMultiple(of: 2) { _ = try store.read() }
        try store.append(QueuedLog(id: "log-\(index)", loggedAt: Date(timeIntervalSince1970: 0)))
      } catch {
        XCTFail("\(error)")
      }
    }

    let ids = Set(try QueueStore(url: url).read().map(\.id))
    XCTAssertEqual(ids, Set((0..<total).map { "log-\($0)" }))
  }

  func testRemoveLeavesOtherIds() throws {
    let store = QueueStore(url: url)
    for id in ["a", "b", "c"] {
      try store.append(QueuedLog(id: id, loggedAt: Date(timeIntervalSince1970: 0)))
    }

    try store.remove(ids: ["a", "c", "missing"])

    XCTAssertEqual(try store.read().map(\.id), ["b"])
  }

  func testWritesTheAppsJson() throws {
    let store = QueueStore(url: url)
    try store.append(QueuedLog(id: "a", loggedAt: Date(timeIntervalSince1970: 1_794_645_300.25)))

    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: String]])
    XCTAssertEqual(json, [["id": "a", "loggedAt": "2026-11-14T08:35:00.250Z"]])
  }
}
