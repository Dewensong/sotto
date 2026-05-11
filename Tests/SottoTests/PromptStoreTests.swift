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

    func testRemovesRecentDocument() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = PromptDocumentStore(directory: directory)
        var first = SegmentationService().segment("第一段稿件。")
        first.title = "First"
        var second = SegmentationService().segment("第二段稿件。")
        second.title = "Second"

        try store.save(first)
        try store.save(second)
        try store.remove(id: first.id)

        let loaded = try store.loadRecentDocuments()
        XCTAssertEqual(loaded.map(\.id), [second.id])
    }

    func testDocumentStoreKeepsAllSavedDocumentsForLibraryManagement() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = PromptDocumentStore(directory: directory)

        for index in 0..<16 {
            var document = SegmentationService().segment("第 \(index) 段稿件。")
            document.title = "Draft \(index)"
            try store.save(document)
        }

        let loaded = try store.loadRecentDocuments()
        XCTAssertEqual(loaded.count, 16)
    }
}
