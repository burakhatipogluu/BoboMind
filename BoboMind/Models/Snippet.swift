import SwiftData
import Foundation

@Model
final class Snippet {
    var id: UUID
    var title: String
    var content: String
    var keyword: String
    var createdAt: Date
    var useCount: Int

    init(title: String, content: String, keyword: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.keyword = keyword
        self.createdAt = Date()
        self.useCount = 0
    }
}
