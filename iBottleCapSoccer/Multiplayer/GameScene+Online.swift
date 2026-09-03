import SpriteKit

extension GameScene {

    /// Captures the current board as a `Codable` snapshot to send to the opponent.
    func snapshot() -> OnlineMatchState {
        let caps = (homeCaps + awayCaps).map {
            OnlineMatchState.CapState(name: $0.name ?? "", x: Double($0.position.x), y: Double($0.position.y))
        }
        return OnlineMatchState(
            caps: caps,
            ballX: Double(ball.position.x),
            ballY: Double(ball.position.y),
            homeScore: viewModel?.homeScore ?? 0,
            awayScore: viewModel?.awayScore ?? 0,
            currentTeam: viewModel?.currentTeam.rawValue ?? Team.home.rawValue
        )
    }

    /// Renders a snapshot received from Game Center by teleporting nodes — never re-simulates
    /// a turn this device didn't play, since physics isn't guaranteed identical across devices.
    func applyOnlineSnapshot(_ state: OnlineMatchState) {
        let byName = Dictionary(uniqueKeysWithValues: (homeCaps + awayCaps).map { ($0.name ?? "", $0) })
        for cs in state.caps {
            guard let node = byName[cs.name] else { continue }
            node.position = CGPoint(x: cs.x, y: cs.y)
            node.physicsBody?.velocity = .zero
        }
        ball.position = CGPoint(x: state.ballX, y: state.ballY)
        ball.physicsBody?.velocity = .zero
        wasSimulating = false
        awaitingReset = false
        viewModel?.isSimulating = false
        highlightActiveTeam()
    }

    /// Sends the current board state to Game Center as the result of this device's turn.
    func submitOnlineTurnIfNeeded() {
        guard viewModel?.mode.isOnline == true else { return }
        GameCenterManager.shared.submitTurn(snapshot())
    }
}
