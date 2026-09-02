import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @State private var badgeRotation: Double = 0
    @State private var barWidth: CGFloat = 0
    @State private var appeared = false

    private let autoDismissDelay: Double = 2.6

    var body: some View {
        ZStack {
            RadialGradient(colors: [Brand.orange.opacity(0.35), .clear], center: .top, startRadius: 10, endRadius: 500)
                .background(LinearGradient(colors: [Brand.black, Color(red: 0.09, green: 0.07, blue: 0.04), Brand.black], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 96, height: 96)
                        .shadow(color: Brand.orange.opacity(0.4), radius: 20)
                    Text("⚽").font(.system(size: 46))
                }
                .rotationEffect(.degrees(badgeRotation))

                VStack(spacing: 6) {
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

                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 220, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LinearGradient(colors: [Brand.orange, Brand.amber], startPoint: .leading, endPoint: .trailing))
                            .frame(width: barWidth, height: 4)
                    }
                    .padding(.top, 6)

                VStack(spacing: 6) {
                    Text("Developed by ")
                        .foregroundColor(.white.opacity(0.75))
                    + Text("David Arsénio Martins").bold().foregroundColor(.white)

                    HStack(spacing: 10) {
                        Link("ividi.dev", destination: URL(string: "https://ividi.dev/")!)
                        Text("•").opacity(0.5)
                        Link("GitHub", destination: URL(string: "https://github.com/VidiPT89/")!)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Brand.orangeLight)
                }
                .font(.footnote)
                .padding(.top, 4)

                Button(action: onFinish) {
                    Text(Localizer.shared.t(.splashSkip))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(Color.white.opacity(0.2)))
                }
                .padding(.top, 14)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.4)) { barWidth = 220 }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                badgeRotation = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                onFinish()
            }
        }
    }
}
