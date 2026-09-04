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
    /// Team owed a free-kick bonus turn from 3 consecutive fouls, if any — must travel with
    /// the snapshot, since it's decided on the fouling device but has to be honored by the
    /// device that plays the owed team's next turn. Missing on older/decoded data = no bonus.
    var extraTurnOwed: String? = nil

    var isMatchOver: Bool {
        homeScore >= Self.targetScore || awayScore >= Self.targetScore
    }
}
