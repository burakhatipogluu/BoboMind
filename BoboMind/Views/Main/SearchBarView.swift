import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @Binding var filterType: ContentType?
    @FocusState.Binding var isFocused: Bool

    private let filterTypes: [ContentType] = [.plainText, .image, .richText, .fileURL]

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(nsImage: AppLogo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                TextField("Search clips…  /regex/", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .accessibilityLabel("Search clipboard history")

                if !text.isEmpty || filterType != nil {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            text = ""
                            filterType = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(
                        label: "All",
                        systemImage: "tray.full",
                        isSelected: filterType == nil
                    ) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            filterType = nil
                        }
                    }

                    ForEach(filterTypes) { type in
                        FilterChip(
                            label: type.displayName,
                            systemImage: type.sfSymbol,
                            isSelected: filterType == type
                        ) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                filterType = filterType == type ? nil : type
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        // Note: blanket .animation() removed to prevent spillover; clear button uses explicit withAnimation
    }
}

struct FilterChip: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(label)")
    }
}
