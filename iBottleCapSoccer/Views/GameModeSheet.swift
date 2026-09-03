import SwiftUI

/// Presented from the menu before starting a fresh match. Two steps: pick a mode, then
/// (only for the bot) pick a difficulty. Local and bot start immediately via `onStart`;
/// online hands off to Game Center matchmaking via `onPlayOnline`.
struct GameModeSheet: View {
    @EnvironmentObject private var localizer: Localizer
    @Environment(\.dismiss) private var dismiss

    var onStart: (GameMode, Int?) -> Void
    var onPlayOnline: (() -> Void)?

    @State private var pickingDifficulty = false
    /// Optional early-finish target ("first to N") for Local/Bot — `nil` plays the full clock.
    @State private var goalTarget: Int? = nil
    private static let goalTargetOptions: [Int?] = [nil, 3, 5, 10]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                if !pickingDifficulty {
                    goalTargetPicker
                }
                if pickingDifficulty {
                    ForEach(BotDifficulty.allCases) { difficulty in
                        modeRow(
                            title: difficultyLabel(difficulty),
                            subtitle: nil,
                            icon: difficultyIcon(difficulty)
                        ) {
                            onStart(.bot(difficulty), goalTarget)
                            dismiss()
                        }
                    }
                } else {
                    modeRow(title: localizer.t(.mode1v1), subtitle: localizer.t(.mode1v1Subtitle), icon: "person.2.fill") {
                        onStart(.local, goalTarget)
                        dismiss()
                    }
                    modeRow(title: localizer.t(.modeBot), subtitle: localizer.t(.modeBotSubtitle), icon: "cpu.fill") {
                        withAnimation { pickingDifficulty = true }
                    }
                    if let onPlayOnline {
                        modeRow(title: localizer.t(.modeOnline), subtitle: localizer.t(.modeOnlineSubtitle), icon: "network") {
                            dismiss()
                            onPlayOnline()
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal)
            .navigationTitle(pickingDifficulty ? localizer.t(.botDifficultyTitle) : localizer.t(.modePickerTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if pickingDifficulty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(localizer.t(.back)) { withAnimation { pickingDifficulty = false } }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizer.t(.cancel)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var goalTargetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizer.t(.goalTargetTitle))
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Picker(localizer.t(.goalTargetTitle), selection: $goalTarget) {
                ForEach(Self.goalTargetOptions, id: \.self) { option in
                    Text(option.map { "\($0)" } ?? localizer.t(.goalTargetNone)).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func difficultyLabel(_ d: BotDifficulty) -> String {
        switch d {
        case .easy: return localizer.t(.botEasy)
        case .medium: return localizer.t(.botMedium)
        case .hard: return localizer.t(.botHard)
        }
    }

    private func difficultyIcon(_ d: BotDifficulty) -> String {
        switch d {
        case .easy: return "tortoise.fill"
        case .medium: return "figure.walk"
        case .hard: return "hare.fill"
        }
    }

    private func modeRow(title: String, subtitle: String?, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon).foregroundColor(.black).font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.primary)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}
