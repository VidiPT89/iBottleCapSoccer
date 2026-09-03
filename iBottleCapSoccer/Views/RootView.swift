import SwiftUI
import SpriteKit

enum AppScreen {
    case splash
    case menu
    case game
}

struct RootView: View {
    @State private var screen: AppScreen = .splash
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
                    withAnimation(.easeOut(duration: 0.5)) { screen = .menu }
                }
                .transition(.opacity)
                .zIndex(1)
            case .menu:
                MainMenuView(
                    viewModel: viewModel,
                    onPlay: { withAnimation(.easeOut(duration: 0.35)) { screen = .game } },
                    onPlayOnline: { gcManager.presentMatchmaker() }
                )
                .transition(.opacity)
            case .game:
                MainGameView(viewModel: viewModel, scene: scene) {
                    withAnimation(.easeOut(duration: 0.35)) { screen = .menu }
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
            withAnimation(.easeOut(duration: 0.35)) { screen = .game }
        }
    }
}
