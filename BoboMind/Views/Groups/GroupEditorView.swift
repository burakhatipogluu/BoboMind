import SwiftUI
import SwiftData

struct GroupEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ClipGroup.sortOrder, order: .reverse) private var existingGroups: [ClipGroup]

    @State private var name = ""
    @State private var selectedIcon = "folder.fill"

    private let iconOptions = [
        "folder.fill", "star.fill", "bookmark.fill", "tag.fill",
        "heart.fill", "flag.fill", "bolt.fill", "leaf.fill",
        "briefcase.fill", "house.fill", "globe", "doc.fill",
        "paintbrush.fill", "wrench.fill", "cup.and.saucer.fill", "music.note"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("New Group")
                .font(.headline)

            TextField("Group name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)

            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedIcon == icon ? Color.accentColor : Color.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createGroup()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 340)
    }

    private func createGroup() {
        let nextSortOrder = (existingGroups.first?.sortOrder ?? -1) + 1
        let group = ClipGroup(name: name.trimmingCharacters(in: .whitespaces), icon: selectedIcon, sortOrder: nextSortOrder)
        modelContext.insert(group)
        do { try modelContext.save() } catch { logger.error("Failed to save group: \(error.localizedDescription)") }
        dismiss()
    }
}
