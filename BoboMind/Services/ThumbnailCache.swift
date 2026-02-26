import AppKit

@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 200
    }

    /// Synchronous cache lookup only — returns cached thumbnail or nil.
    func cachedThumbnail(for id: String, maxSize: CGFloat = 72) -> NSImage? {
        let key = "\(id)-\(Int(maxSize))" as NSString
        return cache.object(forKey: key)
    }

    /// Async thumbnail generation — decodes on background thread.
    func thumbnail(for data: Data, id: String, maxSize: CGFloat = 72) async -> NSImage? {
        let key = "\(id)-\(Int(maxSize))" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let thumb: NSImage? = await Task.detached(priority: .userInitiated) {
            guard let image = NSImage(data: data) else { return nil as NSImage? }
            return image.thumbnail(maxSize: maxSize)
        }.value

        if let thumb {
            cache.setObject(thumb, forKey: key)
        }
        return thumb
    }

    /// Legacy synchronous method for compatibility
    func thumbnailSync(for data: Data, id: String, maxSize: CGFloat = 72) -> NSImage? {
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
