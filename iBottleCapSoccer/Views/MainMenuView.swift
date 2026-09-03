import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var localizer: Localizer
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject var viewModel: GameViewModel
    @State private var showRules = false
    @State private var badgeFloat = false

    var onPlay: () -> Void

    private var isResuming: Bool { viewModel.hasStarted && !viewModel.isFullTime }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Button(localizer.language.displayCode) { localizer.toggle() }
                            .buttonStyle(ChipButtonStyle())
                        Button { theme.cycle() } label: {
                            Image(systemName: theme.theme.icon)
                        }
                        .buttonStyle(ChipButtonStyle())
                    }
                }
                .padding()

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 110, height: 110)
                        .shadow(color: Brand.orange.opacity(0.4), radius: 24)
                    Text("⚽").font(.system(size: 52))
                }
                .offset(y: badgeFloat ? -8 : 8)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: badgeFloat)

                titleBlock

                Text(localizer.t(.menuSubtitle))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 40)

                if isResuming {
                    resumeChip
                }

                Spacer(minLength: 12)

                howToPlayRow
                    .padding(.bottom, 22)

                actionButtons
                    .padding(.horizontal, 32)

                creditsBlock
                    .padding(.top, 22)
                    .padding(.bottom, 20)
            }
        }
        .onAppear { badgeFloat = true }
        .sheet(isPresented: $showRules) { RulesView() }
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Brand.black, Color(red: 0.09, green: 0.07, blue: 0.04), Brand.black], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Brand.orange.opacity(0.28), .clear], center: .top, startRadius: 10, endRadius: 520)
        }
        .ignoresSafeArea()
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("FUTEBOL")
                .font(.system(size: 32, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(.white)
            Text("DE CARICAS")
                .font(.system(size: 36, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(.white)
                .overlay(
                    LinearGradient(colors: [Brand.orangeLight, Brand.amber], startPoint: .leading, endPoint: .trailing)
                        .mask(
                            Text("DE CARICAS")
                                .font(.system(size: 36, weight: .heavy))
                                .tracking(1.5)
                        )
                )
        }
        .padding(.top, 22)
    }

    private var resumeChip: some View {
        HStack(spacing: 8) {
            Circle().fill(Brand.orange).frame(width: 7, height: 7)
            Text("\(viewModel.homeScore) — \(viewModel.awayScore)")
                .font(.caption.bold().monospacedDigit())
            Text("·")
                .foregroundColor(.white.opacity(0.4))
            Text(localizer.t(viewModel.half == .first ? .half1 : .half2))
                .font(.caption2.bold())
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(Capsule().stroke(Color.white.opacity(0.15)))
        .padding(.top, 14)
    }

    private var howToPlayRow: some View {
        HStack(spacing: 22) {
            howToPlayStep(icon: "hand.draw.fill", text: localizer.t(.menuStep1))
            howToPlayStep(icon: "bolt.fill", text: localizer.t(.menuStep2))
            howToPlayStep(icon: "trophy.fill", text: localizer.t(.menuStep3))
        }
    }

    private func howToPlayStep(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(Brand.orangeLight)
            }
            Text(text).font(.caption2.bold()).foregroundColor(.white.opacity(0.65))
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: onPlay) {
                Text(localizer.t(isResuming ? .menuContinue : .menuPlay))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Brand.orange.opacity(0.35), radius: 16, y: 6)
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
