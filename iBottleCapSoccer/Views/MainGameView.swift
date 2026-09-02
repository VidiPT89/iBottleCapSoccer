import SwiftUI
import SpriteKit

struct MainGameView: View {
    @EnvironmentObject private var localizer: Localizer
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var viewModel = GameViewModel()
    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: GameScene.fieldWidth, height: GameScene.fieldHeight))
        s.scaleMode = .aspectFit
        return s
    }()
    @State private var showRules = false

    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            topBar
            ScoreboardView(viewModel: viewModel)
            turnBar
            fieldArea
            Text(localizer.t(.hintText))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 8)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .onAppear {
            scene.viewModel = viewModel
            viewModel.scene = scene
            viewModel.startNewMatch()
        }
        .sheet(isPresented: $showRules) { RulesView() }
    }

    private var topBar: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(ChipButtonStyle())

            Spacer(minLength: 8)
            Button(localizer.language.displayCode) { localizer.toggle() }
                .buttonStyle(ChipButtonStyle())
            Button {
                theme.cycle()
            } label: {
                Image(systemName: theme.theme.icon)
            }
            .buttonStyle(ChipButtonStyle())
            Button(localizer.t(.navRules)) { showRules = true }
                .buttonStyle(ChipButtonStyle())
            Button(localizer.t(.navNewGame)) { viewModel.startNewMatch() }
                .buttonStyle(ChipButtonStyle(primary: true))
        }
        .padding(.horizontal)
    }

    private var turnBar: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.currentTeam == .home ? Brand.orange : Color.gray)
                    .frame(width: 9, height: 9)
                Text(localizer.t(viewModel.currentTeam == .home ? .turnHome : .turnAway))
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.secondary.opacity(0.12)))

            Spacer()

            Text("\(localizer.t(.actionsLeft)) \(viewModel.actionsLeft)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private var fieldArea: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: geo.size.width, height: geo.size.width * (GameScene.fieldHeight / GameScene.fieldWidth))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.5), lineWidth: 6))

                if viewModel.showGoalFlash {
                    Text(localizer.t(.goalText))
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: Brand.orange, radius: 20)
                        .transition(.scale.combined(with: .opacity))
                }

                if viewModel.isFullTime {
                    fullTimeCard
                }
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(GameScene.fieldWidth / GameScene.fieldHeight, contentMode: .fit)
        .padding(.horizontal)
    }

    private var fullTimeCard: some View {
        VStack(spacing: 14) {
            Text(localizer.t(.fulltime)).font(.title2.bold())
            Text("\(viewModel.homeScore) — \(viewModel.awayScore)")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(Brand.orange)
            Button(localizer.t(.restart)) { viewModel.startNewMatch() }
                .buttonStyle(ChipButtonStyle(primary: true))
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ChipButtonStyle: ButtonStyle {
    var primary: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if primary {
                        LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .leading, endPoint: .trailing)
                    } else {
                        LinearGradient(colors: [Color.secondary.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .foregroundColor(primary ? .black : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
