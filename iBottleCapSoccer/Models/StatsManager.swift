import Foundation
import Combine

/// Lightweight lifetime stats, persisted locally. Counts only the player's own side —
/// `.home` in Local/Bot, or this device's team when playing online.
final class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published private(set) var goalsScored: Int {
        didSet { UserDefaults.standard.set(goalsScored, forKey: "fdc_stats_goals") }
    }
    @Published private(set) var matchesPlayed: Int {
        didSet { UserDefaults.standard.set(matchesPlayed, forKey: "fdc_stats_played") }
    }
    @Published private(set) var matchesWon: Int {
        didSet { UserDefaults.standard.set(matchesWon, forKey: "fdc_stats_won") }
    }

    private init() {
        let defaults = UserDefaults.standard
        goalsScored = defaults.integer(forKey: "fdc_stats_goals")
        matchesPlayed = defaults.integer(forKey: "fdc_stats_played")
        matchesWon = defaults.integer(forKey: "fdc_stats_won")
    }

    func recordGoal() {
        goalsScored += 1
    }

    func recordMatch(won: Bool) {
        matchesPlayed += 1
        if won { matchesWon += 1 }
    }
}
