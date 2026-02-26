import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isSearchFocused: Bool

    @AppStorage(Constants.UserDefaultsKeys.showPreviewPanel) private var showPreview = true
    @State private var selectedItemID: PersistentIdentifier?
    @State private var cachedFilteredItems: [ClipboardItem] = []
    // TODO: @Query may cause duplicate fetches when multiple views use the same query; consider shared data source
    @Query(sort: \ClipboardItem.lastUsedAt, order: .reverse)
    private var allItems: [ClipboardItem]
    @Query(sort: \ClipGroup.sortOrder)
    private var groups: [ClipGroup]
    @State private var searchDebounceTask: Task<Void, Never>?

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Search bar
            SearchBarView(
                text: $state.searchText,
                filterType: $state.filterType,
                isFocused: $isSearchFocused
            )

            Divider()

            // Content area
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                
                Divider()

                if appState.sidebarFilter == .snippets {
                    SnippetListView()
                        .frame(maxWidth: .infinity)
                } else {
                    clipListSection
                        .frame(minWidth: 260)

                    if showPreview {
                        Divider()

                        PreviewPanelView(item: selectedItem)
                            .frame(minWidth: 200, idealWidth: 280)
                    }
                }
            }

            Divider()

            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .onAppear {
            isSearchFocused = true
            recomputeFilteredItems()
            if selectedItemID == nil {
                selectedItemID = cachedFilteredItems.first?.persistentModelID
            }
        }
        .onChange(of: allItems.map(\.persistentModelID)) {
            recomputeFilteredItems()
        }
        .onChange(of: appState.searchText) {
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
                recomputeFilteredItems()
                selectedItemID = cachedFilteredItems.first?.persistentModelID
            }
        }
        .onChange(of: appState.filterType) {
            recomputeFilteredItems()
            selectedItemID = cachedFilteredItems.first?.persistentModelID
        }
        .onChange(of: appState.sidebarFilter) {
            recomputeFilteredItems()
            selectedItemID = cachedFilteredItems.first?.persistentModelID
        }
        .onKeyPress(.return) {
            if let item = selectedItem {
                pasteAndDismiss(item)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: .init(charactersIn: "\r"), phases: .down) { press in
            if press.modifiers.contains(.shift), let item = selectedItem {
                pasteAndDismiss(item, plainTextOnly: true)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            moveSelection(direction: .down)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(direction: .up)
            return .handled
        }
        .onKeyPress(.delete) {
            if let item = selectedItem {
                appState.deleteItem(item)
                selectedItemID = cachedFilteredItems.first?.persistentModelID
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: .init(charactersIn: "p"), phases: .down) { press in
            if press.modifiers.contains(.command), let item = selectedItem {
                appState.togglePin(item)
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 4) {
            sidebarButton(icon: "tray.full", label: "All", filter: .all)
            sidebarButton(icon: "pin.fill", label: "Pinned", filter: .pinned)
            sidebarButton(icon: "text.quote", label: "Snippets", filter: .snippets)

            if !groups.isEmpty {
                Divider()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                ForEach(groups) { group in
                    sidebarButton(
                        icon: group.icon,
                        label: group.name,
                        filter: .group(group.persistentModelID)
                    )
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .frame(width: 52)
    }

    private func sidebarButton(icon: String, label: String, filter: AppState.SidebarFilter) -> some View {
        let isSelected = appState.sidebarFilter == filter
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                appState.sidebarFilter = filter
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 36, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                Text(label)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Clip List

    private var clipListSection: some View {
        Group {
            if cachedFilteredItems.isEmpty {
                EmptyStateView(isSearching: !appState.searchText.isEmpty || appState.filterType != nil)
            } else {
                ScrollViewReader { proxy in
                    List(selection: $selectedItemID) {
                        ForEach(cachedFilteredItems) { item in
                            ClipRowView(item: item, isSelected: selectedItemID == item.persistentModelID)
                                .tag(item.persistentModelID)
                                .id(item.persistentModelID)
                                .onTapGesture(count: 2) {
                                    pasteAndDismiss(item)
                                }
                                .onTapGesture(count: 1) {
                                    selectedItemID = item.persistentModelID
                                }
                                .contextMenu {
                                    clipContextMenu(for: item)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onChange(of: selectedItemID) { _, newValue in
                        if let id = newValue {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func clipContextMenu(for item: ClipboardItem) -> some View {
        Button("Paste") {
            pasteAndDismiss(item)
        }

        if item.plainText != nil {
            Button("Paste as Plain Text") {
                pasteAndDismiss(item, plainTextOnly: true)
            }
        }

        Divider()

        Button(item.isPinned ? "Unpin" : "Pin") {
            appState.togglePin(item)
        }

        // Move to Group submenu
        if !groups.isEmpty {
            Menu("Move to Group") {
                Button("None") {
                    item.group = nil
                    do { try modelContext.save() } catch { logger.error("Failed to save: \(error.localizedDescription)") }
                }

                Divider()

                ForEach(groups) { group in
                    Button {
                        item.group = group
                        do { try modelContext.save() } catch { logger.error("Failed to save: \(error.localizedDescription)") }
                    } label: {
                        Label(group.name, systemImage: group.icon)
                    }
                }
            }
        }

        Divider()

        Button("Delete", role: .destructive) {
            appState.deleteItem(item)
        }
    }

    // MARK: - Data

    private var selectedItem: ClipboardItem? {
        guard let id = selectedItemID else { return nil }
        do {
            guard let item = try? modelContext.model(for: id) as? ClipboardItem,
                  !item.isDeleted else {
                return nil
            }
            // Access a property to trigger fault; if model is gone this may throw
            _ = item.title
            return item
        } catch {
            return nil
        }
    }

    private func recomputeFilteredItems() {
        var result: [ClipboardItem]

        // Apply sidebar filter
        switch appState.sidebarFilter {
        case .all:
            result = allItems
        case .pinned:
            result = allItems.filter(\.isPinned)
        case .snippets:
            cachedFilteredItems = []
            return
        case .group(let groupID):
            if let group = modelContext.model(for: groupID) as? ClipGroup {
                result = group.items.sorted { $0.lastUsedAt > $1.lastUsedAt }
            } else {
                result = allItems
            }
        }

        // Pinned first (only for "all" filter)
        if case .all = appState.sidebarFilter {
            let pinned = result.filter(\.isPinned)
            let unpinned = result.filter { !$0.isPinned }
            result = pinned + unpinned
        }

        // Filter by content type
        if let filterType = appState.filterType {
            result = result.filter { $0.contentType == filterType }
        }

        // Filter by search text
        if !appState.searchText.isEmpty {
            let query = appState.searchText

            // 1) Regex mode: /pattern/ syntax
            if query.hasPrefix("/") && query.hasSuffix("/") && query.count > 2 {
                let regexPattern = String(query.dropFirst().dropLast())
                guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
                    cachedFilteredItems = []
                    return
                }
                result = result.filter { item in
                    let text = item.plainText ?? item.title
                    let range = NSRange(text.startIndex..., in: text)
                    return regex.firstMatch(in: text, range: range) != nil
                }
            } else {
                // 2) Exact match first
                let exactMatches = result.filter {
                    $0.title.localizedCaseInsensitiveContains(query) ||
                    ($0.plainText?.localizedCaseInsensitiveContains(query) ?? false)
                }

                if !exactMatches.isEmpty {
                    result = exactMatches
                } else {
                    // 3) Fuzzy match fallback
                    let scored = result.compactMap { item -> (ClipboardItem, Int)? in
                        let text = item.plainText ?? item.title
                        guard let m = FuzzyMatcher.match(pattern: query, in: text) else { return nil }
                        return (item, m.score)
                    }
                    result = scored.sorted { $0.1 > $1.1 }.map(\.0)
                }
            }
        }

        cachedFilteredItems = result
    }

    // MARK: - Navigation

    private enum MoveDirection { case up, down }

    private func moveSelection(direction: MoveDirection) {
        let items = cachedFilteredItems
        guard !items.isEmpty else { return }

        guard let currentID = selectedItemID,
              let currentIndex = items.firstIndex(where: { $0.persistentModelID == currentID }) else {
            selectedItemID = items.first?.persistentModelID
            return
        }

        let newIndex: Int
        switch direction {
        case .down:
            newIndex = min(currentIndex + 1, items.count - 1)
        case .up:
            newIndex = max(currentIndex - 1, 0)
        }

        selectedItemID = items[newIndex].persistentModelID
    }

    private func pasteAndDismiss(_ item: ClipboardItem, plainTextOnly: Bool = false) {
        appState.selectAndPaste(item, plainTextOnly: plainTextOnly)
        // Use animateOut() so onClose callback fires and appState.panel is properly cleaned up
        if let panel = appState.panel, panel.isVisible {
            panel.animateOut()
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 8) {
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Text("**\u{21A9}** Paste")
                Text("**\u{21E7}\u{21A9}** Plain")
                Text("**\u{2318}P** Pin")
                Text("**\u{232B}** Delete")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var statusText: String {
        let total = allItems.count
        let shown = cachedFilteredItems.count
        if shown == total {
            return "\(total) clips"
        }
        return "\(shown) of \(total) clips"
    }
}
