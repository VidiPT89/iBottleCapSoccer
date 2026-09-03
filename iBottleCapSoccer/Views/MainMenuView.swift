import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var localizer: Localizer
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var soundManager = SoundManager.shared
    @State private var showRules = false
    @State private var showModePicker = false
    @State private var showCustomize = false
    @State private var showStats = false
    @State private var badgeFloat = false

    var onPlay: () -> Void
    var onPlayOnline: () -> Void
    var onTraining: () -> Void
    var onCareer: () -> Void

    private var isResuming: Bool { viewModel.hasStarted && !viewModel.isFullTime }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    settingsMenu
                }
                .padding()

                Spacer()

                badge
                titleBlock

                Text(localizer.t(.menuSubtitle))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 40)

                if isResuming {
                    resumeChip
                }

                Spacer()

                howToPlayLine
                    .padding(.bottom, 20)

                actionButtons

                creditsBlock
                    .padding(.top, 24)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
        }
        .onAppear { badgeFloat = true }
        .sheet(isPresented: $showRules) {
            RulesView()
                .preferredColorScheme(theme.theme.colorScheme)
        }
        .sheet(isPresented: $showModePicker) {
            GameModeSheet(
                onStart: { mode, goalTarget in
                    viewModel.startNewMatch(mode: mode, goalTarget: goalTarget)
                    onPlay()
                },
                onPlayOnline: onPlayOnline
            )
            .preferredColorScheme(theme.theme.colorScheme)
        }
        .sheet(isPresented: $showCustomize) {
            CustomizeKitsView()
                .preferredColorScheme(theme.theme.colorScheme)
        }
        .sheet(isPresented: $showStats) {
            StatsView()
                .preferredColorScheme(theme.theme.colorScheme)
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Brand.black, Color(red: 0.09, green: 0.07, blue: 0.04), Brand.black], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Brand.orange.opacity(0.28), .clear], center: .top, startRadius: 10, endRadius: 520)
        }
        .ignoresSafeArea()
    }

    private var settingsMenu: some View {
        Menu {
            Picker(selection: $localizer.language) {
                Text("Português").tag(AppLanguage.pt)
                Text("English").tag(AppLanguage.en)
            } label: {
                Label(localizer.language == .pt ? "Português" : "English", systemImage: "globe")
            }
            .pickerStyle(.inline)

            Picker(selection: $theme.theme) {
                ForEach([AppTheme.system, .light, .dark], id: \.self) { option in
                    Label(themeLabel(option), systemImage: option.icon).tag(option)
                }
            } label: {
                Label(themeLabel(theme.theme), systemImage: theme.theme.icon)
            }
            .pickerStyle(.inline)

            Divider()

            Toggle(isOn: $soundManager.isAmbientEnabled) {
                Label(localizer.t(.ambientToggle), systemImage: "speaker.wave.2.fill")
            }
            Button { showCustomize = true } label: {
                Label(localizer.t(.customizeTitle), systemImage: "paintpalette.fill")
            }
            Button { showStats = true } label: {
                Label(localizer.t(.statsTitle), systemImage: "chart.bar.fill")
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
    }

    private func themeLabel(_ t: AppTheme) -> String {
        switch t {
        case .system: return localizer.language == .pt ? "Sistema" : "System"
        case .light: return localizer.language == .pt ? "Claro" : "Light"
        case .dark: return localizer.language == .pt ? "Escuro" : "Dark"
        }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 108, height: 108)
                .shadow(color: Brand.orange.opacity(0.4), radius: 24)
            Text("⚽").font(.system(size: 50))
        }
        .offset(y: badgeFloat ? -8 : 8)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: badgeFloat)
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("FUTEBOL")
                .font(.system(size: 30, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(.white)
            Text("DE CARICAS")
                .font(.system(size: 34, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(.white)
                .overlay(
                    LinearGradient(colors: [Brand.orangeLight, Brand.amber], startPoint: .leading, endPoint: .trailing)
                        .mask(
                            Text("DE CARICAS")
                                .font(.system(size: 34, weight: .heavy))
                                .tracking(1.5)
                        )
                )
        }
        .padding(.top, 18)
    }

    private var resumeChip: some View {
        HStack(spacing: 8) {
            Circle().fill(Brand.orange).frame(width: 7, height: 7)
            Text("\(viewModel.homeScore) — \(viewModel.awayScore)")
                .font(.caption.bold().monospacedDigit())
            Text("·").foregroundColor(.white.opacity(0.4))
            Text(resumeChipDetail)
                .font(.caption2.bold())
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(Capsule().stroke(Color.white.opacity(0.15)))
        .padding(.top, 14)
    }

    private var resumeChipDetail: String {
        if viewModel.mode.isOnline { return localizer.t(.onlineFirstTo5) }
        if let target = viewModel.goalTarget { return "\(localizer.t(.goalTargetTitle)): \(target)" }
        return localizer.t(viewModel.half == .first ? .half1 : .half2)
    }

    private var howToPlayLine: some View {
        HStack(spacing: 8) {
            Text(localizer.t(.menuStep1))
            Image(systemName: "arrow.right").font(.caption2)
            Text(localizer.t(.menuStep2))
            Image(systemName: "arrow.right").font(.caption2)
            Text(localizer.t(.menuStep3))
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(0.55))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                if isResuming { onPlay() } else { showModePicker = true }
            } label: {
                Text(localizer.t(isResuming ? .menuContinue : .menuPlay))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Brand.orange.opacity(0.35), radius: 16, y: 6)
            }

            HStack(spacing: 12) {
                secondaryButton(localizer.t(.menuTraining), icon: "target", action: onTraining)
                secondaryButton(localizer.t(.menuCareer), icon: "trophy.fill", action: onCareer)
            }

            Button { showRules = true } label: {
                Text(localizer.t(.menuRules))
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15)))
            }
        }
    }

    private func secondaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(title).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15)))
        }
    }

    private var creditsBlock: some View {
        VStack(spacing: 4) {
            Text("Developed by ")
                .foregroundColor(.white.opacity(0.6))
            + Text("David Arsénio Martins").bold().foregroundColor(.white.opacity(0.85))
            HStack(spacing: 10) {
                Link("ividi.dev", destination: URL(string: "https://ividi.dev/")!)
                Text("•").opacity(0.5)
                Link("GitHub", destination: URL(string: "https://github.com/VidiPT89/")!)
            }
            .font(.caption2.weight(.semibold))
            .foregroundColor(Brand.orangeLight)
        }
        .font(.caption2)
    }
}
