import AppKit

extension NSImage {
    func thumbnail(maxSize: CGFloat) -> NSImage {
        let currentSize = size
        guard currentSize.width > 0, currentSize.height > 0 else { return self }

        let ratio = min(maxSize / currentSize.width, maxSize / currentSize.height)
        if ratio >= 1.0 { return self }

        let newSize = NSSize(
            width: currentSize.width * ratio,
            height: currentSize.height * ratio
        )

        let thumbnail = NSImage(size: newSize, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            self.draw(
                in: rect,
                from: NSRect(origin: .zero, size: currentSize),
                operation: .copy,
                fraction: 1.0
            )
            return true
        }
        return thumbnail
    }
}
