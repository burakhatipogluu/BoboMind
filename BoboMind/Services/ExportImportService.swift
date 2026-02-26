import Foundation
import SwiftData
import AppKit
import CryptoKit

struct ExportImportResult: Sendable {
    let success: Bool
    let clipsCount: Int
    let snippetsCount: Int
    let message: String
}

struct ExportableClip: Codable {
    let title: String
    let plainText: String?
    let contentType: String
    let createdAt: Date
    let isPinned: Bool
    let sourceAppName: String?
    let groupName: String?
    let contentHash: String?
    let binaryContents: [ExportableBinaryContent]?
}

struct ExportableBinaryContent: Codable {
    let pasteboardType: String
    let base64Data: String
}

struct ExportableSnippet: Codable {
    let title: String
    let content: String
    let keyword: String
}

struct ExportData: Codable, Sendable {
    let version: Int
    let exportedAt: Date
    let clips: [ExportableClip]
    let snippets: [ExportableSnippet]
}

@MainActor
enum ExportImportService {

    static func exportToJSON(clips: [ClipboardItem], snippets: [Snippet]) -> Data? {
        let exportClips = clips.map { item in
            // Encode binary content (images, files) as base64
            let binaryContents: [ExportableBinaryContent]? = item.plainText == nil ? item.contents.map { content in
                ExportableBinaryContent(
                    pasteboardType: content.pasteboardType,
                    base64Data: content.data.base64EncodedString()
                )
            } : nil

            return ExportableClip(
                title: item.title,
                plainText: item.plainText,
                contentType: item.contentTypeRaw,
                createdAt: item.createdAt,
                isPinned: item.isPinned,
                sourceAppName: item.sourceAppName,
                groupName: item.group?.name,
                contentHash: item.contentHash,
                binaryContents: binaryContents
            )
        }

        let exportSnippets = snippets.map { snippet in
            ExportableSnippet(
                title: snippet.title,
                content: snippet.content,
                keyword: snippet.keyword
            )
        }

        let exportData = ExportData(
            version: 1,
            exportedAt: Date(),
            clips: exportClips,
            snippets: exportSnippets
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(exportData)
        } catch {
            logger.error("Failed to encode export data: \(error.localizedDescription)")
            return nil
        }
    }

    static func showExportPanel(clips: [ClipboardItem], snippets: [Snippet]) async -> ExportImportResult? {
        guard let data = exportToJSON(clips: clips, snippets: snippets) else {
            return ExportImportResult(success: false, clipsCount: 0, snippetsCount: 0, message: "Failed to encode data")
        }

        // Warn about binary content size
        let binaryCount = clips.filter { $0.plainText == nil }.count
        if binaryCount > 0 {
            let alert = NSAlert()
            alert.messageText = "Export includes binary data"
            alert.informativeText = "\(binaryCount) image/file clip(s) will be exported with full binary data (base64 encoded). The export file may be large."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() != .alertFirstButtonReturn {
                return nil
            }
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "BoboMind-Export.json"
        panel.title = "Export BoboMind History"

        let response = await withCheckedContinuation { continuation in
            panel.begin { response in
                continuation.resume(returning: response)
            }
        }

        guard response == .OK, let url = panel.url else { return nil }

        do {
            try data.write(to: url)
            let textClips = clips.filter { $0.plainText != nil }.count
            let binaryOnly = clips.count - textClips
            var message = "Exported \(clips.count) clips and \(snippets.count) snippets"
            if binaryOnly > 0 {
                message += " (\(binaryOnly) image/file clips are metadata-only)"
            }
            return ExportImportResult(
                success: true,
                clipsCount: clips.count,
                snippetsCount: snippets.count,
                message: message
            )
        } catch {
            logger.error("Failed to write export: \(error.localizedDescription)")
            return ExportImportResult(
                success: false, clipsCount: 0, snippetsCount: 0,
                message: "Export failed: \(error.localizedDescription)"
            )
        }
    }

    static func showImportPanel(modelContext: ModelContext, modelContainer: ModelContainer?) async -> ExportImportResult? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import BoboMind History"

        let response = await withCheckedContinuation { continuation in
            panel.begin { response in
                continuation.resume(returning: response)
            }
        }

        guard response == .OK, let url = panel.url else { return nil }

        if let container = modelContainer {
            let bgContext = ModelContext(container)
            return importFromJSON(url: url, modelContext: bgContext)
        } else {
            return importFromJSON(url: url, modelContext: modelContext)
        }
    }

