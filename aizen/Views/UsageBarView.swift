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
            return Color(red: 0.37, green: 0.92, blue: 0.54)
        case .warning:
            return Color(red: 0.95, green: 0.77, blue: 0.29)
        case .critical:
            return Color(red: 0.98, green: 0.44, blue: 0.42)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.09))

                Capsule()
                    .fill(fillColor)
                    .frame(width: proxy.size.width * (remainingPercent / 100))
            }
        }
        .frame(height: 7)
    }
}
