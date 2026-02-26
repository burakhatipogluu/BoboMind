import AppKit

enum ContentType: String, CaseIterable, Identifiable, Codable {
    case plainText
    case richText
    case html
    case image
    case fileURL
    case color
    case unknown

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .plainText: "doc.text"
        case .richText: "doc.richtext"
        case .html: "globe"
        case .image: "photo"
        case .fileURL: "doc"
        case .color: "paintpalette"
        case .unknown: "questionmark.square"
        }
    }

    var displayName: String {
        switch self {
        case .plainText: "Text"
        case .richText: "Rich Text"
        case .html: "HTML"
        case .image: "Image"
        case .fileURL: "File"
        case .color: "Color"
        case .unknown: "Unknown"
        }
    }

    static func from(pasteboardType: NSPasteboard.PasteboardType) -> ContentType {
        switch pasteboardType {
        case .string: .plainText
        case .rtf, .rtfd: .richText
        case .html: .html
        case .png, .tiff: .image
        case .fileURL: .fileURL
        case .color: .color
        default: .unknown
        }
    }

    static func primaryType(from types: [NSPasteboard.PasteboardType]) -> ContentType {
        let priority: [ContentType] = [.image, .fileURL, .html, .richText, .plainText, .color]
        for contentType in priority {
            for pbType in types {
                if ContentType.from(pasteboardType: pbType) == contentType {
                    return contentType
                }
            }
        }
        return .unknown
    }
}
