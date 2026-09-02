import SwiftUI

enum AppScreen {
    case splash
    case menu
    case game
}

struct RootView: View {
    @State private var screen: AppScreen = .splash

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
                MainMenuView {
                    withAnimation(.easeOut(duration: 0.35)) { screen = .game }
                }
                .transition(.opacity)
            case .game:
                MainGameView {
                    withAnimation(.easeOut(duration: 0.35)) { screen = .menu }
                }
                .transition(.opacity)
            }
        }
    }
}
