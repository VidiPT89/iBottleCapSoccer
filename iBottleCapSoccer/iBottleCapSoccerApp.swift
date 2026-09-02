import SwiftUI

@main
struct iBottleCapSoccerApp: App {
    @StateObject private var localizer = Localizer.shared
    @StateObject private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(localizer)
                .environmentObject(theme)
                .preferredColorScheme(theme.theme.colorScheme)
        }
    }
}
