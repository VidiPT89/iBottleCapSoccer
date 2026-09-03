import SwiftUI

/// A ladder of Bot matches with rising difficulty. Winning a stage unlocks the next one;
/// the match itself is the normal `MainGameView` flow, pushed on top via `onPlay`.
struct CareerView: View {
    @EnvironmentObject private var localizer: Localizer
    @ObservedObject var viewModel: GameViewModel
    var scene: GameScene
    var onPlay: () -> Void

    @ObservedObject private var career = CareerManager.shared
    @State private var lastResultStage: Int?
    @State private var lastResultWon = false

    var body: some View {
        List {
            ForEach(Array(CareerManager.stages.enumerated()), id: \.offset) { index, difficulty in
                stageRow(index: index, difficulty: difficulty)
            }
        }
        .navigationTitle(localizer.t(.careerTitle))
        .navigationBarTitleDisplayMode(.inline)
        .alert(lastResultWon ? localizer.t(.careerWon) : localizer.t(.fulltime), isPresented: Binding(
            get: { lastResultStage != nil },
            set: { if !$0 { lastResultStage = nil } }
        )) {
            Button(localizer.t(.close), role: .cancel) { lastResultStage = nil }
        }
    }

    private func stageRow(index: Int, difficulty: BotDifficulty) -> some View {
        let locked = index > career.unlockedStage
        let won = index < career.unlockedStage
        return HStack {
            ZStack {
                Circle()
                    .fill(AnyShapeStyle(locked ? AnyShapeStyle(Color.secondary.opacity(0.15)) : AnyShapeStyle(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .topLeading, endPoint: .bottomTrailing))))
                    .frame(width: 40, height: 40)
                Image(systemName: locked ? "lock.fill" : (won ? "checkmark" : "figure.soccer"))
                    .foregroundColor(locked ? .secondary : .black)
                    .font(.system(size: 15, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(localizer.t(.careerStage)) \(index + 1)").font(.headline)
                Text(difficultyLabel(difficulty)).font(.caption).foregroundColor(.secondary)
                if locked {
                    Text(localizer.t(.careerLocked)).font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            if !locked {
                Button(localizer.t(.careerPlay)) {
                    startStage(index: index, difficulty: difficulty)
                }
                .buttonStyle(PrimaryChipButtonStyle())
            }
        }
        .opacity(locked ? 0.5 : 1)
        .padding(.vertical, 4)
    }

    private func startStage(index: Int, difficulty: BotDifficulty) {
        viewModel.onMatchFinished = { won in
            lastResultStage = index
            lastResultWon = won
            if won { CareerManager.shared.recordWin(atStage: index) }
            viewModel.onMatchFinished = nil
        }
        viewModel.startNewMatch(mode: .bot(difficulty))
        onPlay()
    }

    private func difficultyLabel(_ d: BotDifficulty) -> String {
        switch d {
        case .easy: return localizer.t(.botEasy)
        case .medium: return localizer.t(.botMedium)
        case .hard: return localizer.t(.botHard)
        }
    }
}
