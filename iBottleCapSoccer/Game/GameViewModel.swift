import Foundation
import Combine

final class GameViewModel: ObservableObject {
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var currentTeam: Team = .home
    @Published var actionsLeft = GameViewModel.actionsPerTurn
    @Published var half: MatchHalf = .first
    @Published var timeLeft: Int = GameViewModel.halfDuration
    @Published var isPaused = false
    @Published var showGoalFlash = false
    @Published var isFullTime = false
    @Published var isSimulating = false
    @Published var hasStarted = false
    @Published var mode: GameMode = .local
    /// Optional early-finish goal target for Local/Bot matches (e.g. "first to 5") — the clock
    /// stays the hard cap either way. `nil` means "no limit, play the full 2x15min". Online
    /// always uses its own fixed `OnlineMatchState.targetScore`, independent of this.
    @Published var goalTarget: Int?
    /// Transient banner text for a foul or an earned free kick — mirrors `showGoalFlash`.
    @Published var foulFlash: String?
    /// Team owed a free-kick bonus turn from 3 consecutive fouls, if any. Not `private`: in
    /// online mode this must be read into and applied from `OnlineMatchState` (see
    /// `GameScene+Online.swift`), since a decision made on the fouling device is meaningless
    /// unless it's carried over to the device that actually plays the owed team's next turn.
    var extraTurnOwed: Team?
    /// Set by `CareerView` before starting a stage — fired once the match ends, `true` if the
    /// player (home) won. Decoupled from view lifecycle so it fires even if the career screen
    /// isn't the top of the navigation stack when the match finishes.
    var onMatchFinished: ((Bool) -> Void)?
    /// True while the current match is a Career stage — lets `MainGameView` offer "Back to
    /// Career" instead of "Play Again" on the full-time card (replaying in place would silently
    /// desync from the ladder, since `onMatchFinished` only fires once per `startStage` call).
    @Published var isCareerMatch = false

    /// Which team the bot controls, when `mode` is `.bot`.
    let botTeam: Team = .away
    /// Which team this device plays as, when `mode` is `.online`.
    @Published var localOnlineTeam: Team = .home

    static let halfDuration = 15 * 60
    /// One flick per turn, then it passes to the other team — simpler than the official
    /// "1-3 actions" rule (tried as 2 actions, but reverted: it didn't feel right in practice).
    static let actionsPerTurn = 1

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

    func startNewMatch(mode: GameMode = .local, goalTarget: Int? = nil) {
        self.mode = mode
        self.goalTarget = goalTarget
        // Cleared by default so an abandoned Career attempt (left before finishing) can never
        // leak its completion callback into an unrelated match started afterward — CareerView
        // re-assigns it right after calling this, before any goal can possibly be scored.
        onMatchFinished = nil
        isCareerMatch = false
        homeScore = 0
        awayScore = 0
        half = .first
        timeLeft = Self.halfDuration
        currentTeam = .home
        actionsLeft = Self.actionsPerTurn
        extraTurnOwed = nil
        foulFlash = nil
        statsRecorded = false
        isPaused = false
        isMenuPaused = false
        isFullTime = false
        hasStarted = true
        scene?.resetKickoff()
        scene?.scheduleBotTurnIfNeeded()
        startTimer()
        SoundManager.shared.play(.whistle)
        SoundManager.shared.startAmbientLoop()
    }

    /// Called when the match screen is dismissed (back to menu) — freezes the clock without resetting progress.
    func pause() {
        isMenuPaused = true
        isPaused = true
        SoundManager.shared.stopAmbientLoop()
    }

