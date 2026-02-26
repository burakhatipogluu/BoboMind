import SwiftUI

struct TimeAgoText: View {
    let date: Date

    var body: some View {
        Text(date, format: .relative(presentation: .named))
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
}
