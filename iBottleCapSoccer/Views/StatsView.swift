import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var localizer: Localizer
    @ObservedObject private var stats = StatsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                row(localizer.t(.statsGoals), stats.goalsScored)
                row(localizer.t(.statsPlayed), stats.matchesPlayed)
                row(localizer.t(.statsWon), stats.matchesWon)
            }
            .navigationTitle(localizer.t(.statsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t(.close)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func row(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)").bold().foregroundColor(Brand.orange)
        }
    }
}
