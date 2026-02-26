import Foundation

enum PanelSize: String, CaseIterable, Identifiable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact:  "Compact"
        case .standard: "Default"
        case .large:    "Large"
        }
    }

    var width: CGFloat {
        switch self {
        case .compact:  560
        case .standard: 640
        case .large:    760
        }
    }

    var height: CGFloat {
        switch self {
        case .compact:  420
        case .standard: 500
        case .large:    580
        }
    }
}
