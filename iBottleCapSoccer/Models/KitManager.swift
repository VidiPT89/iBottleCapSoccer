import SpriteKit
import Combine

/// A small fixed palette of cap colors a player can pick per team — the "paint your caps"
/// personalization from the design doc, kept simple (no per-cap patterns/decals).
enum CapKit: String, CaseIterable, Identifiable {
    case orange, dark, red, blue, green, purple

    var id: String { rawValue }

    var base: SKColor {
        switch self {
        case .orange: return SKColor(red: 0.83, green: 0.38, blue: 0.02, alpha: 1)
        case .dark: return SKColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1)
        case .red: return SKColor(red: 0.62, green: 0.08, blue: 0.08, alpha: 1)
        case .blue: return SKColor(red: 0.08, green: 0.24, blue: 0.62, alpha: 1)
        case .green: return SKColor(red: 0.08, green: 0.42, blue: 0.18, alpha: 1)
        case .purple: return SKColor(red: 0.35, green: 0.1, blue: 0.5, alpha: 1)
        }
    }

    var highlight: SKColor {
        switch self {
        case .orange: return SKColor(red: 1, green: 0.72, blue: 0.42, alpha: 1)
        case .dark: return SKColor(red: 0.42, green: 0.42, blue: 0.46, alpha: 1)
        case .red: return SKColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 1)
        case .blue: return SKColor(red: 0.45, green: 0.6, blue: 0.95, alpha: 1)
        case .green: return SKColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 1)
        case .purple: return SKColor(red: 0.75, green: 0.5, blue: 0.9, alpha: 1)
        }
    }
}

final class KitManager: ObservableObject {
    static let shared = KitManager()

    @Published var homeKit: CapKit {
        didSet { UserDefaults.standard.set(homeKit.rawValue, forKey: "fdc_kit_home") }
    }
    @Published var awayKit: CapKit {
        didSet { UserDefaults.standard.set(awayKit.rawValue, forKey: "fdc_kit_away") }
    }

    private init() {
        let defaults = UserDefaults.standard
        homeKit = CapKit(rawValue: defaults.string(forKey: "fdc_kit_home") ?? "") ?? .orange
        awayKit = CapKit(rawValue: defaults.string(forKey: "fdc_kit_away") ?? "") ?? .dark
    }
}
