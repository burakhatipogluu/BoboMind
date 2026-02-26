import SwiftData
import Foundation

@Model
final class ClipGroup {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ClipboardItem.group)
    var items: [ClipboardItem]

    init(name: String, icon: String = "folder.fill", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.items = []
    }
}
