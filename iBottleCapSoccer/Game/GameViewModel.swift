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

    static let halfDuration = 15 * 60

    private var timerCancellable: AnyCancellable?
    weak var scene: GameScene?

    var clockText: String {
        let m = timeLeft / 60
        let s = timeLeft % 60
        return String(format: "%02d:%02d", m, s)
    }

    func startNewMatch() {
        homeScore = 0
        awayScore = 0
        half = .first
        timeLeft = Self.halfDuration
        currentTeam = .home
        actionsLeft = 1
        isPaused = false
        isFullTime = false
        scene?.resetKickoff(scorer: nil)
        startTimer()
    }

    private func startTimer() {
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
                self?.scene?.resetKickoff(scorer: nil)
                self?.isPaused = false
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.showGoalFlash = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            self?.scene?.resetKickoff(scorer: team)
        }
    }

    func turnEnded() {
        actionsLeft -= 1
        if actionsLeft <= 0 {
            currentTeam = currentTeam.opponent
            actionsLeft = 1
        }
    }
}
