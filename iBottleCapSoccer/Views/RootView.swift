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
                MainMenuView(viewModel: viewModel) {
                    withAnimation(.easeOut(duration: 0.35)) { screen = .game }
                }
                .transition(.opacity)
            case .game:
                MainGameView(viewModel: viewModel, scene: scene) {
                    withAnimation(.easeOut(duration: 0.35)) { screen = .menu }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            scene.viewModel = viewModel
            viewModel.scene = scene
        }
    }
}
