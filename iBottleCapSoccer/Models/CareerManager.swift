import Foundation
import Combine

/// A short, fixed ladder of Bot opponents with rising difficulty — the "campeonato" progression
/// from the design doc, kept lightweight (no unlockable content, just sequential access).
final class CareerManager: ObservableObject {
    static let shared = CareerManager()

    static let stages: [BotDifficulty] = [.easy, .easy, .medium, .medium, .hard, .hard, .hard]

    /// Index of the highest stage the player has unlocked (i.e. can attempt).
    @Published var unlockedStage: Int {
        didSet { UserDefaults.standard.set(unlockedStage, forKey: "fdc_career_unlocked") }
    }

    private init() {
        unlockedStage = UserDefaults.standard.integer(forKey: "fdc_career_unlocked")
    }

    func recordWin(atStage index: Int) {
        guard index == unlockedStage, unlockedStage < Self.stages.count - 1 else { return }
        unlockedStage += 1
    }
}
