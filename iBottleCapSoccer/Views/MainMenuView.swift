import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var localizer: Localizer
    @EnvironmentObject private var theme: ThemeManager
    @State private var showRules = false
    @State private var badgeFloat = false

    var onPlay: () -> Void

    var body: some View {
        ZStack {
            RadialGradient(colors: [Brand.orange.opacity(0.28), .clear], center: .top, startRadius: 10, endRadius: 520)
                .background(LinearGradient(colors: [Brand.black, Color(red: 0.09, green: 0.07, blue: 0.04), Brand.black], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()

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

                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 110, height: 110)
                        .shadow(color: Brand.orange.opacity(0.4), radius: 24)
                    Text("⚽").font(.system(size: 52))
                }
                .offset(y: badgeFloat ? -8 : 8)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: badgeFloat)

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

                Text(localizer.t(.menuSubtitle))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 14) {
                    Button(action: onPlay) {
                        Text(localizer.t(.menuPlay))
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
                .padding(.horizontal, 32)

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
                .padding(.top, 26)
                .padding(.bottom, 20)
            }
        }
        .onAppear { badgeFloat = true }
        .sheet(isPresented: $showRules) { RulesView() }
    }
}
