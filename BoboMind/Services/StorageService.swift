import SwiftData
import Foundation

@ModelActor
actor StorageService {
    func saveClip(
        hash: String,
        title: String,
        plainText: String?,
        contentType: ContentType,
        contents: [(String, Data)],
        sourceAppBundleID: String?,
        sourceAppName: String?,
        historyLimit: Int = 500
    ) throws {
        // Check for duplicate by hash
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.contentHash == hash }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.lastUsedAt = Date()
            existing.useCount += 1
            try modelContext.save()
            return
        }

        let item = ClipboardItem(
            contentHash: hash,
            title: title,
            plainText: plainText,
            contentType: contentType,
            sourceAppBundleID: sourceAppBundleID,
            sourceAppName: sourceAppName
        )

        for (type, data) in contents {
            let content = ClipboardItemContent(pasteboardType: type, data: data)
            item.contents.append(content)
        }

        modelContext.insert(item)
        try modelContext.save()

        try enforceHistoryLimit(limit: historyLimit)
    }

    func deleteClip(_ itemID: PersistentIdentifier) throws {
        guard let item = modelContext.model(for: itemID) as? ClipboardItem else { return }
        modelContext.delete(item)
        try modelContext.save()
    }

    func togglePin(_ itemID: PersistentIdentifier) throws {
        guard let item = modelContext.model(for: itemID) as? ClipboardItem else { return }
        item.isPinned.toggle()
        try modelContext.save()
    }

    func markUsed(_ itemID: PersistentIdentifier) throws {
        guard let item = modelContext.model(for: itemID) as? ClipboardItem else { return }
        item.lastUsedAt = Date()
        item.useCount += 1
        try modelContext.save()
    }

    func clearAll(keepPinned: Bool = true) throws {
        let descriptor: FetchDescriptor<ClipboardItem>
        if keepPinned {
            descriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { !$0.isPinned }
            )
        } else {
            descriptor = FetchDescriptor<ClipboardItem>()
        }

        let items = try modelContext.fetch(descriptor)
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }

    private func enforceHistoryLimit(limit: Int) throws {
        guard limit > 0 else { return } // 0 = unlimited

        var descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPinned },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchOffset = limit

        let overflow = try modelContext.fetch(descriptor)
        for item in overflow {
            modelContext.delete(item)
        }
        if !overflow.isEmpty {
            try modelContext.save()
        }
    }
}
