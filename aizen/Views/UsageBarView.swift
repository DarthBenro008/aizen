import SwiftUI

struct UsageBarView: View {
    let usedPercent: Double
    let status: UsageStatus

    private var remainingPercent: Double {
        min(max(100 - usedPercent, 0), 100)
    }

    private var fillColor: Color {
        switch status {
        case .ok:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))

                Capsule()
                    .fill(fillColor)
                    .frame(width: proxy.size.width * (remainingPercent / 100))
            }
        }
        .frame(height: 8)
    }
}
