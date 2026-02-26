import SwiftUI

struct ToastItem: Equatable {
    let isSuccess: Bool
    let title: String
    let detail: String
}

struct ToastView: View {
    let item: ToastItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(item.isSuccess ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(.callout, weight: .semibold))

                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(0.10), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}
