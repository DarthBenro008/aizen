import SwiftUI

struct ProviderCardView: View {
    let state: ProviderUsageState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                ProviderTitleView(state: state)

                Spacer(minLength: 8)

                if let planType = state.planType, !planType.isEmpty {
                    Text(planType)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                }
            }

            if let configurationMessage = state.configurationMessage {
                Text("Not configured")
                    .font(.subheadline.weight(.semibold))
                Text(configurationMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let errorMessage = state.errorMessage {
                Text(errorMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            } else if state.usageItems.isEmpty {
                Text("No usage data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(state.usageItems) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.label)
                                .font(.subheadline.weight(.medium))

                            Spacer(minLength: 8)

                            Text("\(Int(item.usedPercent.rounded()))% used")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        UsageBarView(usedPercent: item.usedPercent, status: item.status)

                        HStack {
                            if let remaining = item.remaining {
                                Text("Remaining: \(remaining)")
                            } else {
                                Text("Remaining: \(Int(max(0, (100 - item.usedPercent).rounded())))%")
                            }

                            Spacer(minLength: 8)

                            if let resetDate = item.resetsAt {
                                Text("Resets \(resetDate, style: .relative)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
