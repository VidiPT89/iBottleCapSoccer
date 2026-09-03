import GameKit
import UIKit
import Combine

/// Handles Game Center auth, turn-based matchmaking, and syncing `OnlineMatchState`
/// between the two devices. A match always has exactly 2 participants; participant
/// index 0 (creation order) plays Home, index 1 plays Away.
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    /// Set whenever GameKit needs to present a view controller (auth sheet, matchmaker).
    /// `GameKitViewControllerPresenter` observes this and presents/dismisses it.
    @Published var presentedViewController: UIViewController?

    /// Bumped whenever a new incoming/updated match is ready to be shown to the player.
    @Published var incomingUpdate: UUID?
    private(set) var pendingState: OnlineMatchState?
    private(set) var pendingLocalTeam: Team = .home

    private var currentMatch: GKTurnBasedMatch?
    private var listenerRegistered = false
    private var wantsMatchmakerAfterAuth = false

    private override init() { super.init() }

    // MARK: - Auth

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                self.presentedViewController = viewController
                return
            }
            self.presentedViewController = nil
            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            if self.isAuthenticated, !self.listenerRegistered {
                GKLocalPlayer.local.register(self)
                self.listenerRegistered = true
            }
            if self.isAuthenticated, self.wantsMatchmakerAfterAuth {
                self.wantsMatchmakerAfterAuth = false
                self.presentMatchmaker()
            }
        }
    }

    // MARK: - Matchmaking

    func presentMatchmaker() {
        guard isAuthenticated else {
            wantsMatchmakerAfterAuth = true
            authenticate()
            return
        }
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        let vc = GKTurnBasedMatchmakerViewController(matchRequest: request)
        vc.turnBasedMatchmakerDelegate = self
        presentedViewController = vc
    }

    // MARK: - Turn submission

    /// Called by GameScene once the acting player's shot has settled and the resulting
    /// state (with `currentTeam` already flipped to the opponent) is ready to send.
    func submitTurn(_ state: OnlineMatchState) {
        guard let match = currentMatch, let data = try? JSONEncoder().encode(state) else { return }
        let next = match.participants.filter { $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }
        if state.isMatchOver {
            match.endMatchInTurn(withMatch: data) { _ in }
        } else {
            match.endTurn(withNextParticipants: next.isEmpty ? match.participants : next, turnTimeout: GKTurnTimeoutDefault, match: data) { _ in }
        }
    }

    /// Team this device plays as within `currentMatch` (creation order: participant 0 = home).
    func localTeam(in match: GKTurnBasedMatch) -> Team {
        let isFirst = match.participants.first?.player?.gamePlayerID == GKLocalPlayer.local.gamePlayerID
        return isFirst ? .home : .away
    }

    func clearIncoming() {
        pendingState = nil
        incomingUpdate = nil
    }
}

// MARK: - GKLocalPlayerListener

extension GameCenterManager: GKLocalPlayerListener {
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        currentMatch = match
        presentedViewController = nil
        pendingLocalTeam = localTeam(in: match)

        if let data = match.matchData, !data.isEmpty, let state = try? JSONDecoder().decode(OnlineMatchState.self, from: data) {
            pendingState = state
        } else {
            // Brand-new match, no turn played yet — this device (always the creator, since
            // it's the only participant who can see an empty match) seeds the kickoff state.
            pendingState = nil
        }
        incomingUpdate = UUID()
    }

    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        currentMatch = match
        if let data = match.matchData, let state = try? JSONDecoder().decode(OnlineMatchState.self, from: data) {
            pendingState = state
            pendingLocalTeam = localTeam(in: match)
            incomingUpdate = UUID()
        }
    }
}

// MARK: - GKTurnBasedMatchmakerViewControllerDelegate

extension GameCenterManager: GKTurnBasedMatchmakerViewControllerDelegate {
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        presentedViewController = nil
    }

    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        presentedViewController = nil
    }
}
