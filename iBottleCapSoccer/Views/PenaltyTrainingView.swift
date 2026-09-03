import SwiftUI
import SpriteKit

struct PenaltyTrainingView: View {
    @EnvironmentObject private var localizer: Localizer
    @State private var scene: PenaltyScene = {
        let s = PenaltyScene(size: CGSize(width: PenaltyScene.fieldWidth, height: PenaltyScene.fieldHeight))
        s.scaleMode = .aspectFit
        return s
    }()
    @State private var attempts = 0
    @State private var goals = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Text(localizer.t(.trainingScore)).font(.subheadline.bold())
                Text("\(goals)/\(attempts)").font(.subheadline.bold().monospacedDigit()).foregroundColor(Brand.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.secondary.opacity(0.12)))

            GeometryReader { geo in
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: geo.size.width, height: geo.size.width * (PenaltyScene.fieldHeight / PenaltyScene.fieldWidth))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.5), lineWidth: 6))
                    .frame(maxWidth: .infinity)
            }
            .aspectRatio(PenaltyScene.fieldWidth / PenaltyScene.fieldHeight, contentMode: .fit)
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 10)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationTitle(localizer.t(.trainingTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scene.onAttemptResolved = { scored in
                attempts += 1
                if scored { goals += 1 }
            }
        }
    }
}
