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

enum PopupPosition: String, CaseIterable, Identifiable {
    case center
    case mouseCursor
    case topCenter
    case bottomCenter
    case leftCenter
    case rightCenter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .center:       "Center"
        case .mouseCursor:  "Mouse Cursor"
        case .topCenter:    "Top Center"
        case .bottomCenter: "Bottom Center"
        case .leftCenter:   "Left Center"
        case .rightCenter:  "Right Center"
        }
    }
}
