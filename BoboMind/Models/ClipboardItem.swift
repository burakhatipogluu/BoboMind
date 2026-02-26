import SwiftData
import Foundation

@Model
final class ClipboardItem {
    @Attribute(.unique) var contentHash: String

    var id: UUID
    var title: String
    var plainText: String?
    var contentTypeRaw: String
    var createdAt: Date
    var lastUsedAt: Date
    var useCount: Int
    var isPinned: Bool
    var sourceAppBundleID: String?
    var sourceAppName: String?

    @Relationship(deleteRule: .cascade, inverse: \ClipboardItemContent.item)
    var contents: [ClipboardItemContent]

    var group: ClipGroup?

    var contentType: ContentType {
        get { ContentType(rawValue: contentTypeRaw) ?? .unknown }
        set { contentTypeRaw = newValue.rawValue }
    }

    init(
        contentHash: String,
        title: String,
        plainText: String? = nil,
        contentType: ContentType = .unknown,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = UUID()
        self.contentHash = contentHash
        self.title = title
        self.plainText = plainText
        self.contentTypeRaw = contentType.rawValue
        self.createdAt = Date()
        self.lastUsedAt = Date()
        self.useCount = 0
        self.isPinned = false
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.contents = []
    }
}
