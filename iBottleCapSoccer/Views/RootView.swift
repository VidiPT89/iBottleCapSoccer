import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.5)) { showSplash = false }
                }
                .transition(.opacity)
                .zIndex(1)
            } else {
                MainGameView()
                    .transition(.opacity)
            }
        }
    }
}
