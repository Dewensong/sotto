import AppKit
import Foundation

enum FileTextExtractor {
    static let supportedExtensions = ["md", "markdown", "txt", "doc", "docx"]

    static func extractText(from url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown", "txt":
            return try String(contentsOf: url, encoding: .utf8)
        case "docx":
            return try extractDocx(url)
        case "doc":
            return try extractDoc(url)
        default:
            throw ExtractionError.unsupportedFormat(ext)
        }
    }

    private static func extractDocx(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.officeOpenXML
        ]
        let attrString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attrString.string
    }

    private static func extractDoc(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.docFormat
        ]
        let attrString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attrString.string
    }
}

enum ExtractionError: LocalizedError {
    case unsupportedFormat(String)
    case readFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext): return "不支持的格式 .\(ext)"
        case .readFailed(let error): return "读取失败：\(error.localizedDescription)"
        }
    }
}
