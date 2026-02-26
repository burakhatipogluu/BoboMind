import SwiftData
import Foundation

@Model
final class ClipboardItemContent {
    var id: UUID
    var pasteboardType: String
    var data: Data

    var item: ClipboardItem?

    init(pasteboardType: String, data: Data) {
        self.id = UUID()
        self.pasteboardType = pasteboardType
        self.data = data
    }
}
