import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"

    var id: String { self.rawValue }

    var localizedName: String {
        switch self {
        case .light: return L10n.lightMode
        case .dark: return L10n.darkMode
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}
