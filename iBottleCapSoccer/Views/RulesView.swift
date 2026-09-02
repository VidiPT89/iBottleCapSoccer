import SwiftUI

struct RulesView: View {
    @EnvironmentObject private var localizer: Localizer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section(.rulesObjectiveTitle, .rulesObjectiveBody)
                    section(.rulesDurationTitle, .rulesDurationBody)
                    section(.rulesHowTitle, .rulesHowBody)
                    section(.rulesShootTitle, .rulesShootBody)
                    section(.rulesSpecialTitle, .rulesSpecialBody)
                    section(.rulesPlaysTitle, .rulesPlaysBody)
                }
                .padding()
            }
            .navigationTitle(localizer.t(.rulesTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t(.close)) { dismiss() }
                }
            }
        }
    }

    private func section(_ title: LocKey, _ body: LocKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localizer.t(title)).font(.headline).foregroundColor(Brand.orange)
            Text(localizer.t(body)).font(.subheadline).foregroundColor(.secondary)
        }
    }
}
