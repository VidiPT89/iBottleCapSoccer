import SwiftUI
import SpriteKit

enum AppScreen {
    case splash
    case app
}

struct RootView: View {
    @State private var screen: AppScreen = .splash
    @State private var showGame = false
    @State private var showTraining = false
    @State private var showCareer = false
    @StateObject private var viewModel = GameViewModel()
    @ObservedObject private var gcManager = GameCenterManager.shared
    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: GameScene.fieldWidth, height: GameScene.fieldHeight))
        s.scaleMode = .aspectFit
        return s
    }()

    var body: some View {
        ZStack {
            switch screen {
            case .splash:
                SplashView {
                    withAnimation(.easeOut(duration: 0.5)) { screen = .app }
                }
                .transition(.opacity)
                .zIndex(1)
            case .app:
                // Real push navigation (not a manual view switch) so the system back button
                // and the standard edge-swipe-to-go-back gesture both work out of the box.
                NavigationStack {
                    MainMenuView(
                        viewModel: viewModel,
                        onPlay: { showGame = true },
                        onPlayOnline: { gcManager.presentMatchmaker() },
                        onTraining: { showTraining = true },
                        onCareer: { showCareer = true }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(isPresented: $showGame) {
                        MainGameView(viewModel: viewModel, scene: scene)
                    }
                    .navigationDestination(isPresented: $showTraining) {
                        PenaltyTrainingView()
                    }
                    .navigationDestination(isPresented: $showCareer) {
                        CareerView(viewModel: viewModel, scene: scene, onPlay: { showGame = true })
                    }
                }
                .transition(.opacity)
            }
        }
        .background(GameKitViewControllerPresenter(manager: gcManager))
        .onAppear {
            scene.viewModel = viewModel
            viewModel.scene = scene
            scene.prepareIfNeeded()
        }
        .onChange(of: gcManager.incomingUpdate) { newValue in
            guard newValue != nil else { return }
            if let state = gcManager.pendingState {
                viewModel.applyOnlineState(state, localTeam: gcManager.pendingLocalTeam)
            } else {
                viewModel.seedNewOnlineMatch(localTeam: gcManager.pendingLocalTeam)
            }
            gcManager.clearIncoming()
            showGame = true
        }
    }
}
