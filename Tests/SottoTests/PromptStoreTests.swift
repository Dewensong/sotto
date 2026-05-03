import XCTest
@testable import SottoCore

final class PromptStoreTests: XCTestCase {
    func testSavesUpdatesAndLoadsRecentDocuments() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = PromptDocumentStore(directory: directory)
        var document = SegmentationService().segment("第一段稿件。")
        document.title = "First"

        try store.save(document)
        var loaded = try store.loadRecentDocuments()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "First")

        document.rawText = "更新后的稿件。"
        try store.save(document)
        loaded = try store.loadRecentDocuments()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].rawText, "更新后的稿件。")
    }
}
