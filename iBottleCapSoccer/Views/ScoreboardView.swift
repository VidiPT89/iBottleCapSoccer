import SwiftUI

struct ScoreboardView: View {
    @EnvironmentObject private var localizer: Localizer
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                teamChip(name: localizer.t(.teamHome), color: Brand.orange, alignLeading: true)
                Spacer()
                HStack(spacing: 8) {
                    Text("\(viewModel.homeScore)").font(.system(size: 28, weight: .black))
                    Text("—").foregroundColor(.secondary)
                    Text("\(viewModel.awayScore)").font(.system(size: 28, weight: .black))
                }
                Spacer()
                teamChip(name: localizer.t(.teamAway), color: .primary, alignLeading: false)
            }
            HStack(spacing: 10) {
                if viewModel.mode.isOnline {
                    Text(localizer.t(.onlineFirstTo5))
                        .font(.caption2.bold())
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                } else {
                    Text(localizer.t(viewModel.half == .first ? .half1 : .half2))
                        .font(.caption2.bold())
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    Text(viewModel.clockText)
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .foregroundColor(Brand.orange)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
        .padding(.horizontal)
    }

    private func teamChip(name: String, color: Color, alignLeading: Bool) -> some View {
        HStack(spacing: 6) {
            if alignLeading { Circle().fill(color).frame(width: 10, height: 10) }
            Text(name).font(.caption.bold())
            if !alignLeading { Circle().fill(color).frame(width: 10, height: 10) }
        }
    }
}
