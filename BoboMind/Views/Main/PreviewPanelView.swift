import SwiftUI
import SwiftData
import CryptoKit

struct PreviewPanelView: View {
    let item: ClipboardItem?
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        Group {
            if let item {
                VStack(alignment: .leading, spacing: 0) {
                    previewHeader(item)
                    Divider()
                    previewContent(item)
                        .transition(.opacity)
                }
                .id(item.id)
                .onChange(of: item.id) {
                    isEditing = false
                }
            } else {
                noSelectionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.15), value: item?.id)
    }

    private func previewHeader(_ item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            ClipTypeIcon(contentType: item.contentType, size: 14)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.quaternary.opacity(0.4))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(item.contentType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if let appName = item.sourceAppName {
                    Text(appName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
            }

            // Edit button for text items
            if item.contentType != .image {
                Button {
                    if isEditing {
                        saveEdit(item)
                    } else {
                        editText = item.plainText ?? item.title
                        isEditing = true
                    }
                } label: {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.system(size: 14))
                        .foregroundColor(isEditing ? Color.green : Color.secondary)
                }
                .buttonStyle(.plain)
            }

            TimeAgoText(date: item.createdAt)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func previewContent(_ item: ClipboardItem) -> some View {
        switch item.contentType {
        case .image:
            imagePreview(item)
        default:
            if isEditing {
                textEditor(item)
            } else {
                textPreview(item)
            }
        }
    }

    private func imagePreview(_ item: ClipboardItem) -> some View {
        GeometryReader { geo in
            if let imageContent = item.contents.first(where: {
                $0.pasteboardType == NSPasteboard.PasteboardType.png.rawValue ||
                $0.pasteboardType == NSPasteboard.PasteboardType.tiff.rawValue
            }),
            let nsImage = NSImage(data: imageContent.data) {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geo.size.width - 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
                .padding(12)
            }
        }
    }

    private func textPreview(_ item: ClipboardItem) -> some View {
        ScrollView {
            Text(item.plainText ?? item.title)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.9))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
    }

    private func textEditor(_ item: ClipboardItem) -> some View {
        VStack(spacing: 0) {
            TextEditor(text: $editText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)

            HStack {
                Button("Cancel") {
                    isEditing = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                Spacer()

                Button("Save") {
                    saveEdit(item)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .font(.caption)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func saveEdit(_ item: ClipboardItem) {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isEditing = false
            return
        }

        item.plainText = editText
        item.title = String(editText.components(separatedBy: .newlines).first?.prefix(200) ?? "")

        // Update the string content in contents array
        let textData = Data(editText.utf8)
        if let stringContent = item.contents.first(where: {
            $0.pasteboardType == NSPasteboard.PasteboardType.string.rawValue
        }) {
            stringContent.data = textData
        }

        // Recompute contentHash to keep deduplication consistent
        var hasher = SHA256()
        for content in item.contents {
            hasher.update(data: Data(content.pasteboardType.utf8))
            hasher.update(data: content.data)
        }
        item.contentHash = hasher.finalize().map { String(format: "%02x", $0) }.joined()

        do { try modelContext.save() } catch { logger.error("Failed to save edit: \(error.localizedDescription)") }
        isEditing = false
    }

    private var noSelectionView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(.quaternary)

            Text("Select a clip to preview")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}