    static func importFromJSON(url: URL, modelContext: ModelContext) -> ExportImportResult {
        guard let data = try? Data(contentsOf: url) else {
            return ExportImportResult(success: false, clipsCount: 0, snippetsCount: 0, message: "Could not read file")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let exportData = try? decoder.decode(ExportData.self, from: data) else {
            return ExportImportResult(success: false, clipsCount: 0, snippetsCount: 0, message: "Invalid file format")
        }

        var importedClips = 0
        var importedSnippets = 0

        // Import snippets (skip duplicates by title+content)
        for exportSnippet in exportData.snippets {
            let title = exportSnippet.title
            let content = exportSnippet.content
            let descriptor = FetchDescriptor<Snippet>(
                predicate: #Predicate { $0.title == title && $0.content == content }
            )
            if (try? modelContext.fetchCount(descriptor)) ?? 0 > 0 { continue }

            let snippet = Snippet(
                title: exportSnippet.title,
                content: exportSnippet.content,
                keyword: exportSnippet.keyword
            )
            modelContext.insert(snippet)
            importedSnippets += 1
        }

        // Import clips (skip duplicates by contentHash)
        for exportClip in exportData.clips {
            // Handle binary-only clips with base64 data
            if exportClip.plainText == nil, let binaryContents = exportClip.binaryContents, !binaryContents.isEmpty {
                let hash = exportClip.contentHash ?? UUID().uuidString
                let descriptor = FetchDescriptor<ClipboardItem>(
                    predicate: #Predicate { $0.contentHash == hash }
                )
                if (try? modelContext.fetchCount(descriptor)) ?? 0 > 0 { continue }

                let item = ClipboardItem(
                    contentHash: hash,
                    title: exportClip.title,
                    plainText: nil,
                    contentType: ContentType(rawValue: exportClip.contentType) ?? .image,
                    sourceAppName: exportClip.sourceAppName
                )
                item.createdAt = exportClip.createdAt
                item.isPinned = exportClip.isPinned

                for bc in binaryContents {
                    if let data = Data(base64Encoded: bc.base64Data) {
                        let content = ClipboardItemContent(
                            pasteboardType: bc.pasteboardType,
                            data: data
                        )
                        item.contents.append(content)
                    }
                }
                modelContext.insert(item)
                importedClips += 1
                continue
            }

            guard let text = exportClip.plainText else { continue }

            let textData = Data(text.utf8)

            // Use original contentHash from export if available, otherwise compute from text-only data
            let hash: String
            if let originalHash = exportClip.contentHash, !originalHash.isEmpty {
                hash = originalHash
            } else {
                let typeString = NSPasteboard.PasteboardType.string.rawValue
                var hasher = SHA256()
                hasher.update(data: Data(typeString.utf8))
                hasher.update(data: textData)
                hash = hasher.finalize().map { String(format: "%02x", $0) }.joined()
            }

            // Skip if already exists
            let descriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { $0.contentHash == hash }
            )
            if (try? modelContext.fetchCount(descriptor)) ?? 0 > 0 { continue }

            let item = ClipboardItem(
                contentHash: hash,
                title: exportClip.title,
                plainText: text,
                contentType: ContentType(rawValue: exportClip.contentType) ?? .plainText,
                sourceAppName: exportClip.sourceAppName
            )
            item.createdAt = exportClip.createdAt
            item.isPinned = exportClip.isPinned

            let content = ClipboardItemContent(
                pasteboardType: NSPasteboard.PasteboardType.string.rawValue,
                data: textData
            )
            item.contents.append(content)
            modelContext.insert(item)
            importedClips += 1
        }

        do {
            try modelContext.save()
            return ExportImportResult(
                success: true,
                clipsCount: importedClips,
                snippetsCount: importedSnippets,
                message: "Imported \(importedClips) clips and \(importedSnippets) snippets"
            )
        } catch {
            logger.error("Failed to save import: \(error.localizedDescription)")
            return ExportImportResult(
                success: false, clipsCount: 0, snippetsCount: 0,
                message: "Import failed: \(error.localizedDescription)"
            )
        }
    }
}
