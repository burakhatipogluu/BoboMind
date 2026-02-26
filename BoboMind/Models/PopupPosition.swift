import Foundation

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
