import Foundation
import Combine

final class GameViewModel: ObservableObject {
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var currentTeam: Team = .home
    @Published var actionsLeft = 1
    @Published var half: MatchHalf = .first
    @Published var timeLeft: Int = GameViewModel.halfDuration
    @Published var isPaused = false
    @Published var showGoalFlash = false
    @Published var isFullTime = false
    @Published var isSimulating = false
    @Published var hasStarted = false
    @Published var mode: GameMode = .local

    /// Which team the bot controls, when `mode` is `.bot`.
    let botTeam: Team = .away
    /// Which team this device plays as, when `mode` is `.online`.
    @Published var localOnlineTeam: Team = .home

    static let halfDuration = 15 * 60

    private var timerCancellable: AnyCancellable?
    private var isMenuPaused = false
    weak var scene: GameScene?

    var clockText: String {
        let m = timeLeft / 60
        let s = timeLeft % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// True when it's this device's turn to act — always true outside of online mode.
    var isMyTurn: Bool {
        guard mode.isOnline else { return true }
        return currentTeam == localOnlineTeam
    }

    // MARK: - Local / bot matches

    func startNewMatch(mode: GameMode = .local) {
        self.mode = mode
        homeScore = 0
        awayScore = 0
        half = .first
        timeLeft = Self.halfDuration
        currentTeam = .home
        actionsLeft = 1
        isPaused = false
        isMenuPaused = false
        isFullTime = false
        hasStarted = true
        scene?.resetKickoff()
        scene?.scheduleBotTurnIfNeeded()
        startTimer()
    }

    /// Called when the match screen is dismissed (back to menu) — freezes the clock without resetting progress.
    func pause() {
        isMenuPaused = true
        isPaused = true
    }

    /// Called when returning to an in-progress match — resumes input/clock unless the match has
    /// already ended. `isPaused` also gates touch input (not just the clock), so it must be
    /// cleared for every mode, including online — the clock itself stays off for online since
    /// `startTimer()` never runs for it.
    func resume() {
        isMenuPaused = false
        guard hasStarted, !isFullTime else { return }
        isPaused = false
    }

    private func startTimer() {
        guard !mode.isOnline else { return } // online matches are turn-based, not clock-based
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard !isPaused, !isSimulating else { return }
        timeLeft -= 1
        if timeLeft <= 0 {
            timeLeft = 0
            handleHalfEnd()
        }
    }

    private func handleHalfEnd() {
        isPaused = true
        if half == .first {
            half = .second
            timeLeft = Self.halfDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                guard let self else { return }
                self.scene?.resetKickoff()
                if !self.isMenuPaused { self.isPaused = false }
                self.scene?.scheduleBotTurnIfNeeded()
            }
        } else {
            timerCancellable?.cancel()
            isFullTime = true
        }
    }

    func goalScored(by team: Team) {
        if team == .home { homeScore += 1 } else { awayScore += 1 }
        showGoalFlash = true
        currentTeam = team.opponent
        actionsLeft = 1

        if mode.isOnline, homeScore >= OnlineMatchState.targetScore || awayScore >= OnlineMatchState.targetScore {
            isFullTime = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.showGoalFlash = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self else { return }
            self.scene?.resetKickoff()
            if self.mode.isOnline {
                self.scene?.submitOnlineTurnIfNeeded()
            } else {
                self.scene?.scheduleBotTurnIfNeeded()
            }
        }
    }

    func turnEnded() {
        actionsLeft -= 1
        if actionsLeft <= 0 {
            currentTeam = currentTeam.opponent
            actionsLeft = 1
        }
    }

    // MARK: - Online matches

    /// Configures this view model from a snapshot received via Game Center and asks the
    /// scene to render it (teleporting nodes, never re-simulating a turn it didn't play).
    func applyOnlineState(_ state: OnlineMatchState, localTeam: Team) {
        mode = .online
        localOnlineTeam = localTeam
        homeScore = state.homeScore
        awayScore = state.awayScore
        currentTeam = Team(rawValue: state.currentTeam) ?? .home
        actionsLeft = 1
        isPaused = false
        isMenuPaused = false
        isFullTime = state.isMatchOver
        hasStarted = true
        timerCancellable?.cancel()
        scene?.applyOnlineSnapshot(state)
    }

    /// This device is the one creating a brand-new online match — seed a fresh kickoff and
    /// send it as the first turn (home always kicks off).
    func seedNewOnlineMatch(localTeam: Team) {
        mode = .online
        localOnlineTeam = localTeam
        homeScore = 0
        awayScore = 0
        currentTeam = .home
        actionsLeft = 1
        isPaused = false
        isMenuPaused = false
        isFullTime = false
        hasStarted = true
        timerCancellable?.cancel()
        scene?.resetKickoff()
        scene?.submitOnlineTurnIfNeeded()
    }
}
