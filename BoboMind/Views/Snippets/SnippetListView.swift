import SwiftUI
import SwiftData

struct SnippetListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Snippet.title) private var snippets: [Snippet]
    @State private var showingEditor = false
    @State private var editingSnippet: Snippet?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Snippets")
                    .font(.headline)
                Spacer()
                Button {
                    editingSnippet = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if snippets.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(.quaternary)
                    Text("No snippets yet")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Text("Create reusable text templates")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(snippets) { snippet in
                        SnippetRowView(snippet: snippet)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                pasteSnippet(snippet)
                            }
                            .contextMenu {
                                Button("Copy to Clipboard") {
                                    pasteSnippet(snippet)
                                }
                                Button("Edit") {
                                    editingSnippet = snippet
                                    showingEditor = true
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(snippet)
                                    do { try modelContext.save() } catch { logger.error("Failed to delete snippet: \(error.localizedDescription)") }
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .onChange(of: showingEditor) { _, show in
            if show {
                SnippetEditorWindow.show(snippet: editingSnippet, modelContext: modelContext) {
                    showingEditor = false
                }
            }
        }
    }

    private func pasteSnippet(_ snippet: Snippet) {
        appState.pasteService.copySnippetToPasteboard(text: snippet.content)
        snippet.useCount += 1
        do { try modelContext.save() } catch { logger.error("Failed to save snippet: \(error.localizedDescription)") }
    }
}

struct SnippetRowView: View {
    let snippet: Snippet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(snippet.title)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)

                if !snippet.keyword.isEmpty {
                    Text(snippet.keyword)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }

                Spacer()

                if snippet.useCount > 0 {
                    Text("\(snippet.useCount)x")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(snippet.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct SnippetEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let snippet: Snippet?
    var onDismiss: () -> Void = {}

    @State private var title = ""
    @State private var content = ""
    @State private var keyword = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(snippet == nil ? "New Snippet" : "Edit Snippet")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)

                TextField("Keyword (optional)", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                Text("Content")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
            }

            HStack(spacing: 12) {
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)

                Button(snippet == nil ? "Create" : "Save") {
                    saveSnippet()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || content.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            if let snippet {
                title = snippet.title
                content = snippet.content
                keyword = snippet.keyword
            }
        }
    }

    private func saveSnippet() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespaces)

        if let snippet {
            snippet.title = trimmedTitle
            snippet.content = content
            snippet.keyword = trimmedKeyword
        } else {
            let newSnippet = Snippet(title: trimmedTitle, content: content, keyword: trimmedKeyword)
            modelContext.insert(newSnippet)
        }

        do { try modelContext.save() } catch { logger.error("Failed to save snippet: \(error.localizedDescription)") }
        onDismiss()
    }
}
