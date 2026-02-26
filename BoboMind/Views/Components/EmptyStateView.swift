import SwiftUI

struct EmptyStateView: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 16) {
            if isSearching {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(.quaternary)

                Text("No matching clips")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Try a different search term")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Image(nsImage: AppLogo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Welcome to BoboMind")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)

                VStack(spacing: 6) {
                    instructionRow("1", "Copy anything from any app")
                    instructionRow("2", "Press ⌘⇧V to open BoboMind")
                    instructionRow("3", "Select a clip and press Return to paste")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Text(number)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
                .foregroundStyle(Color.accentColor)
            Text(text)
        }
    }
}
