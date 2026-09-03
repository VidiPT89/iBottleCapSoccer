import SwiftUI

struct CustomizeKitsView: View {
    @EnvironmentObject private var localizer: Localizer
    @ObservedObject private var kits = KitManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(localizer.t(.customizeHome)) {
                    swatchRow(selection: $kits.homeKit)
                }
                Section(localizer.t(.customizeAway)) {
                    swatchRow(selection: $kits.awayKit)
                }
            }
            .navigationTitle(localizer.t(.customizeTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t(.close)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func swatchRow(selection: Binding<CapKit>) -> some View {
        HStack(spacing: 14) {
            ForEach(CapKit.allCases) { kit in
                Button {
                    selection.wrappedValue = kit
                } label: {
                    Circle()
                        .fill(Color(uiColor: kit.base))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(Color.primary, lineWidth: selection.wrappedValue == kit ? 3 : 0)
                        )
                        .overlay(
                            Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
