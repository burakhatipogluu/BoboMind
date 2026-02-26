import AppKit

@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 200
    }

    func thumbnail(for data: Data, id: String, maxSize: CGFloat = 72) -> NSImage? {
        let key = "\(id)-\(Int(maxSize))" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let image = NSImage(data: data) else { return nil }
        let thumb = image.thumbnail(maxSize: maxSize)
        cache.setObject(thumb, forKey: key)
        return thumb
    }

    func clear() {
        cache.removeAllObjects()
    }
}
