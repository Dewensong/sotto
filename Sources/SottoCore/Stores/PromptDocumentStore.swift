import Foundation

public final class PromptDocumentStore {
    private let directory: URL
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var cachedDocuments: [PromptDocument]?

    public init(directory: URL? = nil) {
        let baseDirectory = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Sotto", isDirectory: true)
        self.directory = baseDirectory
        self.fileURL = baseDirectory.appendingPathComponent("recent-documents.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func save(_ document: PromptDocument) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var documents = try loadRecentDocuments()
        var updated = document
        updated.updatedAt = Date()

        if let index = documents.firstIndex(where: { $0.id == updated.id }) {
            documents[index] = updated
        } else {
            documents.append(updated)
        }

        documents.sort { $0.updatedAt > $1.updatedAt }
        cachedDocuments = documents
        let data = try encoder.encode(documents)
        try data.write(to: fileURL, options: .atomic)
    }

    public func loadRecentDocuments() throws -> [PromptDocument] {
        if let cached = cachedDocuments { return cached }
        let documents = try loadFromDisk()
        cachedDocuments = documents
        return documents
    }

    public func remove(id: PromptDocument.ID) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var documents = try loadRecentDocuments()
        documents.removeAll { $0.id == id }
        cachedDocuments = documents
        let data = try encoder.encode(documents)
        try data.write(to: fileURL, options: .atomic)
    }

    private func loadFromDisk() throws -> [PromptDocument] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let documents = try decoder.decode([PromptDocument].self, from: data)
        return documents.sorted { $0.updatedAt > $1.updatedAt }
    }
}
