import Foundation

/// Full snapshot of the match, sent as `matchData` at the end of every online turn.
/// The receiving device applies it directly (teleports nodes) — it never re-simulates
/// physics for a turn it didn't play, since SpriteKit physics isn't guaranteed
/// bit-identical across devices/OS versions.
struct OnlineMatchState: Codable {
    struct CapState: Codable {
        let name: String
        let x: Double
        let y: Double
    }

    static let targetScore = 5

    var caps: [CapState]
    var ballX: Double
    var ballY: Double
    var homeScore: Int
    var awayScore: Int
    var currentTeam: String

    var isMatchOver: Bool {
        homeScore >= Self.targetScore || awayScore >= Self.targetScore
    }
}
