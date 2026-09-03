import SwiftUI
import SpriteKit

struct MainGameView: View {
    @EnvironmentObject private var localizer: Localizer
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject var viewModel: GameViewModel
    var scene: GameScene
    @State private var showRules = false

    var onExit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ScoreboardView(viewModel: viewModel)
                turnBar
                fieldArea
                Text(localizer.t(.hintText))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer(minLength: 0)
            }
            .padding(.top, 10)
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle(localizer.t(.appTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onExit) {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(localizer.t(.navRules)) { showRules = true }
                        Button(localizer.t(.navNewGame)) { viewModel.startNewMatch() }
                        Divider()
                        Picker(selection: $localizer.language) {
                            Text("Português").tag(AppLanguage.pt)
                            Text("English").tag(AppLanguage.en)
                        } label: {
                            Label(localizer.language == .pt ? "Português" : "English", systemImage: "globe")
                        }
                        .pickerStyle(.inline)
                        Picker(selection: $theme.theme) {
                            Label("System", systemImage: AppTheme.system.icon).tag(AppTheme.system)
                            Label("Light", systemImage: AppTheme.light.icon).tag(AppTheme.light)
                            Label("Dark", systemImage: AppTheme.dark.icon).tag(AppTheme.dark)
                        } label: {
                            Label("Theme", systemImage: theme.theme.icon)
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            if viewModel.hasStarted {
                viewModel.resume()
            } else {
                viewModel.startNewMatch()
            }
        }
        .onDisappear {
            viewModel.pause()
        }
        .sheet(isPresented: $showRules) {
            RulesView()
                .preferredColorScheme(theme.theme.colorScheme)
        }
    }

    private var turnBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.currentTeam == .home ? Brand.orange : Color.gray)
                .frame(width: 9, height: 9)
            Text(localizer.t(viewModel.currentTeam == .home ? .turnHome : .turnAway))
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.secondary.opacity(0.12)))
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
                .buttonStyle(PrimaryChipButtonStyle())
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PrimaryChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
