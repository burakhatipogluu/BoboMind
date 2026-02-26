import SwiftUI

struct ClipTypeIcon: View {
    let contentType: ContentType
    var size: CGFloat = 14

    var body: some View {
        Image(systemName: contentType.sfSymbol)
            .font(.system(size: size))
            .foregroundStyle(.secondary)
            .frame(width: size + 6, height: size + 6)
    }
}
