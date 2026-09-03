import Foundation

enum GameMode: Equatable {
    case local
    case bot(BotDifficulty)
    case online

    var isOnline: Bool { self == .online }
}

enum BotDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy, medium, hard

    var id: String { rawValue }

    /// Pause before the bot "reacts", for pacing.
    var thinkingDelay: Double {
        switch self {
        case .easy: return 0.5
        case .medium: return 0.8
        case .hard: return 1.1
        }
    }

    /// Random angle jitter applied to the bot's aim, in degrees.
    var aimJitterDegrees: Double {
        switch self {
        case .easy: return 16
        case .medium: return 8
        case .hard: return 2.5
        }
    }

    /// Random multiplier applied to the computed shot power.
    var powerVarianceRange: ClosedRange<Double> {
        switch self {
        case .easy: return 0.55...1.35
        case .medium: return 0.8...1.15
        case .hard: return 0.92...1.05
        }
    }

    /// Easy bots just nudge the ball forward; medium/hard also look for a clean shot on goal
    /// and pull back a defender to clear danger near their own goal.
    var playsTactically: Bool { self != .easy }

    /// Hard bots pick whichever of their caps gives the best shot, not just the nearest one.
    var picksBestCap: Bool { self == .hard }
}