    /// Called when returning to an in-progress match — resumes input/clock unless the match has
    /// already ended. `isPaused` also gates touch input (not just the clock), so it must be
    /// cleared for every mode, including online — the clock itself stays off for online since
    /// `startTimer()` never runs for it.
    func resume() {
        isMenuPaused = false
        guard hasStarted, !isFullTime else { return }
        isPaused = false
        SoundManager.shared.startAmbientLoop()
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
                SoundManager.shared.play(.whistle)
            }
        } else {
            timerCancellable?.cancel()
            isFullTime = true
            SoundManager.shared.play(.whistle)
            SoundManager.shared.stopAmbientLoop()
            recordMatchResultIfNeeded()
        }
    }

    /// Which side represents "the player" for stats purposes: `.home` in Local/Bot, or this
    /// device's own team when playing online.
    private var playerTeam: Team { mode.isOnline ? localOnlineTeam : .home }
    private var statsRecorded = false

    private func recordMatchResultIfNeeded() {
        guard !statsRecorded else { return }
        statsRecorded = true
        let won = playerTeam == .home ? homeScore > awayScore : awayScore > homeScore
        StatsManager.shared.recordMatch(won: won)
        onMatchFinished?(won)
    }

    func goalScored(by team: Team) {
        if team == .home { homeScore += 1 } else { awayScore += 1 }
        if team == playerTeam { StatsManager.shared.recordGoal() }
        showGoalFlash = true
        currentTeam = team.opponent
        actionsLeft = Self.actionsPerTurn

        if mode.isOnline, homeScore >= OnlineMatchState.targetScore || awayScore >= OnlineMatchState.targetScore {
            isFullTime = true
            recordMatchResultIfNeeded()
        } else if !mode.isOnline, let goalTarget, homeScore >= goalTarget || awayScore >= goalTarget {
            isFullTime = true
            timerCancellable?.cancel()
            SoundManager.shared.play(.whistle)
            SoundManager.shared.stopAmbientLoop()
            recordMatchResultIfNeeded()
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

    /// Consumes one action. Returns `true` when that was the last one and the turn passed
    /// to the other team — callers that only care about turn *boundaries* (e.g. submitting
    /// an online turn) should check this instead of assuming every action ends the turn.
    @discardableResult
    func turnEnded() -> Bool {
        actionsLeft -= 1
        guard actionsLeft <= 0 else { return false }
        if extraTurnOwed == currentTeam {
            // This team just played the free kick they were owed — give them one more turn
            // instead of alternating away, then the streak is spent.
            extraTurnOwed = nil
            actionsLeft = Self.actionsPerTurn
            return true
        }
        currentTeam = currentTeam.opponent
        actionsLeft = Self.actionsPerTurn
        return true
    }

    /// Called when a team charges an opponent cap without touching the ball first, three times
    /// in a row — the opponent earns an extra, uninterrupted turn right after their next one.
    func grantFreeKick(to team: Team) {
        extraTurnOwed = team
        foulFlash = "freeKick"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            if self?.foulFlash == "freeKick" { self?.foulFlash = nil }
        }
    }

    func reportFoul(team: Team, streak: Int) {
        foulFlash = "foul:\(streak)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            if self?.foulFlash == "foul:\(streak)" { self?.foulFlash = nil }
        }
    }

    // MARK: - Online matches

    /// Configures this view model from a snapshot received via Game Center and asks the
    /// scene to render it (teleporting nodes, never re-simulating a turn it didn't play).
    func applyOnlineState(_ state: OnlineMatchState, localTeam: Team) {
        let isFirstTime = !hasStarted
        let wasFullTime = isFullTime
        mode = .online
        localOnlineTeam = localTeam
        if isFirstTime { onMatchFinished = nil }
        homeScore = state.homeScore
        awayScore = state.awayScore
        currentTeam = Team(rawValue: state.currentTeam) ?? .home
        actionsLeft = Self.actionsPerTurn
        extraTurnOwed = state.extraTurnOwed.flatMap { Team(rawValue: $0) }
        isPaused = false
        isMenuPaused = false
        isFullTime = state.isMatchOver
        hasStarted = true
        timerCancellable?.cancel()
        scene?.applyOnlineSnapshot(state)
        if isFirstTime {
            statsRecorded = false
            SoundManager.shared.play(.whistle)
        } else if isFullTime, !wasFullTime {
            SoundManager.shared.play(.whistle)
            recordMatchResultIfNeeded()
        }
    }

    /// This device is the one creating a brand-new online match — seed a fresh kickoff and
    /// send it as the first turn (home always kicks off).
    func seedNewOnlineMatch(localTeam: Team) {
        mode = .online
        localOnlineTeam = localTeam
        onMatchFinished = nil
        isCareerMatch = false
        homeScore = 0
        awayScore = 0
        currentTeam = .home
        actionsLeft = Self.actionsPerTurn
        extraTurnOwed = nil
        foulFlash = nil
        statsRecorded = false
        isPaused = false
        isMenuPaused = false
        isFullTime = false
        hasStarted = true
        timerCancellable?.cancel()
        scene?.resetKickoff()
        scene?.submitOnlineTurnIfNeeded()
        SoundManager.shared.play(.whistle)
    }
}
