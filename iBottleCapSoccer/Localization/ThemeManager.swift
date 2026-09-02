import SwiftUI

enum AppTheme: String {
    case system
    case light
    case dark

    var icon: String {
        switch self {
        case .system: return "gearshape.fill"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "fdc_theme") }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "fdc_theme") ?? AppTheme.system.rawValue
        theme = AppTheme(rawValue: saved) ?? .system
    }

    func cycle() {
        switch theme {
        case .system: theme = .light
        case .light: theme = .dark
        case .dark: theme = .system
        }
    }
}
