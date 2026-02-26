import SwiftUI
import SwiftData

struct ClipRowView: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Type icon with subtle background
            ClipTypeIcon(contentType: item.contentType)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }

                    Text(item.title)
                        .font(.system(.body, design: .default, weight: isSelected ? .medium : .regular))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 4) {
                    if let appName = item.sourceAppName {
                        Text(appName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(.quaternary.opacity(0.3))
                            )
                    }

                    TimeAgoText(date: item.lastUsedAt)
                }
            }

            Spacer(minLength: 4)

            if item.contentType == .image {
                thumbnailView
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let imageContent = item.contents.first(where: {
            $0.pasteboardType == NSPasteboard.PasteboardType.png.rawValue ||
            $0.pasteboardType == NSPasteboard.PasteboardType.tiff.rawValue
        }),
        let thumb = ThumbnailCache.shared.thumbnail(for: imageContent.data, id: item.id.uuidString) {
            Image(nsImage: thumb)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }
}
